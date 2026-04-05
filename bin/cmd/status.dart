import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:path/path.dart' as path;

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/steps/vendor/docker_compose.dart'
    as dockerCompose;
import 'package:td_erpnext/src/steps/vendor/systemd.dart' as systemd;

final NatrixCommand statusCommand = NatrixCommand(
  id: "status",
  description: "Status information about the installation and the manager.",
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }

    final Settings settings = Settings.fromDisk();

    final String composeFilePath = path.join(
      Settings.appDirectoryPath,
      "frappe_docker",
      "pwd.yml",
    );
    final bool configFound = File(Settings.configurationFilePath).existsSync();
    final bool hasSchedule = systemd.hasSchedule();
    final bool hasAutostart = systemd.hasAutostart();
    final bool installed = File(composeFilePath).existsSync();
    final bool running = dockerCompose.isRunning(
      composeFile: File(composeFilePath),
      workingDirectory: Settings.appDirectoryPath,
    );
    final String? schedule = hasSchedule
        ? DurationFlag(id: "", value: systemd.getSchedule()).getFormatted()
        : null;

    NatrixText erpnextStatus = NatrixText("✕ Not found", foreground: .red);
    if (installed) {
      erpnextStatus = NatrixText("✓ Installed, not running", foreground: .cyan);
    }
    if (running) {
      erpnextStatus = NatrixText("• Running", foreground: .green);
    }
    io.writeLines(
      lines: status(
        dockerContainerName: settings.frontendContainer.value,
        connectionPort: settings.port.value,
        currentSite: settings.frontendSite.value,
        erpnextStatus: erpnextStatus,
        configFound: configFound,
        hasSchedule: hasSchedule,
        hasAutostart: hasAutostart,
        schedule: schedule,
      ).format(),
    );
  },
);

NatrixSection status({
  required String dockerContainerName,
  required int connectionPort,
  required String currentSite,
  required NatrixText erpnextStatus,
  required bool configFound,
  required bool hasSchedule,
  required bool hasAutostart,
  required String? schedule,
}) => NatrixStructure(
  sections: [
    NatrixBlock(
      heading: NatrixText("Installation:", style: .bold),
      content: NatrixStructure(
        padding: 0,
        spacePrefix: 1,
        sections: [
          NatrixLine(text: NatrixText("(ERPNext) ") + erpnextStatus),
          NatrixLine(
            text:
                NatrixText("(Configuration file) ") +
                NatrixText(
                  configFound ? "✓ Found" : "✕ Not found",
                  foreground: configFound ? .green : .red,
                ),
          ),
          NatrixLine(
            text:
                NatrixText("(Backup schedule) ") +
                NatrixText(
                  hasSchedule ? "✓ ${schedule!}" : "✕ Disabled",
                  foreground: hasSchedule ? .green : .red,
                ),
          ),
          NatrixLine(
            text:
                NatrixText("(Autostart) ") +
                NatrixText(
                  hasAutostart ? "✓ Active" : "✕ Disabled",
                  foreground: hasAutostart ? .green : .red,
                ),
          ),
        ],
      ),
    ),
    NatrixBlock(
      heading: NatrixText("Connection:", style: .bold),
      content: NatrixStructure(
        padding: 0,
        spacePrefix: 1,
        sections: [
          NatrixLine(
            text:
                NatrixText("(container) ") +
                NatrixText(dockerContainerName, foreground: .blue),
          ),
          NatrixLine(
            text:
                NatrixText("(port) ") +
                NatrixText(connectionPort.toString(), foreground: .blue),
          ),
          NatrixLine(
            text:
                NatrixText("(site) ") +
                NatrixText(currentSite, foreground: .blue),
          ),
        ],
      ),
    ),
  ],
);
