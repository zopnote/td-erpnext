
import 'dart:io';

import 'package:stepflow/core.dart';

class CreateDirectory extends ConfigureStep {
  final String path;
  final bool recursive;
  final bool deleteIfExists;
  const CreateDirectory(
      this.path, {
        this.recursive = false,
        this.deleteIfExists = false,
      });
  @override
  Step configure() => Runnable((context) async {
    final bool exists = await Directory(path).exists();
    if (exists) {
      if (!deleteIfExists) {
        return;
      }
      await Directory(path).delete(recursive: true);
    }
    await Directory(path).create(recursive: recursive);
  });
}
