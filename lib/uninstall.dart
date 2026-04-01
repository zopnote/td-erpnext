
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/docker.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/settings.dart';

import 'src/systemd/systemd.dart';
import 'src/systemd/autostart.dart';
import 'src/systemd/schedule.dart';

class Uninstall extends ConfigureStep {
  final DockerOutputCallback? onCallback;
  final String appDirectoryPath;
  final bool removeBackups;
  final String backupsDirectoryPath;
  Uninstall({
    required this.appDirectoryPath,
    this.onCallback,
    this.removeBackups = false,
    this.backupsDirectoryPath = "",
  });

  late final DockerOutputCallback _grayedCallback = (context, chars, error) =>
      this.onCallback?.call(
        context,
        LogColor.grayed(String.fromCharCodes(chars)).codeUnits,
        error,
      );
  @override
  Step configure() {
    if (removeBackups && backupsDirectoryPath.isEmpty) {
      throw Exception(
        "If you want to remove backups, "
            "you have to specify the backups directory "
            "in order to get it removed.",
      );
    }
    final String composeFilePath = path.join(
      appDirectoryPath,
      "frappe_docker",
      "pwd.yml",
    );
    return Chain(
      steps: [
        LogASCIIContext("Uninstall dockerimages and -volumes..."),
        DockerCompose.shutdown(
          composeFile: File(composeFilePath),
          onCallback: _grayedCallback,
          removeImages: true,
          removeVolumes: true,
        ),
        LogASCIIContext("Remove $appDirectoryPath..."),
        Shell(
          program: "rm",
          arguments: ["-r", "-f", appDirectoryPath],
          onStderr: (context, chars) => _grayedCallback(context, chars, true),
          onStdout: (context, chars) => _grayedCallback(context, chars, false),
        ),
        Conditional(
          condition: removeBackups,
          child: Chain(steps: [
            LogASCIIContext("Remove $backupsDirectoryPath..."),
            Shell(
              program: "rm",
              arguments: ["-r", "f", backupsDirectoryPath],
              onStderr: (context, chars) => _grayedCallback(context, chars, true),
              onStdout: (context, chars) => _grayedCallback(context, chars, false),
            )
          ]),
        ),
        LogASCIIContext("Remove systemd services..."),
        Systemd.removeAutostart(Settings.serviceName),
        Systemd.removeSchedule(Settings.serviceName),
      ],
    );
  }
}
