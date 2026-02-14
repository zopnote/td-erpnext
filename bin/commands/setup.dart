import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/setup.dart';
import 'package:td_erpnext/src/docker.dart';
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

  final Settings settings = Settings(
    connectionPort: cP.value,
    currentSite: cS.value,
    dockerContainerName: dCN.value,
    appDirectoryName: aDN.value,
    logDirectoryName: lDN.value,
    backupSourcePath: settingsAtProgramStart.backupSourcePath,
    backupDestinationPath: settingsAtProgramStart.backupDestinationPath,
  );

  settings.dump();

  await runWorkflow(
    SetupWorkflow(settings: settings),
    (response) {
      if (response.isError) {
        stderr.writeln(response.message);
        return;
      }
      stdout.writeln(response.message);
    },
  );
  return const Response();
}

class SetupWorkflow extends ConfigureStep {
  final Settings settings;
  const SetupWorkflow({required this.settings});
  @override
  Step configure() {
    return Chain(
      steps: [
        ERPNextInstall(
          appDirectoryPath: settings.appDirectoryPath,
          onCallback: (context, chars, error) => context.send(
            Response(
              String.fromCharCodes(chars),
              error ? Level.error : Level.normal,
            ),
          ),
        ),
        Docker.update(
          containers: [DockerContainer(settings.dockerContainerName)],
          settings: DockerUpdateSettings(restart: DockerRestartPolicy.no),
        ),
        Systemd.setupBoot(serviceName: Settings.serviceName, arguments: ["start"]),
      ],
    );
  }
}
