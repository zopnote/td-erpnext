import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'cmd.dart';

export 'src/cmd/backups.dart';
export 'src/cmd/fix.dart';
export 'src/cmd/settings.dart';
export 'src/cmd/setup.dart';
export 'src/cmd/start.dart';
export 'src/cmd/status.dart';
export 'src/cmd/stop.dart';
export 'src/cmd/uninstall.dart';

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
  flags: [
    NatrixTextFlag(id: "asd")
  ],
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
