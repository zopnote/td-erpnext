import 'dart:io';

import 'package:stepflow/core.dart';

final class RecreateDirectory extends ConfigureStep {
  final String path;
  final bool recursive;
  const RecreateDirectory(this.path, {this.recursive = false});
  @override
  Step configure() => Runnable(
    () =>
        (Directory(path).existsSync()
                ? (Directory(path)..deleteSync(recursive: true))
                : Directory(path))
            .createSync(recursive: true),
  );
}
