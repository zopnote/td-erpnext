import 'dart:io';

import 'package:path/path.dart' as path;

import 'build.dart';

Future<void> main() async {
  print("Remove output directory...");
  await Directory(
    path.join((await getProjectRoot()).path, "out"),
  ).delete(recursive: true);
}
