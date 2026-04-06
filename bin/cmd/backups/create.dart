import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';
import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/store.dart';

final NatrixCommand backupsCreateCommand = NatrixCommand(
  id: "create",
  description: "Creates a backup.",
  inheritFlags: false,
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.syntax.format());
      return;
    }
    await runWorkflow(
      const CreateBackup(),
      (e) => io.newLine(
        text: NatrixText(e.exception.toString(), foreground: .red),
        output: .stderr,
      ),
    );
  },
);
