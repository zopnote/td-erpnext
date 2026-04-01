import 'dart:io';

import 'package:natrix/core.dart';
import 'package:path/path.dart' as path;

import 'package:stepflow/io.dart';
import 'package:stepflow/src/io/steps/log_print.dart';

import 'package:td_erpnext/src/settings.dart';

final NatrixCommand backupsListCommand = NatrixCommand(
  id: "list",
  description: "Lists all available backups.",
  inheritFlags: true,
  callback: (NatrixCallbackOptions options) async {
    final String backupPath = settingsAtProgramStart.backupDestinationPath;
    final directory = Directory(backupPath);

    if (!directory.existsSync()) {
      return Response(
        "Backup directory does not exist: $backupPath",
        Level.warning,
      );
    }

    final List<FileSystemEntity> entities = directory
        .listSync()
        .whereType<Directory>()
        .toList();
    entities.sort(
      (a, b) => b.path.compareTo(a.path),
    ); // Sort by name descending (latest first)

    if (entities.isEmpty) {
      return Response("No backups found in $backupPath");
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln("Available backups in $backupPath:");
    buffer.writeln("");

    for (final entity in entities) {
      if (entity is Directory) {
        final String name = path.basename(entity.path);
        final String frappeBackupsPath = path.join(entity.path, "backups");
        final String dockerVolumePath = path.join(
          entity.path,
          "erpnext_volumes_backup.tar.gz",
        );

        bool hasSql = false;
        bool hasFiles = false;
        bool hasPrivate = false;
        bool hasDocker = File(dockerVolumePath).existsSync();

        if (Directory(frappeBackupsPath).existsSync()) {
          final List<File> files = Directory(
            frappeBackupsPath,
          ).listSync().whereType<File>().toList();
          for (final file in files) {
            final fileName = path.basename(file.path);
            if (fileName.contains("-database.sql.gz")) hasSql = true;
            if (fileName.contains("-files.tgz")) hasFiles = true;
            if (fileName.contains("-private-files.tgz")) hasPrivate = true;
          }
        }

        // Only list if at least one component exists
        if (hasSql || hasFiles || hasPrivate || hasDocker) {
          final List<String> markers = [];
          markers.add(
            hasSql ? LogColor.greened("SQL ✓") : LogColor.yellowed("No SQL"),
          );
          markers.add(
            hasFiles
                ? LogColor.greened("Files ✓")
                : LogColor.yellowed("No Files"),
          );
          markers.add(
            hasPrivate
                ? LogColor.greened("Private ✓")
                : LogColor.yellowed("No Private"),
          );
          markers.add(
            hasDocker
                ? LogColor.greened("Docker ✓")
                : LogColor.yellowed("No Docker"),
          );

          buffer.writeln("- ${LogColor.cyanid(name)} (${markers.join(", ")})");
        }
      }
    }

    return Response(buffer.toString());
  },
);
