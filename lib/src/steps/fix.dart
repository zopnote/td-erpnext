import 'dart:io';

import 'package:natrix/io.dart';
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/vendor/systemd.dart' as systemd;
import 'package:td_erpnext/src/utils.dart';

class Fix extends ConfigureStep {
  final bool resetSettings;
  const Fix({required this.resetSettings});

  @override
  Step configure() {
    final NatrixStdio io = NatrixStdio();

    if (!File(Settings.composeFilePath).existsSync()) {
      throw InstallationNotFoundException();
    }
    final NatrixMount mount = io.newLine();
    return Chain(
      steps: [
        Conditional(
          condition: systemd.hasSchedule(),
          child: Chain(
            steps: [
              RenewNatrixLine(
                mount: mount,
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
              RenewNatrixLine(
                mount: mount,
                text: NatrixText("Reinstall systemd boot service..."),
              ),
              systemd.RemoveAutostart(),
              systemd.SetupAutostart(args: ["start"]),
            ],
          ),
        ),
        Conditional(
          condition:
              !File(Settings.configurationFilePath).existsSync() ||
              resetSettings,
          child: Chain(
            steps: [
              RenewNatrixLine(
                mount: mount,
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
              RenewNatrixLine(
                mount: mount,
                text: NatrixText("Create app directory..."),
              ),
              CreateDirectory(
                Settings.appDirectoryPath,
                recursive: true,
                deleteIfExists: true,
              ),
            ],
          ),
        ),

        RenewNatrixLine(mount: mount, text: NatrixText("Applied some fixes.")),
      ],
    );
  }
}
