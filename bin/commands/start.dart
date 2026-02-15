import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/start.dart';

Future<Response> startCommand(CommandInformation info) async {
  if (info.getFlag("help").value) {
    return Response(info.command.formatSyntax(spacer: 13), Level.normal);
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

  return Response("", lastResponse.level);
}
