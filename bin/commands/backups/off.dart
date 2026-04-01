import 'dart:io';

import 'package:natrix/core.dart';
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/systemd/systemd.dart';

final NatrixCommand backupsDisableCommand = NatrixCommand(
  id: "off",
  description: "Enables backups of the erpnext volumes.",
  inheritFlags: false,
  callback: (NatrixCallbackOptions options) async {
    final Response lastResponse = await runWorkflow(
      Chain(steps: [Systemd.removeSchedule(Settings.serviceName)]),
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
    return Response("Removed the scheduler service.");
  },
);
