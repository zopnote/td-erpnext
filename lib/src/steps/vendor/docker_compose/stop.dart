import 'dart:io';

import 'package:td_erpnext/src/steps/vendor/docker_compose.dart';
import 'package:td_erpnext/src/utils.dart';

class Stop extends DockerComposeStep {
  final File composeFile;
  final String? projectName;
  const Stop({
    required this.composeFile,
    this.projectName,
    super.callback,
    super.programCallLiteral,
    super.workingDirectory,
  });

  @override
  List<String> format() => List.empty(growable: true)
    ..addAll(["-f", composeFile.path])
    ..addAllNotNull(projectName, (v) => ["-p", v])
    ..add("stop");
}
