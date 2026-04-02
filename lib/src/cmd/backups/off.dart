import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/systemd/systemd.dart';

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

    final Response lastResponse = await runWorkflow(
      Systemd.get().removeSchedule(),
      (response) => io.newLine(
        text: NatrixText(response.message),
        output: response.isError ? .stderr : .stdout,
      ),
    );

    if (lastResponse.isError) {
      io.newLine(
        text: NatrixText("An error occurred.", foreground: .red),
        output: .stderr,
      );
      return;
    }
    io.newLine(
      text: NatrixText("Removed the scheduler service."),
      output: .stdout,
    );
  },
);
