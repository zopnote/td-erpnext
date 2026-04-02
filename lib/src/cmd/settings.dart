import 'dart:convert';
import 'dart:io';

import 'package:natrix/core.dart';
import 'package:stepflow/io.dart';
import 'package:stepflow/src/io/steps/log_print.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/flags.dart';
import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

final NatrixCommand settingsCommand = NatrixCommand(
  id: "settings",
  description:
      "Adjust the settings. To adjust settings related to backups, use the corresponding command.",
  callback: (NatrixCallbackOptions options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    io.writeLines(lines: theme.root.format());
  },
);
