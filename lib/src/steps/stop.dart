import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/docker.dart';
import 'package:stepflow/src/io/steps/log_print.dart';

class Stop extends ConfigureStep {
  final DockerOutputCallback? onCallback;
  final String appDirectoryPath;

  Stop({required this.appDirectoryPath, this.onCallback});

  late final DockerOutputCallback _grayedCallback = (context, chars, error) =>
      this.onCallback?.call(
        context,
        LogColor.grayed(String.fromCharCodes(chars)).codeUnits,
        error,
      );
  @override
  Step configure() {
    final String composeFilePath = path.join(
      appDirectoryPath,
      "frappe_docker",
      "pwd.yml",
    );
    return Chain(
      steps: [
        LogASCIIContext("Stop $composeFilePath..."),
        DockerCompose.stop(
          composeFile: File(composeFilePath),
          workingDirectory: appDirectoryPath,
          onCallback: _grayedCallback,
        ),
      ],
    );
  }
}
