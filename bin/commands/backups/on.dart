import 'dart:io';

import 'package:natrix/core.dart';
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/systemd/systemd.dart';

final NatrixCommand backupsEnableCommand = NatrixCommand(
  id: "on",
  description: "Enables backups of the erpnext volumes.",
  callback: (NatrixCallbackOptions options) async {
    final bP = options.getFlag("interval") as DurationFlag;

    final Response lastResponse = await runWorkflow(
      Chain(
        steps: [
          Systemd.setupSchedule(
            serviceName: Settings.serviceName,
            arguments: ["backups", "create"],
            interval: bP.value,
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
    if (lastResponse.isError) {
      return Response("An error occurred.", Level.critical);
    }
    return Response(
      "Installed schedule service with a interval of ${bP.getFormatted()}.",
    );
  },
);
