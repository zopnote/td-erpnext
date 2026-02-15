
import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/systemd.dart';

Future<Response> backupsCommand(CommandInformation info) async {
  final bP = info.getFlag("interval") as DurationFlag;

  bool changedSchedulerDuration =
      Systemd.isSchedulerInstalled(Settings.serviceName) &&
      Systemd.getSchedulerDuration(Settings.serviceName) != bP.value;

  if (changedSchedulerDuration) {
    final Response lastResponse = await runWorkflow(
      Systemd.updateSchedulerDuration(
        serviceName: Settings.serviceName,
        interval: bP.value,
      ),
      (response) {
        if (response.isError) {
          stderr.writeln(response.message);
          return;
        }
        stdout.writeln(response.message);
      },
    );
    stdout.writeln("Updated backup schedule to ${bP.getFormatted()}.");

    if (lastResponse.isError) {
      return Response("An error occurred.", Level.critical);
    }
  }

  if (!Systemd.isSchedulerInstalled(Settings.serviceName)) {
    stdout.writeln(LogColor.yellowed("Backups are currently disabled."));
  }

  if (changedSchedulerDuration) return Response();
  return Response(info.command.formatSyntax(spacer: 15), Level.normal);
}
