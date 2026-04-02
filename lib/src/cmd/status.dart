import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:path/path.dart' as path;

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/steps/docker.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:td_erpnext/src/systemd/systemd.dart';

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

    final Settings settings = Settings.load();

    final String composeFilePath = path.join(
      settings.appDirectoryPath,
      "frappe_docker",
      "pwd.yml",
    );
    final Systemd systemd = Systemd.get();

    final bool configFound = File(Settings.configurationFilePath).existsSync();
    final bool hasSchedule = systemd.hasSchedule();
    final bool hasAutostart = systemd.hasAutostart();
    final bool installed = File(composeFilePath).existsSync();
    final bool running = DockerCompose.isRunning(
      composeFile: File(composeFilePath),
      workingDirectory: settings.appDirectoryPath,
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
      lines: NatrixColumn(
        lines: [
          ...NatrixBlock(
            heading: NatrixText("Installation:", style: .bold),
            content: NatrixStructure(
              padding: 0,
              spacePrefix: 1,
              sections: [
                NatrixLine(text: NatrixText("(Status) ") + erpnextStatus),
                NatrixLine(
                  text:
                      NatrixText("(Configuration file)  ") +
                      NatrixText(
                        configFound ? "✓ Found" : "✕ Not found",
                        foreground: configFound ? .green : .red,
                      ),
                ),
                NatrixLine(
                  text:
                      NatrixText("(Backup schedule)  ") +
                      NatrixText(
                        hasSchedule ? "✓ ${schedule!}" : "✕ Disabled",
                        foreground: hasSchedule ? .green : .red,
                      ),
                ),
                NatrixLine(
                  text:
                      NatrixText("(Autostart)  ") +
                      NatrixText(
                        hasAutostart ? "✓ Active" : "✕ Disabled",
                        foreground: hasAutostart ? .green : .red,
                      ),
                ),
              ],
            ),
          ).format(),
          ...NatrixBlock(
            heading: NatrixText("Connection:", style: .bold),
            content: NatrixStructure(
              padding: 0,
              spacePrefix: 1,
              sections: [
                NatrixLine(
                  text:
                      NatrixText("(container)  ") +
                      NatrixText(
                        "${settings.dockerContainerName}",
                        foreground: .blueAccent,
                      ),
                ),
                NatrixLine(
                  text:
                      NatrixText("(port)  ") +
                      NatrixText(
                        "${settings.connectionPort.toString()}",
                        foreground: .blueAccent,
                      ),
                ),
                NatrixLine(
                  text:
                      NatrixText("(site)  ") +
                      NatrixText(
                        "${settings.currentSite}",
                        foreground: .blueAccent,
                      ),
                ),
              ],
            ),
          ).format(),
        ],
      ).format(),
    );
  },
);

class StatusSection implements NatrixSection {
  final NatrixHeader header;

  const StatusSection({required this.header});

  @override
  List<NatrixText> format() {
    // TODO: implement format
    throw UnimplementedError();
  }

  @override
  // TODO: implement isEmpty
  bool get isEmpty => throw UnimplementedError();
}
