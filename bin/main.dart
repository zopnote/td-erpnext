import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/io.dart';

import 'package:td_erpnext/cmd.dart';

Future<void> main(List<String> arguments) async {
  final String? user = Platform.environment['USER'];
  if (user != null && user.isNotEmpty && user != "root") {
    late final int terminalWidth;
    try {
      terminalWidth = stdout.terminalColumns;
    } on StdoutException catch (_) {
      terminalWidth = 60;
    }
    NatrixStdio().writeLines(
      lines: NatrixText(
        "This application needs "
        "root access to execute the desired commands. "
        "Ensure the permissions are provided.",
        foreground: .red,
      ).wrap(terminalWidth),
    );
    exit(1);
  }
  final NatrixPipeline pipeline = NatrixPipeline(
    arguments: arguments,
    globalFlags: globalFlags,
  );
  return pipeline.run(rootCommand);
}
