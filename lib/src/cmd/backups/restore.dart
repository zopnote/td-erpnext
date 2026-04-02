import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/steps/restore.dart';
import 'restore/last.dart';
import 'package:td_erpnext/src/steps/docker.dart';
import 'package:td_erpnext/src/settings.dart';

final NatrixCommand backupsRestoreCommand = NatrixCommand(
  id: "restore",
  tooltip: "Restores a backup.",
  description:
      "Specify a backup by its id. See available backups with backups list.",
  argumentTip: "backup",
  inheritFlags: false,
  children: [backupsRestoreLastCommand],
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }
    if (options.args.isEmpty) {
      io.newLine(
        text: NatrixText(
          "Please specify a valid backup by id.",
          foreground: .red,
        ),
        output: .stderr,
      );
      return;
    }
    await runWorkflow(
      Chain(
        steps: [
          ERPNextRestore(
            container: DockerContainer(
              settingsAtProgramStart.dockerContainerName,
            ),
            restoreLast: false,
            backupBundleName: options.args.first,
            appDirectoryPath: settingsAtProgramStart.appDirectoryPath,
            currentSiteName: settingsAtProgramStart.currentSite,
            backupsDirectoryPath: settingsAtProgramStart.backupDestinationPath,
            workingDirectory: settingsAtProgramStart.appDirectoryPath,
            onCallback: (context, chars, error) => context.send(
              Response(
                String.fromCharCodes(chars),
                error ? Level.error : Level.normal,
              ),
            ),
          ),
        ],
      ),
      (response) => io.newLine(
        text: NatrixText(response.message),
        output: response.isError ? .stderr : .stdout,
      ),
    );
  },
);
