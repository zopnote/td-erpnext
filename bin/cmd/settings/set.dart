import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:stepflow/platform.dart';
import 'package:td_erpnext/src/settings.dart';
import 'package:td_erpnext/src/settings_list_section.dart';

final NatrixCommand settingsSetCommand = NatrixCommand(
  id: "set",
  argumentTip: "setting> <value",
  description: "Sets the specified setting to a value.",
  callback: (options) {
    final NatrixSection syntax = NatrixStructure(sections: [
      settingsListSection,
      NatrixDefaultTheme.of(options.getContext()).usage,
      NatrixLine(text: NatrixText("Please specify a setting and a corresponding value."))
    ]);
    final NatrixStdio io = NatrixStdio();
    if (options.args.isEmpty) {
      io.writeLines(lines: syntax.format());
      return;
    }
    final Setting? setting = settings.firstWhereOrNull((e) => e.key == options.args.first);
    if (setting == null) {
      io.newLine(text: NatrixText("There isn't a setting with the name \"${options.args.first}\"."));
      return;
    }
    if (options.args.length < 2) {
      io.writeLines(lines: syntax.format());
      return;
    }
    setting.value = setting.parse(options.args[1]);
    io.writeLines(lines: syntax.format());
  },
);
