import 'dart:io';

import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/steps/docker/docker.dart';
import 'package:td_erpnext/src/steps/docker_compose/docker_compose.dart';

class StopSettings with StepWiser<DockerCompose, StopSettings, Stop> {
  final File? composeFile;
  final String? projectName;
  final String? workingDirectory;
  const StopSettings({
    this.composeFile,
    this.projectName,
    this.workingDirectory,
  });

  @override
  Stop create() => Stop();
}

class Stop extends DockerComposeStep<StopSettings> {
  @override
  List<String> format() => List.empty(growable: true)
    ..addAllNotNull(wise.composeFile, (v) => ["-f", v.path])
    ..addAllNotNull(wise.projectName, (v) => ["-p", v])
    ..add("stop");
}
