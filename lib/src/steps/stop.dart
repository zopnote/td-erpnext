import 'dart:io';

import 'package:natrix/io.dart';
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:stepflow_docker/docker_compose.dart' as dockerCompose;

import '../exception.dart';

class Stop extends ConfigureStep {
  const Stop();

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }
    if (!dockerCompose.isRunning(composeFile: composeFile)) {
      throw NotRunningException();
    }
    return dockerCompose.Stop(
      composeFile: composeFile,
      workingDirectory: Settings.appDirectoryPath,
      callback: (chars) => NatrixStdio().pipe(
        text: NatrixText(String.fromCharCodes(chars), foreground: .grayAccent),
      ),
    );
  }
}
