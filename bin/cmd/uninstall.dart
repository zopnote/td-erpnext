import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/uninstall.dart';

final NatrixCommand uninstallCommand = NatrixCommand(
  id: "uninstall",
  description: "Removes the installation securely.",
  flags: [
    NatrixBoolFlag(id: "hard", tooltip: "Deletes all backups.", value: false),
  ],
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.syntax.format());
      return;
    }
    await runWorkflow(
      Uninstall(hard: options.getFlag("hard").value),
      (e) => io.newLine(
        text: NatrixText(e.exception.toString(), foreground: .red),
        output: .stderr,
      ),
    );
  },
);
