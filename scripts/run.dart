import 'dart:io' as io;

import 'package:stepflow/io.dart';
import 'build.dart';

Future<void> main(List<String> arguments) async {
  io.stdout.writeln(arguments);
  await Build(
    projectRoot: await getProjectRoot(),
    outDirectoryName: "out",
    buildFinishCallback: (executableFile) async {
      await ProcessInterface.fromFilepath(
        executableFile.path,
        arguments,
        onStdout: (chars) => io.stdout.add(chars),
        onStderr: (chars) => io.stderr.add(chars),
      );
    },
  )();
}
