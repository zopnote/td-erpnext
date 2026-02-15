import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/systemd.dart';


Future<Response> backupsDisableCommand(CommandInformation info) async {
  final Response lastResponse = await runWorkflow(
    Chain(steps: [Systemd.removeScheduler(Settings.serviceName)]),
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
  return Response("Removed the scheduler service.");
}

