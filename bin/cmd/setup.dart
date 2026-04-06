import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/setup.dart';

final NatrixCommand setupCommand = NatrixCommand(
  id: "setup",
  description: "Installs and starts frappe erpnext.",
  flags: [NatrixTextFlag(id: "tag", value: "")],
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.syntax.format());
      return;
    }
    final String tag = options.getFlag("tag").value;
    await runWorkflow(
      Setup(tag: tag.isEmpty ? null : tag),
      (e) => io.newLine(
        text: NatrixText(e.exception.toString(), foreground: .red),
        output: .stderr,
      ),
    );
  },
);
