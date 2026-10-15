import 'dart:io';

import 'package:natrix/io.dart';
import 'package:stepflow/io.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:stepflow_docker/docker.dart' as docker;
import 'package:stepflow_docker/docker_compose.dart' as dockerCompose;
import 'package:stepflow_systemd/systemd.dart' as systemd;

import '../exception.dart';
import 'recreate_directory.dart';
import 'natrix.dart';

final class Setup extends ConfigureStep {
  final String? tag;
  const Setup({this.tag});

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (composeFile.existsSync()) {
      throw AlreadyInstalledException();
    }
    final Directory repository = Directory(Settings.repositoryPath);
    final NatrixStdio io = NatrixStdio();
    final Settings settings = Settings.fromDisk();
    return Chain(
      steps: [
        Check(
          programs: ["docker", "git", "systemctl", "systemd"],
          onFailure: (programs) =>
              throw UnavailableDependenciesException(programs),
        ),
        Conditional(
          condition: !repository.existsSync(),
          child: Chain(
            steps: [
              RecreateDirectory(Settings.appDirectoryPath, recursive: true),
              Shell(
                program: "git",
                arguments: <String>[]
                  ..add("clone")
                  ..mapAllNotNull(
                    tag,
                    (v) => ["--branch", v, "--single-branch"],
                  )
                  ..add("https://github.com/frappe/frappe_docker"),
                options: ProcessInterfaceOptions(
                  workingDirectory: Settings.appDirectoryPath,
                ),
              ),
            ],
          ),
        ),
        dockerCompose.Init(
          composeFile: composeFile,
          detach: true,
          workingDirectory: Settings.appDirectoryPath,
          callback: (chars) => io.pipe(
            text: NatrixText(
              String.fromCharCodes(chars),
              foreground: .grayAccent,
            ),
          ),
        ),
        docker.Update(
          containers: [
            docker.Container(settings.backendContainer.value),
            docker.Container(settings.frontendContainer.value),
            docker.Container(settings.websocketContainer.value),
            docker.Container(settings.schedulerContainer.value),
          ],
          restart: docker.RestartPolicy.no,
          callback: (chars) => io.pipe(
            text: NatrixText(
              String.fromCharCodes(chars),
              foreground: .grayAccent,
            ),
          ),
        ),
        const PrintNatrixLine(text: NatrixText("Add systemd boot service...")),
        systemd.SetupAutostart(args: ["start"]),
        Runnable(() => settings.dump()),
      ],
    );
  }
}
