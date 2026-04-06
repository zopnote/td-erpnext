import 'dart:io';

import 'package:natrix/io.dart';
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import 'package:td_erpnext/src/utils.dart';

class Start extends ConfigureStep {
  const Start();

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }
    final NatrixStdio io = NatrixStdio();
    dockerCompose.OutputCallback callback = (chars) =>
        io.pipe(text: NatrixText(String.fromCharCodes(chars)));
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
