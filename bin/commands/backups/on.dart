import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/systemd.dart';


Future<Response> backupsEnableCommand(CommandInformation info) async {
  final bP = info.getFlag("interval") as DurationFlag;

  final Response lastResponse = await runWorkflow(
    Chain(
      steps: [
        Systemd.setupScheduler(
          serviceName: Settings.serviceName,
          arguments: ["backups", "create"],
          interval: bP.value,
        ),
      ],
    ),
        (response) {
      if (response.isError) {
        stderr.writeln(response.message);
        return;
      }
      stdout.writeln(response.message);
    },
  );
  if (lastResponse.isError) {
    return Response("An error occurred.", Level.critical);
  }
  return Response(
    "Installed schedule service with a interval of ${bP.getFormatted()}.",
  );
}

