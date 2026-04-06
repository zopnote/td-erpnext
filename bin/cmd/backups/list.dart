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
      io.newLine(text: NatrixText("No backups found (errno 2)."));
      return;
    }

    final List<Directory> entities = directory
        .listSync()
        .whereType<Directory>()
        .toList();
    entities.sort(
      (a, b) => b.path.compareTo(a.path),
    ); // Sort by name descending (latest first)

    if (entities.isEmpty) {
      io.newLine(text: NatrixText("No backups found in $bundlesPath."));
      return;
    }
    io.writeLines(
      lines: NatrixDocument(
        header: NatrixLine(
          text: NatrixText("Available backups:", style: .bold),
        ),
        content: NatrixStructure(
          sections: [
            NatrixColumn(
              lines: entities
                  .map((e) => NatrixText("• ${path.basename(e.path)}"))
                  .toList(),
            ),
          ],
        ),
        footer: NatrixBlock.empty(),
      ).format(),
    );
  },
);
