import 'dart:io';

import 'package:td_erpnext/src/steps/vendor/docker_compose.dart';
import 'package:td_erpnext/src/utils.dart';

class Init extends DockerComposeStep {
  final File composeFile;
  final String? projectName;
  final bool detach;
  final bool build;
  const Init({
    required this.composeFile,
    this.projectName,
    this.detach = false,
    this.build = false,
    super.callback,
    super.programCallLiteral,
    super.workingDirectory,
  });

  @override
  List<String> format() => List.empty(growable: true)
    ..addAll(["-f", composeFile.path])
    ..addAllNotNull(projectName, (v) => ["-p", v])
    ..add("up")
    ..addIf(detach, "-d")
    ..addIf(build, "--build");
}
