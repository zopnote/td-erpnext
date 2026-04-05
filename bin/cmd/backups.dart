import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:td_erpnext/src/steps/vendor/systemd.dart' as systemd;

import 'backups/on.dart';
import 'backups/off.dart';
import 'backups/create.dart';
import 'backups/restore.dart';
import 'backups/list.dart';

final NatrixCommand backupsCommand = NatrixCommand(
  id: "backups",
  description: "Manage backups.",
  children: [
    backupsEnableCommand,
    backupsDisableCommand,
    backupsCreateCommand,
    backupsRestoreCommand,
    backupsListCommand,
  ],
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }

    if (!systemd.hasSchedule()) {
      io.newLine(
        text: NatrixText("Backups are currently disabled. See -h for more information.", foreground: .yellow),
        output: .stdout,
      );
    } else {
      io.writeLines(lines: theme.root.format());
    }
  },
);
