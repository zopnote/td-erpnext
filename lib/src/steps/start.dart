import 'dart:io';

import 'package:natrix/io.dart';
import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import 'package:td_erpnext/src/utils.dart';

class StartException implements Exception {
  final String message;

  const StartException(this.message);

  static StartException dockerError(String error) => StartException(
    "An error occurred while the "
    "start up of the docker containers: $error",
  );

  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    if (other is! StartException) {
      return false;
    }
    return other.message == message;
  }
}

class Start extends ConfigureStep {
  const Start();

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }
    dockerCompose.OutputCallback callback = (chars, isError) {
      if (isError) {
        throw StartException.dockerError(String.fromCharCodes(chars));
      }
    };
    return Chain(
      steps: [
        PrintNatrixLine(text: NatrixText("Start ${composeFile.path}...")),
        dockerCompose.Init(
          composeFile: composeFile,
          workingDirectory: Settings.appDirectoryPath,
          detach: true,
          callback: callback,
        ),
      ],
    );
  }
}
