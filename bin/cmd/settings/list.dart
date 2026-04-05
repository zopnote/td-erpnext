import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:td_erpnext/src/settings_list_section.dart';

final NatrixCommand settingsListCommand = NatrixCommand(
  id: "list",
  description: "Lists all available settings and their current values.",
  callback: (options) {
    final NatrixStdio io = NatrixStdio();
    io.writeLines(lines: settingsListSection.format());
  },
);
