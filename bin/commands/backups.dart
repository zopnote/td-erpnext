import 'dart:io';

import 'package:natrix/core.dart';
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/systemd/systemd.dart';

import 'backups/on.dart';
import 'backups/off.dart';
import 'backups/create.dart';
import 'backups/restore.dart';
import 'backups/list.dart';

final NatrixCommand backupsCommand = NatrixCommand(
  id: "backups",
  description: "Manage backups.",
  flags: [
    DurationFlag(
      id: "interval",
      value: Systemd.hasSchedule(Settings.serviceName)
          ? Systemd.getSchedule(Settings.serviceName)
          : Duration(days: 2),
      examples: [
        Duration(days: 1, hours: 12, minutes: 45),
        Duration(minutes: 20),
      ],
      tooltip: "Sets the schedule of backup creation.",
    ),
  ],
  children: [
    backupsEnableCommand,
    backupsDisableCommand,
    backupsCreateCommand,
    backupsRestoreCommand,
    backupsListCommand,
  ],
  callback: (NatrixCallbackOptions options) async {
    final bP = options.getFlag("interval") as DurationFlag;

    bool changedSchedulerDuration =
        Systemd.hasSchedule(Settings.serviceName) &&
        Systemd.getSchedule(Settings.serviceName) != bP.value;

    if (changedSchedulerDuration) {
      final Response lastResponse = await runWorkflow(
        Systemd.updateSchedule(
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

    if (!Systemd.hasSchedule(Settings.serviceName)) {
      stdout.writeln(LogColor.yellowed("Backups are currently disabled."));
    }

    if (changedSchedulerDuration) return Response();
    return Response(info.command.formatSyntax(spacer: 15), Level.normal);
  },
);
