import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/restore.dart';
import 'package:td_erpnext/src/docker.dart';
import 'package:td_erpnext/src/settings.dart';

Future<Response> backupsRestoreCommand(CommandInformation info) async {
  if (info.getFlag("help").value) {
    return Response(info.command.formatSyntax());
  }
  if (info.argument.isEmpty) {
    return Response(info.command.formatSyntax());
  }
  final Response lastResponse = await runWorkflow(
    Chain(
      steps: [
        ERPNextRestore(
          container: DockerContainer(
            settingsAtProgramStart.dockerContainerName,
          ),
          restoreLast: false,
          backupBundleName: info.argument,
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
}

Future<Response> backupsRestoreLastCommand(CommandInformation info) async {
  if (info.getFlag("help").value) {
    return Response(info.command.formatSyntax());
  }

  final Response lastResponse = await runWorkflow(
    ERPNextRestore(
      container: DockerContainer(
        settingsAtProgramStart.dockerContainerName,
      ),
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
}
