import 'dart:convert';
import 'dart:io';

import 'package:natrix/core.dart';
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/setup.dart';
import 'package:td_erpnext/src/docker.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/systemd/systemd.dart';

final NatrixCommand setupCommand = NatrixCommand(
  id: "setup",
  description: "Installs and starts frappe erpnext.",
  callback: (NatrixCallbackOptions options) async {
    if (options.getFlag("help").value) {
      return;
    }

    /**
     * Note that the Flags default values are the current settings, loaded from disk,
     * before initializing the programs command line interface.
     *
     * So, when we dump, and no actual changes to the settings were made, we just dump
     * what we loaded before.
     */
    final cP = options.getFlag(Settings.json(#connectionPort)) as NextIntFlag;
    final cS = options.getFlag(Settings.json(#currentSite)) as TextFlag;
    final dCN =
        options.getFlag(Settings.json(#dockerContainerName)) as TextFlag;
    final aDN = options.getFlag(Settings.json(#appDirectoryName)) as TextFlag;
    final lDN = options.getFlag(Settings.json(#logDirectoryName)) as TextFlag;
    final dRP = options.getFlag(Settings.json(#dbRootPassword)) as TextFlag;

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

    await runWorkflow(
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
          Systemd.setupAutostart(
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
  },
);
