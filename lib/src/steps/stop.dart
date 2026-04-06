import 'dart:io';

import 'package:natrix/io.dart';
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/settings.dart';

import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import 'package:td_erpnext/src/utils.dart';

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
    final NatrixStdio io = NatrixStdio();
    return Chain(
      steps: [
        PrintNatrixLine(text: NatrixText("Stop ${composeFile.path}...")),
        dockerCompose.Stop(
          composeFile: composeFile,
          workingDirectory: Settings.appDirectoryPath,
          callback: (chars) =>
              io.pipe(text: NatrixText(String.fromCharCodes(chars), foreground: .grayAccent)),
        ),
      ],
    );
  }
}
