import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/restore.dart';

import 'restore/last.dart';

final NatrixCommand backupsRestoreCommand = NatrixCommand(
  id: "restore",
  tooltip: "Restores a backup.",
  description:
      "Specify a backup by its id. See available backups with backups list.",
  argumentTip: "backup",
  inheritFlags: false,
  children: [backupsRestoreLastCommand],
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }
    if (options.args.isEmpty) {
      io.newLine(
        text: NatrixText(
          "Please specify a valid backup by id.",
          foreground: .red,
        ),
        output: .stderr,
      );
      return;
    }
    await runWorkflow(
      RestoreBackup(restoreLast: false, bundleName: options.args.first),
      (e) => io.newLine(
        text: NatrixText(e.exception.toString(), foreground: .red),
        output: .stderr,
      ),
    );
  },
);
