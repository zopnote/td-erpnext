import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:path/path.dart' as path;

import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/docker.dart';
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
    final Systemd systemd = Systemd(Settings.serviceName);

    final bool configFound = File(
      Settings.configurationFilePath,
    ).existsSync();
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
      lines: NatrixBlock(
        heading: NatrixText(
          "Status of the current installation:",
          style: .bold,
        ),
        content: NatrixStructure(
          sections: [
            NatrixLine(text: NatrixText("(ERPNext) ") + erpnextStatus),
            NatrixLine(
              text: NatrixText("(Configuration file)  ") + NatrixText(
                configFound ? "✓ Found" : "✕ Not found",
                foreground: configFound ? .green : .red,
              ),
            ),
            NatrixLine(
              text: NatrixText("(Backup schedule)  ") + NatrixText(
                hasSchedule ? "✓ Found" : "✕ Not found",
                foreground: configFound ? .green : .red,
              ),
            ),

          ],
        ),
      ).format(),
    );
    //    return Response("""
    //${info.command.description}
    //ERPNext-Installation: ${installed
    //        ? running!
    //        ? LogColor.greened("✓ Running")
    //        : LogColor.cyanid("✓ Installed, not running")
    //        : LogColor.redid("✕ Not found")}
    //Configuration: ${confFileExists ? LogColor.greened("✓ Valid") : LogColor.redid("✕ Not found")}
    //Services: (backup-scheduler) ${schedulerInstalled ? LogColor.greened("✓ Installed") + " (Period: ${LogColor.cyanid("$backupPeriod")})" : LogColor.redid("✕ Not installed")},
    // (start-on-boot) ${bootInstalled ? LogColor.greened("✓ Installed") : LogColor.redid("✕ Not installed")}
    //Tries to connect to: (container) ${LogColor.cyanid(settings.dockerContainerName)}, (port) ${LogColor.cyanid(settings.connectionPort.toString())}, (site) ${LogColor.cyanid(settings.currentSite)}
    //  """);
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
