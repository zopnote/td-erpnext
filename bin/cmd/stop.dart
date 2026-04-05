import 'package:natrix/core.dart';
import 'package:natrix/io.dart';
import 'package:natrix/theme.dart';

import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/steps/stop.dart';

final NatrixCommand stopCommand = NatrixCommand(
  id: "stop",
  description: "Stops the running ERPNext-instance.",
  callback: (options) async {
    final NatrixStdio io = NatrixStdio();
    final NatrixTheme theme = NatrixDefaultTheme.of(options.getContext());
    if (options.getFlag("help").value) {
      io.writeLines(lines: theme.root.format());
      return;
    }
    await runWorkflow(
      const Stop(),
      (e) => io.newLine(
        text: NatrixText(e.exception.toString(), foreground: .red),
        output: .stderr,
      ),
    );
  },
);
