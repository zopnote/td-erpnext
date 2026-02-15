import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

import 'package:td_erpnext/backup.dart';
import 'package:td_erpnext/src/docker.dart';
import 'package:td_erpnext/src/settings.dart';

Future<Response> backupsCreateCommand(CommandInformation info) async {

  final Response lastResponse = await runWorkflow(
    Chain(
      steps: [
        ERPNextBackup(
          container: DockerContainer(
            settingsAtProgramStart.dockerContainerName,
          ),
          currentSiteName: settingsAtProgramStart.currentSite,
          onCallback: (context, chars, error) => context.send(
            Response(
              String.fromCharCodes(chars),
              error ? Level.error : Level.normal,
            ),
          ),
          backupSourcePath: settingsAtProgramStart.backupSourcePath,
          backupDestinationPath: settingsAtProgramStart.backupDestinationPath,
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
