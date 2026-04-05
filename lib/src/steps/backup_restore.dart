import 'dart:io';

import 'package:natrix/io.dart';
import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/docker/docker.dart';
import 'package:td_erpnext/src/steps/docker_compose/docker_compose.dart'
    as compose;

class BackupException implements Exception {
  static const BackupException unspecified = BackupException(
    "Please either specify a backup name "
    "or if the last backup should be restored.",
  );
  static const BackupException overspecified = BackupException(
    "You can't restore the last bundle and "
    "provide a specific bundle to restore at"
    " the same time. Decide for one use case.",
  );
  static BackupException noBackups(String bundlesPath) => BackupException(
    "There aren't any backups saved yet inside $bundlesPath.",
  );
  static BackupException notFound(String bundlePath) =>
      BackupException("The backup bundle $bundlePath doesn't exist.");

  final String message;
  const BackupException(this.message);

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    if (other is! BackupException) {
      return false;
    }
    return message == other.message;
  }
}

class RestoreBackup extends ConfigureStep {
  final bool? restoreLast;
  final String? bundleName;

  const RestoreBackup({this.restoreLast, this.bundleName});

  @override
  Step configure() {
    late final String bundle;
    final Settings settings = Settings.fromDisk();

    if (bundleName == null && restoreLast == null) {
      throw BackupException.unspecified;
    }

    if (bundleName != null) {
      if (restoreLast != null) {
        throw BackupException.overspecified;
      }
      bundle = path.join(settings.backupStoragePath.value, bundleName);
    }

    if (restoreLast != null) {
      final bundlesDirectory = Directory(settings.backupStoragePath.value);
      if (!bundlesDirectory.existsSync()) {
        throw BackupException.noBackups(bundlesDirectory.path);
      }
      final List<Directory> bundles = bundlesDirectory
          .listSync()
          .whereType<Directory>()
          .toList();
      bundles.sort(
        // Sort by name descending (ISO date)
        (a, b) => b.path.compareTo(a.path),
      );
      if (bundles.isEmpty) {
        throw BackupException.noBackups(bundlesDirectory.path);
      }
      bundle = bundles.first.path;
    }

    if (!Directory(bundle).existsSync()) {
      throw BackupException.notFound(bundle);
    }

    final NatrixStdio io = NatrixStdio();
    final Docker docker = Docker(
      onCallback: (context, chars, isError) {
        if (isError) {
          throw BackupException(
            "An unexpected error occurred inside "
            "docker while restoring the backup: "
            "${String.fromCharCodes(chars)}",
          );
        }
      },
    );
    final compose.DockerCompose dockerCompose = compose.DockerCompose(
      onCallback: (context, chars, isError) {
        if (isError) {
          throw BackupException(
            "An unexpected error occurred inside "
            "docker while restoring the backup: "
            "${String.fromCharCodes(chars)}",
          );
        }
      },
    );
    final File composeFile = File(
      path.join(Settings.appDirectoryPath, "frappe_docker", "pwd.yml"),
    );
    io.newLine(
      text:
          NatrixText("Selected backup: ", style: .bold) +
          NatrixText(path.basename(bundle), foreground: .cyanAccent),
    );
    final NatrixMount mount = io.newLine(
      text: NatrixText("Starts to restore backup..."),
    );
    return Chain(
      steps: [
        Runnable(
          (_) =>
              io.setLine(mount: mount, text: NatrixText("Stops container...")),
        ),
        // 1. Stop containers before restoring volumes
        dockerCompose.stop(
          compose.StopSettings(
            composeFile: composeFile,
            workingDirectory: Settings.appDirectoryPath,
          ),
        ),
        Runnable(
          (_) => io.setLine(
            mount: mount,
            text: NatrixText("Cleaning up old backend container volume..."),
          ),
        ),
        docker.run(
          RunSettings(
            image: DockerImage.busybox,
            program: "rm",
            args: ["-r", "-f", "/home/frappe/frappe-bench/**/**"],
            config: DockerRunConfig(
              remove: true,
              volumesFrom: [DockerContainer(settings.backendContainer.value)],
            ),
          ),
        ),
        Runnable(
          (_) => io.setLine(
            mount: mount,
            text: NatrixText("Cleaning up old frontend container volume..."),
          ),
        ),
        docker.run(
          RunSettings(
            image: DockerImage.busybox,
            program: "rm",
            args: ["-r", "-f", "/home/frappe/frappe-bench/**/**"],
            config: DockerRunConfig(
              remove: true,
              volumesFrom: [DockerContainer(settings.frontendContainer.value)],
            ),
          ),
        ),
        Runnable(
          (_) =>
              io.setLine(mount: mount, text: NatrixText("Restore volumes...")),
        ),
        docker.run(
          RunSettings(
            image: DockerImage.busybox,
            program: "tar",
            args: ["-xvzf", "backup/erpnext_volumes_backup.tar.gz", "-C", "/"],
            config: DockerRunConfig(
              remove: true,
              volumesFrom: [container],
              volumes: [
                DockerVolume(
                  hostPath: backupBundlePath,
                  containerPath: "/backup",
                ),
              ],
            ),
          ),
        ),
        Runnable(
          (_) => io.setLine(
            mount: mount,
            text: NatrixText("Restart container..."),
          ),
        ),
        // 3. Start containers again
        dockerCompose.init(
          compose.InitSettings(
            composeFile: File(composeFilePath),
            workingDirectory: workingDirectory,
            detach: true,
          ),
        ),
        Runnable((_) => io.setLine(mount: mount, text: NatrixText("Done."))),
      ],
    );
  }
}
