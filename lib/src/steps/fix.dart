import 'dart:io';

import 'package:natrix/io.dart';
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import 'package:td_erpnext/src/steps/vendor/systemd.dart' as systemd;
import 'package:td_erpnext/src/utils.dart';

class Fix extends ConfigureStep {
  final bool hard;
  const Fix({required this.hard});

  @override
  Step configure() {
    final File composeFile = File(Settings.composeFilePath);
    if (!composeFile.existsSync()) {
      throw InstallationNotFoundException();
    }
    final bool isRunning = dockerCompose.isRunning(composeFile: composeFile);

    final NatrixStdio io = NatrixStdio();
    return Chain(
      steps: [
        Conditional(
          condition: isRunning,
          child: Chain(
            steps: [
              PrintNatrixLine(text: NatrixText("Stops docker container...")),
              dockerCompose.Stop(
                composeFile: composeFile,
                callback: (chars) {
                  io.newLine(
                    text: NatrixText(
                      String.fromCharCodes(chars),
                      foreground: .grayAccent,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        Conditional(
          condition: systemd.hasSchedule(),
          child: Chain(
            steps: [
              PrintNatrixLine(
                text: NatrixText("Reinstall systemd scheduler..."),
              ),
              systemd.RemoveSchedule(),
              systemd.SetupSchedule(
                args: ["backups", "create"],
                interval: systemd.getSchedule(),
              ),
            ],
          ),
        ),
        Conditional(
          condition: systemd.hasAutostart(),
          child: Chain(
            steps: [
              PrintNatrixLine(
                text: NatrixText("Reinstall systemd boot service..."),
              ),
              systemd.RemoveAutostart(),
              systemd.SetupAutostart(args: ["start"]),
            ],
          ),
        ),
        Conditional(
          condition: !File(Settings.settingsFilePath).existsSync() || hard,
          child: Chain(
            steps: [
              PrintNatrixLine(
                text: NatrixText("Create new configuration file..."),
              ),
              Runnable(() => Settings().dump()),
            ],
          ),
        ),
        Conditional(
          condition: !Directory(Settings.appDirectoryPath).existsSync(),
          child: Chain(
            steps: [
              PrintNatrixLine(text: NatrixText("Create app directory...")),
              CreateDirectory(
                Settings.appDirectoryPath,
                recursive: true,
                deleteIfExists: true,
              ),
            ],
          ),
        ),

        PrintNatrixLine(text: NatrixText("Starts docker container...")),
        dockerCompose.Init(
          composeFile: composeFile,
          detach: true,
          callback: (chars) {
            io.newLine(
              text: NatrixText(
                String.fromCharCodes(chars),
                foreground: .grayAccent,
              ),
            );
          },
        ),
        PrintNatrixLine(text: NatrixText("Applied some fixes.")),
      ],
    );
  }
}
