import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';


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

    final File composeFile = File(Settings.composeFilePath);
    final bool configFound = File(Settings.settingsFilePath).existsSync();
    final bool hasSchedule = systemd.hasSchedule();
    final bool hasAutostart = systemd.hasAutostart();
    final bool installed = composeFile.existsSync();
    final bool running = dockerCompose.isRunning(
      composeFile: composeFile,
      workingDirectory: Settings.appDirectoryPath,
    );
    final String? schedule = hasSchedule
        ? DurationFlag(id: "", value: systemd.getSchedule()).getFormatted()
        : null;
    io.writeLines(
      lines: NatrixStructure(
        padding: 0,
        spacePrefix: 1,
        sections: [
          NatrixLine(
            text:
                NatrixText("(ERPNext) ") +
                (installed
                    ? running
                          ? NatrixText("• Running", foreground: .green)
                          : NatrixText(
                              "✓ Installed, not running",
                              foreground: .cyan,
                            )
                    : NatrixText("✕ Not found", foreground: .red)),
          ),
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
      ).format(),
    );
  },
);
