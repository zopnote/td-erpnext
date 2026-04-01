import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/systemd/systemd.dart';

import 'commands/status.dart';
import 'commands/settings.dart';
import 'commands/setup.dart';
import 'commands/uninstall.dart';
import 'commands/fix.dart';
import 'commands/stop.dart';
import 'commands/start.dart';

import 'commands/backups.dart';
import 'commands/backups/create.dart';
import 'commands/backups/list.dart';
import 'commands/backups/off.dart';
import 'commands/backups/on.dart';
import 'commands/backups/restore.dart';

List<NatrixFlag> get settingFlags {
  return [
    NextIntFlag(
      id: Settings.json(#connectionPort),
      tooltip:
          "Sets the port this manager tries to connect "
          "to of the frontend of the running erpnext"
          "in the docker container.",
      value: settingsAtProgramStart.connectionPort,
    ),
    NatrixTextFlag(
      id: Settings.json(#currentSite),
      tooltip:
          "Sets the current site this manager tries "
          "to connect to of the frontend of the running "
          "erpnext in the docker container.",
      value: settingsAtProgramStart.currentSite,
    ),
    NatrixTextFlag(
      id: Settings.json(#dockerContainerName),
      tooltip:
          "Sets the docker container id this manager tries "
          "to connect to of the frontend of the running "
          "erpnext in the docker container.",
      value: settingsAtProgramStart.dockerContainerName,
    ),
    NatrixTextFlag(
      id: Settings.json(#appDirectoryName),
      tooltip:
          "Location relative to the apps root where the data "
          "files and directories of the working process are stored.",
      value: settingsAtProgramStart.appDirectoryName,
    ),
    NatrixTextFlag(
      id: Settings.json(#logDirectoryName),
      tooltip:
          "Location relative to the apps root where the log "
          "files of the working process are stored.",
      value: settingsAtProgramStart.logDirectoryName,
    ),
    NatrixTextFlag(
      id: Settings.json(#dbRootPassword),
      tooltip: "The root password of the database of the erpnext installation.",
      value: settingsAtProgramStart.dbRootPassword,
    ),
    NatrixTextFlag(
      id: Settings.json(#backupSourcePath),
      tooltip:
          "Sets the backup source directory where backups "
          "will be retrieved from. The entire path is in the corresponding "
          "docker container.",
      value: settingsAtProgramStart.backupSourcePath,
    ),
    NatrixTextFlag(
      id: Settings.json(#backupDestinationPath),
      tooltip:
          "Sets the backup directory where backups get stored. "
          "Path in the filesystem.",
      value: settingsAtProgramStart.backupDestinationPath,
    ),
  ];
}

Future<void> main(List<String> arguments) async {
  final String? user = Platform.environment['USER'];
  if (user != null && user.isNotEmpty && user != "root") {
    late final int terminalWidth;
    try {
      terminalWidth = stdout.terminalColumns;
    } on StdoutException catch (_) {
      terminalWidth = 60;
    }
    NatrixStdio().writeLines(
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
      hidden: true,
      inheritFlags: false,
      children: [
        fixCommand,
        startCommand,
        stopCommand,
        statusCommand,
        uninstallCommand,
        setupCommand,
        settingsCommand,
        backupsCommand,
      ],
      callback: (options) {
        final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
        NatrixStdio().writeLines(lines: theme.root.format());
      },
    ),
  );
}
