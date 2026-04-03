import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/flags.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/steps/systemd/get_schedule.dart';
import 'package:td_erpnext/src/steps/systemd/steps/update_schedule.dart';
import 'package:td_erpnext/src/steps/systemd/systemd.dart';

import 'backups/on.dart';
import 'backups/off.dart';
import 'backups/create.dart';
import 'backups/restore.dart';
import 'backups/list.dart';

final Systemd _systemd = Systemd.get();

final NatrixCommand backupsCommand = NatrixCommand(
  id: "backups",
  description: "Manage backups.",
  flags: [
    DurationFlag(
      id: "interval",
      tooltip: "Sets the schedule of backup creation.",
      value: _systemd.hasSchedule()
          ? _systemd.getSchedule()
          : Duration(days: 2),
      examples: [
        Duration(days: 1, hours: 12, minutes: 45),
        Duration(minutes: 20),
      ],
    ),
  ],
  children: [
    backupsEnableCommand,
    backupsDisableCommand,
    backupsCreateCommand,
    backupsRestoreCommand,
    backupsListCommand,
  ],
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }
    final interval = options.getFlag("interval") as DurationFlag;

    bool changedSchedulerDuration =
        _systemd.hasSchedule() && _systemd.getSchedule() != interval.value;

    if (changedSchedulerDuration) {
      await runWorkflow(
        _systemd.updateSchedule(
          UpdateScheduleSettings(interval: interval.value),
        ),
        (response) => io.newLine(
          text: NatrixText(response.message),
          output: response.isError ? .stderr : .stdout,
        ),
      );
      stdout.writeln("Updated backup schedule to ${interval.getFormatted()}.");
    }

    if (!_systemd.hasSchedule()) {
      stdout.writeln(LogColor.yellowed("Backups are currently disabled."));
    }
  },
);
