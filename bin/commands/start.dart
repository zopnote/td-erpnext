import 'dart:io';

import 'package:natrix/core.dart';
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/start.dart';

final NatrixCommand startCommand = NatrixCommand(
  id: "start",
  description: "Start the ERPNext-instance.",
  callback: (NatrixCallbackOptions options) async {
    if (options.getFlag("help").value) {
      return;
    }
    final Settings settings = Settings.load();

    final Response lastResponse = await runWorkflow(
      Start(
        appDirectoryPath: settings.appDirectoryPath,
        onCallback: (context, chars, error) => context.send(
          Response(
            String.fromCharCodes(chars),
            error ? Level.error : Level.normal,
          ),
        ),
      ),
      (response) {
        if (response.isError) {
          stderr.writeln(response.message);
          return;
        }
        stdout.writeln(response.message);
      },
    );

    return;
  },
);
