import 'dart:io' as io;

import 'package:path/path.dart' as path;

Future<io.Directory> getProjectRoot() async {
  io.Directory projectRoot = io.Directory.current;
  const int maxSearch = 3;
  int searched = 0;
  bool isRoot = false;
  while (!isRoot) {
    await for (io.FileSystemEntity entity in projectRoot.list()) {
      if (entity is io.Directory) {
        if (path.basename(entity.path) == ".git") {
          isRoot = true;
          break;
        }
      }
    }
    if (isRoot) break;
    projectRoot = io.Directory(path.dirname(projectRoot.path));
    if (!projectRoot.existsSync() || searched >= maxSearch) {
      throw Exception(
        "Can't find a root of a repository superordinary to the file.",
      );
    }
    searched++;
  }
  return projectRoot;
}