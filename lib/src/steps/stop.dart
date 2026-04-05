import 'dart:io';

import 'package:natrix/core.dart';
import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/settings.dart';

import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import '../utils.dart';

class StopException implements Exception {
  final String message;

  const StopException(this.message);

  static StopException dockerError(String error) => StopException(
    "An error occurred while the "
    "stop of the docker containers: $error",
  );

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    if (other is! StopException) {
      return false;
    }
    return other.message == message;
  }
}

class Stop extends ConfigureStep {
  const Stop();

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }
    return Chain(
      steps: [
        PrintNatrixLine(text: NatrixText("Stop ${composeFile.path}...")),
        dockerCompose.Stop(
          composeFile: composeFile,
          workingDirectory: Settings.appDirectoryPath,
          callback: (chars, isError) {
            if (isError) {
              throw StopException.dockerError(String.fromCharCodes(chars));
            }
          },
        ),
      ],
    );
  }
}
