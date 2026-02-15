import 'dart:convert';
import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/setup.dart';
import 'package:td_erpnext/src/docker.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/systemd.dart';

Future<Response> setupCommand(CommandInformation info) async {
  if (info.getFlag("help").value) {
    return Response(info.command.formatSyntax(spacer: 25), Level.normal);
  }

  /**
   * Note that the Flags default values are the current settings, loaded from disk,
   * before initializing the programs command line interface.
   *
   * So, when we dump, and no actual changes to the settings were made, we just dump
   * what we loaded before.
   */
  final cP = info.getFlag(Settings.json(#connectionPort)) as IntFlag;
  final cS = info.getFlag(Settings.json(#currentSite)) as TextFlag;
  final dCN = info.getFlag(Settings.json(#dockerContainerName)) as TextFlag;
  final aDN = info.getFlag(Settings.json(#appDirectoryName)) as TextFlag;
  final lDN = info.getFlag(Settings.json(#logDirectoryName)) as TextFlag;
  final dRP = info.getFlag(Settings.json(#dbRootPassword)) as TextFlag;

  final Settings settings = Settings(
    connectionPort: cP.value,
    currentSite: cS.value,
    dockerContainerName: dCN.value,
    appDirectoryName: aDN.value,
    logDirectoryName: lDN.value,
    dbRootPassword: dRP.value,
    backupSourcePath: settingsAtProgramStart.backupSourcePath,
    backupDestinationPath: settingsAtProgramStart.backupDestinationPath,
  );

  settings.dump();

  if (settings != settingsAtProgramStart) {
    stdout.write(
      JsonEncoder.withIndent('  ')
          .convert(settings.document)
          .replaceAll("{", "")
          .replaceAll("}", "")
          .replaceAll("\"", "")
          .replaceAll(",", ""),
    );
  }

  final Response lastResponse = await runWorkflow(
    Chain(
      steps: [
        LogASCIIContext("Setup docker container..."),
        ERPNextSetup(
          appDirectoryPath: settings.appDirectoryPath,
          onCallback: (context, chars, error) => context.send(
            Response(
              String.fromCharCodes(chars),
              error ? Level.error : Level.normal,
            ),
          ),
        ),
        LogASCIIContext("Set restart policy of container..."),
        Docker.update(
          containers: [DockerContainer(settings.dockerContainerName)],
          settings: DockerUpdateSettings(restart: DockerRestartPolicy.no),
        ),
        LogASCIIContext("Add systemd boot service..."),
        Systemd.setupBoot(
          serviceName: Settings.serviceName,
          arguments: ["start"],
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
