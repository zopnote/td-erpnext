import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/steps/start.dart';

final NatrixCommand startCommand = NatrixCommand(
  id: "start",
  description: "Start the ERPNext-instance.",
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.syntax.format());
      return;
    }
    await runWorkflow(
      const Start(),
      (e) => io.pipe(
        text: NatrixText(e.exception.toString(), foreground: .red),
        output: .stderr,
      ),
    );
  },
);
