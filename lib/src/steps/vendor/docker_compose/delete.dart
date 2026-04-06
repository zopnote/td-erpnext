import 'dart:io';

import 'package:td_erpnext/src/steps/vendor/docker_compose.dart';
import 'package:td_erpnext/src/utils.dart';

class Delete extends DockerComposeStep {
  final File? composeFile;
  final String? projectName;
  final bool removeVolumes;
  final bool removeImages;
  const Delete({
    required this.composeFile,
    this.projectName,
    this.removeVolumes = false,
    this.removeImages = false,
    super.callback,
    super.programCallLiteral,
    super.workingDirectory,
  });

  @override
  List<String> format() => List.empty(growable: true)
    ..addAllNotNull(composeFile, (v) => ["-f", "${v.path}"])
    ..add("down")
    ..addIf(removeVolumes, "-v")
    ..addAllIf(removeImages, [
      ["--rmi", "all"],
    ]);
}
