import 'dart:io';

import 'package:natrix/core.dart';
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/restore.dart';
import 'package:td_erpnext/src/docker.dart';
import 'package:td_erpnext/src/settings.dart';

final NatrixCommand backupsRestoreCommand = NatrixCommand(
  id: "restore",
  tooltip: "Restores a backup.",
  description:
      "Specify a backup by its id. See available backups with backups list.",
  argumentTip: "backup",
  inheritFlags: false,
  children: [backupsRestoreLastCommand],
  callback: (NatrixCallbackOptions options) async {
    if (options.getFlag("help").value) {
      return Response(options.command.formatSyntax());
    }
    if (options.argument.isEmpty) {
      return Response(options.command.formatSyntax());
    }
    final Response lastResponse = await runWorkflow(
      Chain(
        steps: [
          ERPNextRestore(
            container: DockerContainer(
              settingsAtProgramStart.dockerContainerName,
            ),
            restoreLast: false,
            backupBundleName: options.argument,
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
      (response) {
        if (response.isError) {
          stderr.writeln(response.message);
          return;
        }
        stdout.writeln(response.message);
      },
    );

    return Response("", lastResponse.level);
  },
);

final NatrixCommand backupsRestoreLastCommand = NatrixCommand(
  id: "last",
  description: "Restores the last backup.",
  callback: (NatrixCallbackOptions options) async {
    if (options.getFlag("help").value) {
      return Response(options.command.formatSyntax());
    }

    final Response lastResponse = await runWorkflow(
      ERPNextRestore(
        container: DockerContainer(settingsAtProgramStart.dockerContainerName),
        restoreLast: true,
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
      (response) {
        if (response.isError) {
          stderr.writeln(response.message);
          return;
        }
        stdout.writeln(response.message);
      },
    );

    return Response("", lastResponse.level);
  },
);
