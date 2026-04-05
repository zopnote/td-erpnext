import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:path/path.dart' as path;

import 'package:td_erpnext/src/settings.dart';

final NatrixCommand backupsListCommand = NatrixCommand(
  id: "list",
  description: "Lists all available backups.",
  inheritFlags: true,
  callback: (NatrixCallbackOptions options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }

    final Settings settings = Settings.fromDisk();
    final String bundlesPath = settings.backupStoragePath.value;
    final directory = Directory(bundlesPath);

    if (!directory.existsSync()) {
      io.newLine(
        text: NatrixText(
          "Backup directory does not exist: $bundlesPath",
          foreground: .red,
        ),
        output: .stderr,
      );
      return;
    }

    final List<FileSystemEntity> entities = directory
        .listSync()
        .whereType<Directory>()
        .toList();
    entities.sort(
      (a, b) => b.path.compareTo(a.path),
    ); // Sort by name descending (latest first)

    if (entities.isEmpty) {
      io.newLine(
        text: NatrixText("No backups found in $bundlesPath", foreground: .red),
        output: .stderr,
      );
      return;
    }

    final StringBuffer buffer = StringBuffer();
    buffer.writeln("Available backups in $bundlesPath:");
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
          markers.add(hasSql ? "SQL ✓" : "No SQL");
          markers.add(hasFiles ? ("Files ✓") : ("No Files"));
          markers.add(hasPrivate ? ("Private ✓") : ("No Private"));
          markers.add(hasDocker ? ("Docker ✓") : ("No Docker"));

          buffer.writeln("- ${(name)} (${markers.join(", ")})");
        }
      }
    }

    io.newLine(text: NatrixText(buffer.toString()), output: .stdout);
  },
);
