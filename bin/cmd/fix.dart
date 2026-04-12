import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/fix.dart';

final NatrixCommand fixCommand = NatrixCommand(
  id: "fix",
  description: "Apply some fixes to encounter issues.",
  inheritFlags: true,
  flags: [
    NatrixBoolFlag(
      id: "hard",
      tooltip: "Resets all configuration.",
      value: false,
    ),
  ],
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.syntax.format());
      return;
    }
    await runWorkflow(
      Fix(hard: options.getFlag("hard").value),
      (e) => io.pipe(
        text: NatrixText(e.exception.toString(), foreground: .red),
        output: .stderr,
      ),
    );
  },
);
