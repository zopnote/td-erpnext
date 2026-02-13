import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'lib/build_project_workflow.dart';

Future<void> main() async => await runWorkflow(
  BuildWorkflow(
    projectRoot: await projectRoot,
    confDirectoryName: "conf",
    outDirectoryName: "out",
    readme: io.File(path.join((await projectRoot).path, "readme.md")),
    pubspec: io.File(path.join((await projectRoot).path, "pubspec.yaml")),
    buildFinishCallback: (executableFile) async {
      print("Execute project binary...\n---------------");
      final ProcessInterface process = await ProcessInterface.fromFilepath(
        executableFile.path,
        ["test"],
        onStdout: (chars) => io.stdout.add(chars),
        onStderr: (chars) => io.stderr.add(chars),
      );
      print(
        (await process.waitForExit()) == 0
            ? "---------------\nExecuted successfully."
            : "---------------\nAn error occurred.",
      );
    },
  ),
  (response) {
    if (response.isError) {
      io.stderr.writeln(response.message);
      return;
    }
    io.stdout.writeln(response.message);
  },
);
