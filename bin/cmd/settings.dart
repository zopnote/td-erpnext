import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'settings/list.dart';
import 'settings/set.dart';

final NatrixCommand settingsCommand = NatrixCommand(
  id: "settings",
  description:
      "Adjust the settings. To adjust settings related to backups, use the corresponding command.",
  children: [
    settingsSetCommand,
    settingsListCommand
  ],
  callback: (options) {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    io.writeLines(lines: theme.syntax.format());
  },
);
