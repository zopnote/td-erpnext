import 'dart:io';

import 'package:path/path.dart' as path;

import 'lib/build_project_workflow.dart';

Future<void> main() async {
  print("Remove output directory...");
  await Directory(path.join((await projectRoot).path, "out")).delete(recursive: true);
}