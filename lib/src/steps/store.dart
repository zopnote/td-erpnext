import 'dart:io';

import 'package:natrix/io.dart';
import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/vendor/docker.dart' as docker;
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
    final docker.OutputCallback callback = (chars, isError) {
      io.newLine(
        text: NatrixText(
          String.fromCharCodes(chars),
          foreground: isError ? .red : .grayAccent,
        ),
        output: output ?? (isError ? .stderr : .stdout),
      );
    };

    final docker.Container frontendContainer = docker.Container(
      settings.frontendContainer.value,
    );
    final docker.Container backendContainer = docker.Container(
      settings.backendContainer.value,
    );
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
        Runnable(
          () => io.newLine(text: NatrixText("Stop running containers...")),
        ),
        docker.Stop(
          containers: [frontendContainer, backendContainer],
          timeout: 0,
          callback: callback,
        ),
        Runnable(() => io.newLine(text: NatrixText("Backup docker volume..."))),
        docker.Run(
          image: docker.Image.busybox,
          program: "tar",
          args: [
            "-cvzf",
            "backup/frontend.tar.gz",
            // We want to backup the data volumes.
            // Usually these are mounted under /home/frappe/frappe-bench
            "home/frappe/frappe-bench",
          ],
          remove: true,
          volumesFrom: [frontendContainer],
          volumes: [
            docker.Volume(hostPath: storesBackupPath, containerPath: "/backup"),
          ],
          callback: callback,
        ),
        docker.Run(
          image: docker.Image.busybox,
          program: "tar",
          args: [
            "-cvzf",
            "backup/backend.tar.gz",
            // We want to backup the data volumes.
            // Usually these are mounted under /home/frappe/frappe-bench
            "home/frappe/frappe-bench",
          ],
          remove: true,
          volumesFrom: [backendContainer],
          volumes: [
            docker.Volume(hostPath: storesBackupPath, containerPath: "/backup"),
          ],
          callback: callback,
        ),
        Runnable(
          () => io.newLine(
            text:
                NatrixText("Backup ") +
                NatrixText(
                  path.basename(storesBackupPath),
                  foreground: NatrixColor.cyanAccent,
                ) +
                NatrixText("stored under ${path.dirname(storesBackupPath)}."),
          ),
        ),
        docker.Start(
          containers: [frontendContainer, backendContainer],
          callback: callback,
        ),
      ],
    );
  }
}
