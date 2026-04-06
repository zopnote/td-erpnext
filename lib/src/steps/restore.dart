import 'dart:io';

import 'package:natrix/io.dart';
import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/vendor/docker.dart' as docker;
import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import 'package:td_erpnext/src/utils.dart';

class BackupUnspecifiedException implements Exception {
  const BackupUnspecifiedException();
  @override
  String toString() =>
      "Please either specify a backup name "
      "or if the last backup should be restored.";
}

class BackupOverspecifiedException implements Exception {
  const BackupOverspecifiedException();
  @override
  String toString() =>
      "You can't restore the last bundle and "
      "provide a specific bundle to restore at"
      " the same time. Decide for one use case.";
}

class BackupNotFoundException implements Exception {
  final String bundlePath;
  const BackupNotFoundException(this.bundlePath);
  @override
  String toString() => "The backup bundle $bundlePath doesn't exist.";
}

class NoneBackupException implements Exception {
  final String bundlesPath;
  const NoneBackupException(this.bundlesPath);
  @override
  String toString() =>
      "There aren't any backups saved yet inside $bundlesPath.";
}

class RestoreBackup extends ConfigureStep {
  final bool? restoreLast;
  final bool hard;
  final String? bundleName;

  const RestoreBackup({this.restoreLast, this.bundleName, this.hard = false});

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }
    late final String bundle;
    final Settings settings = Settings.fromDisk();

    if (bundleName == null && restoreLast == null) {
      throw BackupUnspecifiedException();
    }

    if (bundleName != null) {
      if (restoreLast != null && restoreLast!) {
        throw BackupOverspecifiedException();
      }
      bundle = path.join(settings.backupStoragePath.value, bundleName);
    }

    if (restoreLast != null && restoreLast!) {
      final bundlesDirectory = Directory(settings.backupStoragePath.value);
      if (!bundlesDirectory.existsSync()) {
        throw NoneBackupException(bundlesDirectory.path);
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
        throw NoneBackupException(bundlesDirectory.path);
      }
      bundle = bundles.first.path;
    }

    if (!Directory(bundle).existsSync()) {
      throw BackupNotFoundException(bundle);
    }

    final NatrixStdio io = NatrixStdio();
    final docker.OutputCallback dockerCallback = (chars) {
      io.pipe(
        text: NatrixText(String.fromCharCodes(chars), foreground: .grayAccent),
      );
    };
    dockerCompose.OutputCallback composeCallback = (chars) {
      io.pipe(
        text: NatrixText(String.fromCharCodes(chars), foreground: .grayAccent),
      );
    };
    io.newLine(
      text:
          NatrixText("Selected backup: ", style: .bold) +
          NatrixText(path.basename(bundle), foreground: .cyanAccent),
    );
    return Chain(
      steps: [
        const PrintNatrixLine(text: NatrixText("Stops container...")),
        dockerCompose.Stop(
          composeFile: composeFile,
          workingDirectory: Settings.appDirectoryPath,
          callback: composeCallback,
        ),
        const PrintNatrixLine(text: NatrixText("Cleaning up old volumes...")),
        docker.Run(
          image: docker.Image.busybox,
          program: "rm",
          args: ["-rf", "/volume/*"],
          remove: true,
          volumes: [
            docker.Volume(
              containerPath: "/volume",
              volumeName: settings.sitesVolume.value,
            ),
          ],
          callback: dockerCallback,
        ),
        docker.Run(
          image: docker.Image.busybox,
          program: "rm",
          args: ["-rf", "/volume/*"],
          remove: true,
          volumes: [
            docker.Volume(
              containerPath: "/volume",
              volumeName: settings.databaseVolume.value,
            ),
          ],
          callback: dockerCallback,
        ),
        docker.Run(
          image: docker.Image.busybox,
          program: "rm",
          args: ["-rf", "/volume/*"],
          remove: true,
          volumes: [
            docker.Volume(
              containerPath: "/volume",
              volumeName: settings.redisCacheVolume.value,
            ),
          ],
          callback: dockerCallback,
        ),
        docker.Run(
          image: docker.Image.busybox,
          program: "rm",
          args: ["-rf", "/volume/*"],
          remove: true,
          volumes: [
            docker.Volume(
              containerPath: "/volume",
              volumeName: settings.redisQueueVolume.value,
            ),
          ],
          callback: dockerCallback,
        ),
        const PrintNatrixLine(text: NatrixText("Restore backup...")),
        docker.Run(
          image: docker.Image.busybox,
          program: "tar",
          args: [
            "-xvzf",
            "backup/sites.tar.gz",
            "-C",
            "/sites"
          ],
          remove: true,
          volumes: [
            docker.Volume(
              containerPath: "/sites",
              volumeName: settings.sitesVolume.value,
            ),
            docker.Volume(
              hostPath: bundle,
              containerPath: "/backup",
            ),
          ],
          callback: dockerCallback,
        ),
        docker.Run(
          image: docker.Image.busybox,
          program: "tar",
          args: [
            "-xvzf",
            "backup/database.tar.gz",
            "-C",
            "/database",
          ],
          remove: true,
          volumes: [
            docker.Volume(
              containerPath: "/database",
              volumeName: settings.databaseVolume.value,
            ),
            docker.Volume(
              hostPath: bundle,
              containerPath: "/backup",
            ),
          ],
          callback: dockerCallback,
        ),
        const PrintNatrixLine(text: NatrixText("Restart container...")),
        dockerCompose.Init(
          composeFile: composeFile,
          detach: true,
          workingDirectory: Settings.appDirectoryPath,
          callback: composeCallback,
        ),
        const PrintNatrixLine(text: NatrixText("Restored the backup.")),
      ],
    );
  }
}
