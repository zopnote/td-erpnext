import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/backup.dart';
import 'package:td_erpnext/restore.dart';
import 'package:td_erpnext/src/docker.dart';
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

  /**
   * Note that the Flags default values are the current settings, loaded from disk,
   * before initializing the programs command line interface.
   *
   * So, when we dump, and no actual changes to the settings were made, we just dump
   * what we loaded before.
   */
  final bSP = info.getFlag(Settings.json(#backupSourcePath)) as TextFlag;
  final bDP = info.getFlag(Settings.json(#backupDestinationPath)) as TextFlag;

  if (bSP.value != settingsAtProgramStart.backupSourcePath ||
      bDP.value != settingsAtProgramStart.backupDestinationPath) {
    final Settings settings = Settings(
      connectionPort: settingsAtProgramStart.connectionPort,
      currentSite: settingsAtProgramStart.currentSite,
      dockerContainerName: settingsAtProgramStart.dockerContainerName,
      appDirectoryName: settingsAtProgramStart.appDirectoryName,
      logDirectoryName: settingsAtProgramStart.logDirectoryName,
      dbRootPassword: settingsAtProgramStart.dbRootPassword,
      backupSourcePath: bSP.value,
      backupDestinationPath: bDP.value,
    );

    settings.dump();
    return Response(
      "Adjusted the settings to the following: "
      "\n${JsonEncoder.withIndent('  ').convert(settings.document).replaceAll("{", "").replaceAll("}", "").replaceAll("\"", "").replaceAll(",", "")}",
    );
  }

  if (!Systemd.isSchedulerInstalled(Settings.serviceName)) {
    stdout.writeln(LogColor.yellowed("Backups are currently disabled."));
  }

  if (changedSchedulerDuration) return Response();
  return Response(info.command.formatSyntax(spacer: 15), Level.normal);
}
