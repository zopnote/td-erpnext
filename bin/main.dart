import 'dart:io';

import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/systemd.dart';
import 'commands/status.dart';

import 'commands/settings.dart';
import 'commands/setup.dart';
import 'commands/backups.dart';
import 'commands/backups/create.dart';
import 'commands/backups/list.dart';
import 'commands/backups/off.dart';
import 'commands/backups/on.dart';
import 'commands/backups/restore.dart';
import 'commands/uninstall.dart';
import 'commands/fix.dart';
import 'commands/stop.dart';
import 'commands/start.dart';

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
    TextFlag(
      name: Settings.json(#dbRootPassword),
      description:
          "The root password of the database of the erpnext installation.",
      value: settingsAtProgramStart.dbRootPassword,
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
  ];
}

Future<void> main(List<String> arguments) async {
  final String? user = Platform.environment['USER'];
  if (user != null && user.isNotEmpty && user != "root") {
    throw Exception(
      "This application needs "
      "root access to execute the desired commands. "
      "Ensure the permissions are provided.",
    );
  }
  exitCode = await runCommand(
    Command(
      use: "td-erpnext",
      description:
          "Tool for automize backups and the management of the erpnext service under linux.",
      subCommands: [
        Command(
          use: "fix",
          description: "Apply some fixes to encounter issues.",
          flags: [BoolFlag(name: "reset_settings", value: false)],
          run: fixCommand,
        ),
        Command(
          use: "start",
          description: "Start the ERPNext-instance.",
          run: startCommand,
        ),
        Command(
          use: "stop",
          description: "Stops the running ERPNext-instance.",
          run: stopCommand,
        ),
        Command(
          use: "status",
          description:
              "Status information about the installation and the manager.",
          run: statusCommand,
        ),
        Command(
          use: "uninstall",
          description: "Removes the installation securely.",
          flags: [
            BoolFlag(
              name: "remove_backups",
              description:
                  "If the backups managed by this instance should also be deleted.",
              value: false,
            ),
          ],
          run: uninstallCommand,
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
              subCommands: [
                Command(
                  use: "<backup>",
                  description:
                      "Specify a backup by its name. See available backups with backups list.",
                  run: (info) => Response(info.command.formatSyntax()),
                ),
                Command(
                  use: "last",
                  description: "Restores the last backup.",
                  run: backupsRestoreLastCommand,
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
}
