import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'cmd/backups.dart';
import 'cmd/fix.dart';
import 'cmd/settings.dart';
import 'cmd/setup.dart';
import 'cmd/start.dart';
import 'cmd/status.dart';
import 'cmd/stop.dart';
import 'cmd/uninstall.dart';

final List<NatrixFlag> globalFlags = [
  NatrixBoolFlag(
    id: "help",
    acronym: NatrixChar('h'),
    value: false,
    tooltip: "Displays usage information.",
  ),
];

final NatrixCommand rootCommand = NatrixCommand(
  id: "td-erpnext",
  description:
      "Tool for automize backups and the "
      "management of the erpnext service under linux.",
  hidden: true,
  inheritFlags: false,
  children: [
    fixCommand,
    startCommand,
    stopCommand,
    statusCommand,
    uninstallCommand,
    setupCommand,
    settingsCommand,
    backupsCommand,
  ],
  callback: (options) {
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    NatrixStdio().writeLines(lines: theme.root.format());
  },
);
