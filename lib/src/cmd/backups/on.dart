import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/steps/systemd/systemd.dart';


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

    final Response lastResponse = await runWorkflow(
      Systemd.get().setupSchedule(
        args: ["backups", "create"],
        interval: bP.value,
      ),
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
      text: NatrixText(
        "Installed schedule service with a interval of ${bP.getFormatted()}.",
      ),
      output: .stdout,
    );
  },
);
