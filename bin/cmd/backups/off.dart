import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/vendor/systemd.dart' as systemd;

final NatrixCommand backupsDisableCommand = NatrixCommand(
  id: "off",
  description: "Enables backups of the erpnext volumes.",
  inheritFlags: false,
  callback: (NatrixCallbackOptions options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }
    await runWorkflow(
      systemd.RemoveSchedule(),
      (e) => io.newLine(
        text: NatrixText(e.exception.toString(), foreground: .red),
        output: .stderr,
      ),
    );

    io.newLine(
      text: NatrixText("Removed the scheduler service."),
      output: .stdout,
    );
  },
);
