import 'dart:io' as io;

import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';
import 'lib/build_project_workflow.dart';

Future<void> main() async => await runWorkflow(
  BuildWorkflow(
    projectRoot: await projectRoot,
    outDirectoryName: "out",
    readme: io.File(path.join((await projectRoot).path, "readme.md")),
    pubspec: io.File(path.join((await projectRoot).path, "pubspec.yaml")),
  ), (response) {
    if (response.isError) {
      io.stderr.writeln(response.message);
      return;
    }
    io.stdout.writeln(response.message);
  },
);
