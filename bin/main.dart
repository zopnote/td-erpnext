import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:td_erpnext/td_erpnext.dart' as td_erpnext;

Future<void> main() async {
  final Response lastResponse = await runWorkflow(
    td_erpnext.ManagerWorkflow.binaries(
      rootDirectoryPath: path.dirname(path.dirname(Platform.script.path)),
      binDirectoryName: "bin",
      confDirectoryName: "conf",
      onStdout: (context, chars) => context.send(Response(String.fromCharCodes(chars))),
      onStderr: (context, chars) => context.send(Response(String.fromCharCodes(chars), Level.error)),
    ),
    (response) {
      if (response.isError) {
        stderr.writeln(response.message);
        return;
      }
      stdout.writeln(response.message);
    },
  );
  await Future.delayed(Duration(milliseconds: 100));
  exitCode = lastResponse.isError ?  1 : 0;
}

