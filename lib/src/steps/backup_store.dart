import 'dart:io';

import 'package:natrix/io.dart';
import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/create_directory.dart';

import 'docker/docker.dart';

class CreateBackup extends ConfigureStep {
  final NatrixStdoutSink? output;
  const CreateBackup({this.output});

  @override
  Step configure() {
    final NatrixStdio io = NatrixStdio();
    final Settings settings = Settings.fromDisk();
    final Docker docker = Docker(
      onCallback: (context, chars, isError) {
        io.newLine(
          text: NatrixText(
            String.fromCharCodes(chars),
            foreground: isError ? .red : .grayAccent,
          ),
          output: output ?? (isError ? .stderr : .stdout),
        );
      },
    );

    final DockerContainer frontendContainer = DockerContainer(
      settings.frontendContainer.value,
    );
    final DockerContainer backendContainer = DockerContainer(
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
          (_) => io.newLine(text: NatrixText("Stop running containers...")),
        ),
        docker.stop(
          StopSettings(
            containers: [frontendContainer, backendContainer],
            timeout: 0,
          ),
        ),
        Runnable(
          (_) => io.newLine(text: NatrixText("Backup docker volume...")),
        ),
        docker.run(
          RunSettings(
            image: DockerImage.busybox,
            program: "tar",
            args: [
              "-cvzf",
              "backup/frontend.tar.gz",
              // We want to backup the data volumes.
              // Usually these are mounted under /home/frappe/frappe-bench
              "home/frappe/frappe-bench",
            ],
            config: DockerRunConfig(
              remove: true,
              volumesFrom: [frontendContainer],
              volumes: [
                DockerVolume(
                  hostPath: storesBackupPath,
                  containerPath: "/backup",
                ),
              ],
            ),
          ),
        ),
        docker.run(
          RunSettings(
            image: DockerImage.busybox,
            program: "tar",
            args: [
              "-cvzf",
              "backup/backend.tar.gz",
              // We want to backup the data volumes.
              // Usually these are mounted under /home/frappe/frappe-bench
              "home/frappe/frappe-bench",
            ],
            config: DockerRunConfig(
              remove: true,
              volumesFrom: [backendContainer],
              volumes: [
                DockerVolume(
                  hostPath: storesBackupPath,
                  containerPath: "/backup",
                ),
              ],
            ),
          ),
        ),
        Runnable(
          (_) => io.newLine(
            text:
                NatrixText("Backup ") +
                NatrixText(
                  path.basename(storesBackupPath),
                  foreground: NatrixColor.cyanAccent,
                ) +
                NatrixText("stored under ${path.dirname(storesBackupPath)}."),
          ),
        ),
        docker.start(
          StartSettings(containers: [frontendContainer, backendContainer]),
        ),
      ],
    );
  }
}
