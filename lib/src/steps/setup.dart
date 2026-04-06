import 'dart:io';

import 'package:natrix/io.dart';
import 'package:stepflow/io.dart';
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/vendor/docker.dart' as docker;
import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import 'package:td_erpnext/src/steps/vendor/systemd.dart' as systemd;
import 'package:td_erpnext/src/utils.dart';

class Setup extends ConfigureStep {
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
              CreateDirectory(
                Settings.appDirectoryPath,
                recursive: true,
                deleteIfExists: true,
              ),
              Shell(
                program: "git",
                arguments: ["clone",
                  if (tag != null) ...["--branch", tag!, "--single-branch"],
                  "https://github.com/frappe/frappe_docker"],
                options: ProcessInterfaceOptions(
                  workingDirectory: Settings.appDirectoryPath,
                ),
              ),
            ],
          ),
        ),
        const PrintNatrixLine(text: NatrixText("Setup docker container...")),
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
        const PrintNatrixLine(
          text: NatrixText("Set restart policy of container..."),
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
        const PrintNatrixLine(
          text: NatrixText("Writes default configuration to disk..."),
        ),
        Runnable(() => settings.dump()),
      ],
    );
  }
}
