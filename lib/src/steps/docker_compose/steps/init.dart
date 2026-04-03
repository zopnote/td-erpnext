import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/steps/docker/docker.dart';
import 'package:td_erpnext/src/steps/docker_compose/docker_compose.dart';

class InitSettings with StepWiser<DockerCompose, InitSettings, Init> {
  final File? composeFile;
  final String? projectName;
  final bool detach;
  final bool build;
  final String? workingDirectory;
  const InitSettings({
    this.composeFile,
    this.projectName,
    this.detach = false,
    this.build = false,
    this.workingDirectory,
  });

  @override
  Init create() => Init();
}

class Init extends DockerComposeStep<InitSettings> {
  @override
  List<String> format() => List.empty(growable: true)
    ..addAllNotNull(wise.composeFile, (v) => ["-f", v.path])
    ..addAllNotNull(wise.projectName, (v) => ["-p", v])
    ..add("up")
    ..addIf(wise.detach, "-d")
    ..addIf(wise.build, "--build");
}
