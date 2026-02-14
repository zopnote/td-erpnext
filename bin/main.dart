import 'dart:io';

import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/systemd.dart';
import 'commands/status.dart';

import 'commands/settings.dart';
import 'commands/setup.dart';
import 'commands/backups.dart';

List<Flag> get settingFlags {
  return [
    IntFlag(
      name: Settings.json(#connectionPort),
      description:
          "Sets the port this manager tries to connect "
          "to of the frontend of the running erpnext"
          "in the docker container.",
      value: settingsAtProgramStart.connectionPort,
    ),
    TextFlag(
      name: Settings.json(#currentSite),
      description:
          "Sets the current site this manager tries "
          "to connect to of the frontend of the running "
          "erpnext in the docker container.",
      value: settingsAtProgramStart.currentSite,
    ),
    TextFlag(
      name: Settings.json(#dockerContainerName),
      description:
          "Sets the docker container name this manager tries "
          "to connect to of the frontend of the running "
          "erpnext in the docker container.",
      value: settingsAtProgramStart.dockerContainerName,
    ),
    TextFlag(
      name: Settings.json(#appDirectoryName),
      description:
          "Location relative to the apps root where the data "
          "files and directories of the working process are stored.",
      value: settingsAtProgramStart.appDirectoryName,
    ),
    TextFlag(
      name: Settings.json(#logDirectoryName),
      description:
          "Location relative to the apps root where the log "
          "files of the working process are stored.",
      value: settingsAtProgramStart.logDirectoryName,
    ),
  ];
}

Future<void> main(List<String> arguments) async => exitCode = await runCommand(
  Command(
    use: "td-erpnext",
    description:
        "Tool for automize backups and the management of the erpnext service under linux.",
    subCommands: [
      Command(
        use: "status",
        description:
            "Status information about the installation and the manager.",
        run: statusCommand,
      ),
      Command(
        use: "setup",
        description: "Installs and starts frappe erpnext.",
        flags: settingFlags,
        run: setupCommand,
      ),
      Command(
        use: "settings",
        description:
            "Adjust the settings. To adjust settings related to backups, use the corresponding command.",
        flags: settingFlags,
        run: settingsCommand,
      ),
      Command(
        use: "backups",
        description: "Manage backups.",
        flags: [
          DurationFlag(
            name: "interval",
            value: Systemd.isSchedulerInstalled(Settings.serviceName)
                ? Systemd.getSchedulerDuration(Settings.serviceName)
                : Duration(days: 2),
            description: "Sets the schedule of backup creation.",
            examples: [
              Duration(days: 1, hours: 12, minutes: 45),
              Duration(minutes: 20),
            ],
          ),
          TextFlag(
            name: Settings.json(#backupSourcePath),
            description:
                "Sets the backup source directory where backups "
                "will be retrieved from. The entire path is in the corresponding "
                "docker container.",
            value: settingsAtProgramStart.backupSourcePath,
          ),
          TextFlag(
            name: Settings.json(#backupDestinationPath),
            description:
                "Sets the backup directory where backups get stored. "
                "Path in the filesystem.",
            value: settingsAtProgramStart.backupDestinationPath,
          ),
        ],
        subCommands: [
          Command(
            use: "on",
            description: "Enables backups of the erpnext volumes.",
            inheritFlags: true,
            run: backupsEnableCommand,
          ),
          Command(
            use: "off",
            description: "Enables backups of the erpnext volumes.",
            inheritFlags: false,
            run: backupsDisableCommand,
          ),
          Command(
            use: "create",
            description: "Creates a backup.",
            inheritFlags: false,
            run: backupsCreateCommand,
          ),
          Command(
            use: "restore",
            description: "Restores a backup.",
            inheritFlags: false,
            flags: [
              TextFlag(
                name: "path",
                description: "Path to a specific backup directory. If not provided, the latest backup will be used.",
                value: "",
              ),
            ],
            run: backupsRestoreCommand,
          ),
          Command(
            use: "list",
            description: "Lists all available backups.",
            inheritFlags: true,
            run: backupsListCommand,
          ),
        ],
        run: backupsCommand,
      ),
    ],
    run: (info) => Response(info.formatSyntax(), Level.normal),
  ),
  arguments,
);
