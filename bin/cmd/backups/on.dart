import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/steps/vendor/systemd.dart' as systemd;

final NatrixCommand backupsEnableCommand = NatrixCommand(
  id: "on",
  description: "Enables backups of the erpnext volumes.",
  callback: (NatrixCallbackOptions options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }
    final bP = options.getFlag("interval") as DurationFlag;

    await runWorkflow(
      systemd.SetupSchedule(args: ["backups", "create"], interval: bP.value),
      (e) => io.newLine(
        text: NatrixText(e.exception.toString(), foreground: .red),
        output: .stderr,
      ),
    );
    io.newLine(
      text: NatrixText(
        "Installed schedule service with a interval of ${bP.getFormatted()}.",
      ),
      output: .stdout,
    );
  },
);
