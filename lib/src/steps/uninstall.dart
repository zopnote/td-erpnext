import 'dart:io';

import 'package:natrix/io.dart';
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
  final bool hard;
  const Uninstall({this.hard = false});

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }

    final void Function(List<int>) onStderr = (chars) {
      final String s = String.fromCharCodes(chars);
      if (s.toLowerCase().contains("error")) {
        throw UninstallException(s);
      }
    };

    final NatrixStdio io = NatrixStdio();
    final Settings settings = Settings.fromDisk();
    return Chain(
      steps: [
        const PrintNatrixLine(text: NatrixText("Remove docker container...")),
        dockerCompose.Delete(
          composeFile: composeFile,
          removeImages: true,
          removeVolumes: true,
          workingDirectory: Settings.appDirectoryPath,
          callback: (chars) {
            io.pipe(text: NatrixText(String.fromCharCodes(chars), foreground: .grayAccent));
          },
        ),
        PrintNatrixLine(
          text: NatrixText("Remove ${Settings.appDirectoryPath}..."),
        ),
        Shell(
          program: "rm",
          arguments: ["-r", "-f", Settings.appDirectoryPath],
          onStderr: onStderr,
        ),
        Conditional(
          condition: hard,
          child: Chain(
            steps: [
              PrintNatrixLine(
                text: NatrixText(
                  "Remove ${settings.backupStoragePath.value}...",
                ),
              ),
              Shell(
                program: "rm",
                arguments: ["-r", "-f", settings.backupStoragePath.value],
                onStderr: onStderr,
              ),
              Conditional(
                condition: File(Settings.settingsFilePath).existsSync(),
                child: Chain(
                  steps: [
                    PrintNatrixLine(
                      text: NatrixText(
                        "Remove ${Settings.settingsFilePath}...",
                      ),
                    ),
                    Shell(
                      program: "rm",
                      arguments: ["-f", Settings.settingsFilePath],
                      onStderr: onStderr,
                    ),
                  ],
                ),
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
