import 'dart:io';

import 'package:natrix/io.dart';
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:stepflow_docker/docker_compose.dart' as dockerCompose;

import '../exception.dart';

class Start extends ConfigureStep {
  const Start();

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }
    return dockerCompose.Init(
      composeFile: composeFile,
      workingDirectory: Settings.appDirectoryPath,
      detach: true,
      callback: (chars) =>
          NatrixStdio().pipe(text: NatrixText(String.fromCharCodes(chars))),
    );
  }
}
