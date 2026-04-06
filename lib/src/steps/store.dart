import 'dart:io';

import 'package:natrix/io.dart';
import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/vendor/docker.dart' as docker;
import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import 'package:td_erpnext/src/utils.dart';

class CreateBackup extends ConfigureStep {
  final NatrixStdoutSink? output;
  const CreateBackup({this.output});

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }
    final NatrixStdio io = NatrixStdio();
    final Settings settings = Settings.fromDisk();
    final docker.OutputCallback callback = (chars) {
      io.pipe(
        text: NatrixText(String.fromCharCodes(chars), foreground: .grayAccent),
        output: output ?? .stdout,
      );
    };
    final String storesBackupPath = path.join(
      settings.backupStoragePath.value,
      DateTime.now()
          .toLocal()
          .toIso8601String()
          .substring(0, 18)
          .replaceAll(":", "_"),
    );
    return Chain(
      steps: [
        Conditional(
          condition: !Directory(storesBackupPath).existsSync(),
          child: Chain(
            steps: [CreateDirectory(storesBackupPath, recursive: true)],
          ),
        ),
        Conditional(
          condition: dockerCompose.isRunning(composeFile: composeFile),
          child: Chain(
            steps: [
              const PrintNatrixLine(
                text: NatrixText("Stop running containers..."),
              ),
              dockerCompose.Stop(composeFile: composeFile, callback: callback),
            ],
          ),
        ),
        const PrintNatrixLine(text: NatrixText("Backup sites...")),
        docker.Run(
          image: docker.Image.busybox,
          program: "tar",
          args: ["-cvzf", "/backup/sites.tar.gz", "-C", "/volume", "."],
          remove: true,
          volumes: [
            docker.Volume(
              volumeName: settings.sitesVolume.value,
              containerPath: "/volume",
            ),
            docker.Volume(hostPath: storesBackupPath, containerPath: "/backup"),
          ],
          callback: callback,
        ),
        const PrintNatrixLine(text: NatrixText("Backup database...")),
        docker.Run(
          image: docker.Image.busybox,
          program: "tar",
          args: ["-cvzf", "/backup/database.tar.gz", "-C", "/volume", "."],
          remove: true,
          volumes: [
            docker.Volume(
              volumeName: settings.databaseVolume.value,
              containerPath: "/volume",
            ),
            docker.Volume(hostPath: storesBackupPath, containerPath: "/backup"),
          ],
          callback: callback,
        ),
        const PrintNatrixLine(text: NatrixText("Start containers...")),
        dockerCompose.Init(composeFile: composeFile, detach: true, callback: callback),
        PrintNatrixLine(
          text:
          NatrixText("Backup ") +
              NatrixText(
                path.basename(storesBackupPath),
                foreground: NatrixColor.cyanAccent,
              ) +
              NatrixText(" stored under ${path.dirname(storesBackupPath)}."),
        ),
      ],
    );
  }
}
