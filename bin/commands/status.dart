import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/io.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/docker.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/systemd.dart';

Future<Response> statusCommand(CommandInformation info) async {
  if (info.getFlag("help").value) {
    return Response(info.command.formatSyntax(spacer: 13), Level.normal);
  }
  final Settings settings = Settings.load();

  final String composeFilePath = path.join(
    settings.appDirectoryPath,
    "frappe_docker",
    "pwd.yml",
  );

  final bool confFileExists = File(
    Settings.configurationFilePath,
  ).existsSync();
  final bool schedulerInstalled = Systemd.isSchedulerInstalled(
    Settings.serviceName,
  );
  final bool bootInstalled = Systemd.isBootInstalled(Settings.serviceName);
  final bool installed = File(composeFilePath).existsSync();
  final bool? running = installed
      ? DockerCompose.isRunning(
    composeFile: File(composeFilePath),
    workingDirectory: settings.appDirectoryPath,
  )
      : null;
  final String? backupPeriod = schedulerInstalled ? DurationFlag(
    name: "",
    value: Systemd.getSchedulerDuration(Settings.serviceName),
  ).getFormatted() : null;

  return Response("""
${info.command.description}
ERPNext-Installation: ${installed ? running! ? LogColor.greened("✓ Running") : LogColor.cyanid("✓ Installed, not running") : LogColor.redid("✕ Not found")}
Configuration: ${confFileExists ? LogColor.greened("✓ Valid") : LogColor.redid("✕ Not found")}
Services: (backup-scheduler) ${schedulerInstalled ? LogColor.greened("✓ Installed") + " (Period: ${LogColor.cyanid("$backupPeriod")})" : LogColor.redid("✕ Not installed")}, (start-on-boot) ${bootInstalled ? LogColor.greened("✓ Installed") : LogColor.redid("✕ Not installed")}
Tries to connect to: (container) ${LogColor.cyanid(settings.dockerContainerName)}, (port) ${LogColor.cyanid(settings.connectionPort.toString())}, (site) ${LogColor.cyanid(settings.currentSite)}
  """);
}


