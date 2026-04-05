import 'dart:io';

import 'package:natrix/io.dart';
import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import 'package:td_erpnext/src/steps/vendor/systemd.dart' as systemd;
import 'package:td_erpnext/src/utils.dart';

class UninstallException implements Exception {
  final String message;
  const UninstallException(this.message);

  static UninstallException dockerError(String error) => UninstallException(
    "An error occurred while the "
    "shutdown of the docker container: $error",
  );
  @override
  String toString() => message;

  @override
  bool operator ==(Object other) {
    if (other is! UninstallException) {
      return false;
    }
    return other.message == message;
  }
}

class Uninstall extends ConfigureStep {
  final bool removeBackups;
  const Uninstall({this.removeBackups = false});

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }
    final NatrixStdio io = NatrixStdio();
    final Settings settings = Settings.fromDisk();
    final void Function(List<int>) outputCallback = (chars) =>
        io.newLine(text: NatrixText(String.fromCharCodes(chars)));
    return Chain(
      steps: [
        const PrintNatrixLine(
          text: NatrixText("Uninstall dockerimages and -volumes..."),
        ),
        dockerCompose.Shutdown(
          composeFile: composeFile,
          removeImages: true,
          removeVolumes: true,
          workingDirectory: Settings.appDirectoryPath,
          callback: (chars, isError) {
            if (isError) {
              throw UninstallException.dockerError(String.fromCharCodes(chars));
            }
          },
        ),
        PrintNatrixLine(
          text: NatrixText("Remove ${Settings.appDirectoryPath}..."),
        ),
        Shell(
          program: "rm",
          arguments: ["-r", "-f", Settings.appDirectoryPath],
        ),
        Conditional(
          condition: removeBackups,
          child: Chain(
            steps: [
              PrintNatrixLine(
                text: NatrixText(
                  "Remove ${settings.backupStoragePath.value}...",
                ),
              ),
              Shell(
                program: "rm",
                arguments: ["-r", "f", settings.backupStoragePath.value],
                onStderr: (chars) => outputCallback(chars),
                onStdout: (chars) => outputCallback(chars),
              ),
            ],
          ),
        ),
        const PrintNatrixLine(text: NatrixText("Remove systemd services...")),
        systemd.RemoveAutostart(),
        systemd.RemoveSchedule(),
      ],
    );
  }
}
