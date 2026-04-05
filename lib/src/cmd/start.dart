import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/start.dart';

final NatrixCommand startCommand = NatrixCommand(
  id: "start",
  description: "Start the ERPNext-instance.",
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }
    await runWorkflow(
      Start(
        appDirectoryPath: Settings.appDirectoryPath,
        onCallback: (context, chars, error) => context.send(
          Response(
            String.fromCharCodes(chars),
            error ? Level.error : Level.normal,
          ),
        ),
      ),
      (response) => io.newLine(
        text: NatrixText(response.message),
        output: response.isError ? .stderr : .stdout,
      ),
    );
  },
);
