import 'dart:io';

import 'package:natrix/io.dart';
import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/vendor/docker.dart' as docker;
import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import 'package:td_erpnext/src/utils.dart';

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
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }
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
    final docker.OutputCallback dockerCallback = (chars, isError) {
      if (isError) {
        throw BackupException(
          "An unexpected error occurred inside "
          "docker while restoring the backup: "
          "${String.fromCharCodes(chars)}",
        );
      }
    };
    dockerCompose.OutputCallback composeCallback = (chars, isError) {
      if (isError) {
        throw BackupException(
          "An unexpected error occurred inside "
          "docker while restoring the backup: "
          "${String.fromCharCodes(chars)}",
        );
      }
    };
    io.newLine(
      text:
          NatrixText("Selected backup: ", style: .bold) +
          NatrixText(path.basename(bundle), foreground: .cyanAccent),
    );
    final NatrixMount mount = io.newLine();
    return Chain(
      steps: [
        RenewNatrixLine(
          mount: mount,
          text: const NatrixText("Stops container..."),
        ),
        // 1. Stop containers before restoring volumes
        dockerCompose.Stop(
          composeFile: composeFile,
          workingDirectory: Settings.appDirectoryPath,
          callback: composeCallback,
        ),
        RenewNatrixLine(
          mount: mount,
          text: const NatrixText("Cleaning up old backend container volume..."),
        ),
        docker.Run(
          image: docker.Image.busybox,
          program: "rm",
          args: ["-r", "-f", "/home/frappe/frappe-bench/**/**"],
          callback: dockerCallback,
          remove: true,
          volumesFrom: [docker.Container(settings.backendContainer.value)],
        ),
        RenewNatrixLine(
          mount: mount,
          text: const NatrixText(
            "Cleaning up old frontend container volume...",
          ),
        ),
        docker.Run(
          image: docker.Image.busybox,
          program: "rm",
          callback: dockerCallback,
          args: ["-r", "-f", "/home/frappe/frappe-bench/**/**"],
          remove: true,
          volumesFrom: [docker.Container(settings.frontendContainer.value)],
        ),
        RenewNatrixLine(
          mount: mount,
          text: const NatrixText("Restore volumes..."),
        ),

        docker.Run(
          image: docker.Image.busybox,
          program: "tar",
          callback: dockerCallback,
          args: ["-xvzf", "backup/erpnext_volumes_backup.tar.gz", "-C", "/"],
          remove: true,
          volumesFrom: [docker.Container(settings.backendContainer.value)],
          volumes: [
            docker.Volume(
              hostPath: settings.backupStoragePath.value,
              containerPath: "/backup",
            ),
          ],
        ),
        RenewNatrixLine(
          mount: mount,
          text: const NatrixText("Restart container..."),
        ),
        // 3. Start containers again
        dockerCompose.Init(
          composeFile: composeFile,
          detach: true,
          workingDirectory: Settings.appDirectoryPath,
          callback: composeCallback,
        ),
        RenewNatrixLine(mount: mount, text: const NatrixText("Done.")),
      ],
    );
  }
}
