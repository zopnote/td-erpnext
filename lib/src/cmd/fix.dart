import 'dart:io';

import 'package:natrix/core.dart';
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/#/create_directory.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/systemd/systemd.dart';
import 'package:stepflow/src/io/steps/log_print.dart';

final NatrixCommand fixCommand = NatrixCommand(
  id: "fix",
  description: "Apply some fixes to encounter issues.",
  flags: [
    NatrixBoolFlag(
      id: "reset",
      tooltip: "Resets all settings and configuration.",
      value: false,
    ),
  ],
  callback: (final NatrixCallbackOptions options) async {
    final bool resetSettings = options.getFlag("reset").value;
    final Systemd systemd = Systemd.get();
    final bool hasSchedule = systemd.hasSchedule();

    final Duration? schedule = hasSchedule ? systemd.getSchedule() : null;

    await runWorkflow(
      Chain(
        steps: [
          Conditional(
            condition: hasSchedule,
            child: Chain(
              steps: [
                LogASCIIContext("Reinstall systemd scheduler..."),
                systemd.removeSchedule(),
                systemd.setupSchedule(
                  arguments: ["backups", "create"],
                  interval: schedule!,
                ),
              ],
            ),
          ),
          Conditional(
            condition: systemd.hasAutostart(),
            child: Chain(
              steps: [
                LogASCIIContext("Reinstall systemd boot service..."),
                systemd.removeAutostart(),
                systemd.setupAutostart(arguments: ["start"]),
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
  },
);
