import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:stepflow/core.dart';
import 'package:stepflow/src/io/steps/log_print.dart';

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/docker/docker.dart';
import 'package:td_erpnext/src/steps/setup.dart';
import 'package:td_erpnext/src/steps/systemd/steps/setup_autostart.dart';

import 'package:td_erpnext/src/steps/systemd/systemd.dart';

final NatrixCommand setupCommand = NatrixCommand(
  id: "setup",
  description: "Installs and starts frappe erpnext.",
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }
    final Systemd systemd = Systemd.get();
    final Docker docker = Docker();
    final Settings settings = Settings.fromDisk();

    await runWorkflow(
      Chain(
        steps: [
          LogASCIIContext("Setup docker container..."),
          Setup(
            appDirectoryPath: Settings.appDirectoryPath,
            onCallback: (context, chars, error) => context.send(
              Response(
                String.fromCharCodes(chars),
                error ? Level.error : Level.normal,
              ),
            ),
          ),
          LogASCIIContext("Set restart policy of container..."),
          docker.update(
            UpdateSettings(
              containers: [DockerContainer(settings.frontendContainer.value)],
              config: DockerUpdateConfig(restart: DockerRestartPolicy.no),
            ),
          ),
          LogASCIIContext("Add systemd boot service..."),
          systemd.setupAutostart(SetupAutostartSettings(args: ["start"])),
        ],
      ),
      (response) => io.newLine(
        text: NatrixText(response.message),
        output: response.isError ? .stderr : .stdout,
      ),
    );
  },
);
