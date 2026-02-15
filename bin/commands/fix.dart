import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/create_directory.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/systemd.dart';
import 'package:stepflow/src/io/steps/log_print.dart';

Future<Response> fixCommand(CommandInformation info) async {
  final bool resetSettings = info.getFlag("reset_settings").value;
  final bool schedulerInstalled = Systemd.isSchedulerInstalled(
    Settings.serviceName,
  );
  late final Duration? schedulerDuration;
  if (schedulerInstalled) {
    schedulerDuration = Systemd.getSchedulerDuration(Settings.serviceName);
  } else {
    schedulerDuration = null;
  }
  final Response lastResponse = await runWorkflow(
    Chain(
      steps: [
        Conditional(
          condition: schedulerInstalled,
          child: Chain(
            steps: [
              LogASCIIContext("Reinstall systemd scheduler..."),
              Systemd.removeScheduler(Settings.serviceName),
              Systemd.setupScheduler(
                serviceName: Settings.serviceName,
                arguments: ["backups", "create"],
                interval: schedulerDuration!,
              ),
            ],
          ),
        ),
        Conditional(
          condition: Systemd.isBootInstalled(Settings.serviceName),
          child: Chain(
            steps: [
              LogASCIIContext("Reinstall systemd boot service..."),
              Systemd.removeBoot(Settings.serviceName),
              Systemd.setupBoot(
                serviceName: Settings.serviceName,
                arguments: ["start"],
              ),
            ],
          ),
        ),
        Conditional(
          condition:
              !File(Settings.configurationFilePath).existsSync() ||
              resetSettings,
          child: Chain(
            steps: [
              LogASCIIContext("Create new configuration file..."),
              Runnable((context) => Settings().dump()),
            ],
          ),
        ),
        Conditional(
          condition: !Directory(
            settingsAtProgramStart.appDirectoryPath,
          ).existsSync(),
          child: Chain(
            steps: [
              LogASCIIContext("Create app directory..."),
              CreateDirectory(
                settingsAtProgramStart.appDirectoryPath,
                recursive: true,
                deleteIfExists: true,
              ),
            ],
          ),
        ),
        LogASCIIContext(
"""
${LogColor.cyanid("Applied some fixes.")}

If nothing changed consider to backup your instance and reinstall the setup.
After the reinstallation you can restore your backup.

\$ ${LogColor.grayed("sudo td-erpnext") + " " + LogColor.brightCyanid("fix --reset_settings")}
\$ ${LogColor.grayed("sudo td-erpnext") + " " + LogColor.brightCyanid("backups create")}
\$ ${LogColor.grayed("sudo td-erpnext") + " " + LogColor.brightCyanid("uninstall")}
\$ ${LogColor.grayed("sudo td-erpnext") + " " + LogColor.brightCyanid("setup")}
\$ ${LogColor.grayed("sudo td-erpnext") + " " + LogColor.brightCyanid("backups restore")}
${LogColor.grayed("(Don't forget to adjust the settings after this reinstallation, including the backup dist, from where backups are loaded.)")}

${LogColor.cyanid("If your problem is now fixed, ignore these advises.")}

""",
          color: LogColor.white,
          level: Level.normal,
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
  return Response("", lastResponse.level);
}
