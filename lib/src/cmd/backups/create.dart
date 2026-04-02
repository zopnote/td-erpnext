import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/steps/backup.dart';
import 'package:td_erpnext/src/steps/docker.dart';
import 'package:td_erpnext/src/settings.dart';

final NatrixCommand backupsCreateCommand = NatrixCommand(
  id: "create",
  description: "Creates a backup.",
  inheritFlags: false,
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }

    final Settings settings = Settings.load();
    await runWorkflow(
      Chain(
        steps: [
          ERPNextBackup(
            container: DockerContainer(
              settings.dockerContainerName.value,
            ),
            currentSiteName: settings.currentSite.value,
            backupSourcePath: settings.backupSourcePath.value,
            backupDestinationPath: settings.backupDestinationPath.value,
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
