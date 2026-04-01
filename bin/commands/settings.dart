import 'dart:convert';
import 'dart:io';

import 'package:natrix/core.dart';
import 'package:stepflow/io.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/flags.dart';

final NatrixCommand settingsCommand = NatrixCommand(
  id: "settings",
  description:
      "Adjust the settings. To adjust settings related to backups, use the corresponding command.",
  callback: (NatrixCallbackOptions options) async {
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
    final cP = info.getFlag(Settings.json(#connectionPort)) as NextIntFlag;
    final cS = info.getFlag(Settings.json(#currentSite)) as TextFlag;
    final dCN = info.getFlag(Settings.json(#dockerContainerName)) as TextFlag;
    final aDN = info.getFlag(Settings.json(#appDirectoryName)) as TextFlag;
    final lDN = info.getFlag(Settings.json(#logDirectoryName)) as TextFlag;
    final bSP = info.getFlag(Settings.json(#backupSourcePath)) as TextFlag;
    final bDP = info.getFlag(Settings.json(#backupDestinationPath)) as TextFlag;

    final Settings settings = Settings(
      connectionPort: cP.value,
      currentSite: cS.value,
      dockerContainerName: dCN.value,
      appDirectoryName: aDN.value,
      logDirectoryName: lDN.value,
      backupSourcePath: bSP.value,
      backupDestinationPath: bDP.value,
    );

    if (settings == settingsAtProgramStart) {
      stdout.writeln(
        LogColor.yellowed(
          "Note that no changes were made. Use '--help' to see the changeable settings.",
        ),
      );
      return Response(
        "The current settings are the following:"
        "\n${JsonEncoder.withIndent('  ').convert(settings.document).replaceAll("{", "").replaceAll("}", "").replaceAll("\"", "").replaceAll(",", "")}",
      );
    }
    settings.dump();

    return Response(
      "Adjusted the settings to the following: "
      "\n${JsonEncoder.withIndent('  ').convert(settings.document).replaceAll("{", "").replaceAll("}", "").replaceAll("\"", "").replaceAll(",", "")}",
    );
  },
);
