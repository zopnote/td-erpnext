import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

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

List<NatrixFlag> get settingFlags {
  return [
    IntFlag(
      name: Settings.json(#connectionPort),
      description:
          "Sets the port this manager tries to connect "
          "to of the frontend of the running erpnext"
          "in the docker container.",
      value: settingsAtProgramStart.connectionPort,
    ),
    (
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
  final NatrixStdio io = NatrixStdio();
  late final int terminalWidth;
  try {
    terminalWidth = stdout.terminalColumns;
  } on StdoutException catch (_) {
    terminalWidth = 60;
  }
  final String? user = Platform.environment['USER'];
  if (user != null && user.isNotEmpty && user != "root") {
    io.writeLines(
      lines: NatrixText(
        "This application needs "
        "root access to execute the desired commands. "
        "Ensure the permissions are provided.",
        foreground: .red,
      ).wrap(terminalWidth),
    );
    exit(1);
  }
  final NatrixPipeline pipeline = NatrixPipeline(
    arguments: arguments,
    globalFlags: [
      NatrixBoolFlag(
        id: "help",
        acronym: NatrixChar('h'),
        value: false,
        tooltip: "Displays usage information.",
      ),
    ],
  );
  pipeline.run(
    NatrixCommand(
      id: "td-erpnext",
      description:
          "Tool for automize backups and the management of the erpnext service under linux.",
      callback: (options) {
        final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
        io.writeLines(lines: theme.root.format());
      },
      hidden: true,
      inheritFlags: false,
      children: [
        NatrixCommand(
          id: "fix",
          description: "Apply some fixes to encounter issues.",
          callback: fixCommand,
          flags: [NatrixBoolFlag(id: "reset", value: false)],
        ),
        NatrixCommand(
          id: "start",
          description: "Start the ERPNext-instance.",
          callback: startCommand,
        ),
        NatrixCommand(
          id: "stop",
          description: "Stops the running ERPNext-instance.",
          callback: stopCommand,
        ),
        NatrixCommand(
          id: "status",
          description:
              "Status information about the installation and the manager.",
          callback: statusCommand,
        ),
        NatrixCommand(
          id: "uninstall",
          description: "Removes the installation securely.",
          callback: uninstallCommand,
          flags: [
            NatrixBoolFlag(
              id: "hard",
              tooltip: "Deletes all backups.",
              value: false,
            ),
          ],
        ),
        NatrixCommand(
          id: "setup",
          description: "Installs and starts frappe erpnext.",
          callback: setupCommand,
        ),
        NatrixCommand(
          id: "settings",
          description:
              "Adjust the settings. To adjust settings related to backups, use the corresponding command.",
          callback: settingsCommand,
        ),
        NatrixCommand(
          id: "backups",
          description: "Manage backups.",
          callback: backupsCommand,
          flags: [
            DurationFlag(
              id: "interval",
              value: Systemd.isSchedulerInstalled(Settings.serviceName)
                  ? Systemd.getSchedulerDuration(Settings.serviceName)
                  : Duration(days: 2),
              examples: [
                Duration(days: 1, hours: 12, minutes: 45),
                Duration(minutes: 20),
              ],
              tooltip: "Sets the schedule of backup creation.",
            ),
          ],
          children: [
            NatrixCommand(
              id: "on",
              description: "Enables backups of the erpnext volumes.",
              callback: backupsEnableCommand,
            ),
            NatrixCommand(
              id: "off",
              description: "Enables backups of the erpnext volumes.",
              inheritFlags: false,
              callback: backupsDisableCommand,
            ),
            NatrixCommand(
              id: "create",
              description: "Creates a backup.",
              inheritFlags: false,
              callback: backupsCreateCommand,
            ),
            NatrixCommand(
              id: "restore",
              tooltip: "Restores a backup.",
              description:
                  "Specify a backup by its name. See available backups with backups list.",
              callback: backupsRestoreCommand,
              argumentTip: "backup",
              inheritFlags: false,
              children: [
                NatrixCommand(
                  id: "last",
                  description: "Restores the last backup.",
                  callback: backupsRestoreLastCommand,
                ),
              ],
            ),
            NatrixCommand(
              id: "list",
              description: "Lists all available backups.",
              inheritFlags: true,
              callback: backupsListCommand,
            ),
          ],
        ),
      ],
    ),
  );
}
