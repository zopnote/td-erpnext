import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/steps/docker/docker.dart';
import 'package:td_erpnext/src/steps/docker_compose/docker_compose.dart';

class ShutdownSettings
    with StepWiser<DockerCompose, ShutdownSettings, Shutdown> {
  final File? composeFile;
  final String? projectName;
  final bool removeVolumes;
  final bool removeImages;
  const ShutdownSettings({
    required this.composeFile,
    this.projectName,
    this.removeVolumes = false,
    this.removeImages = false,
  });

  @override
  Shutdown create() => Shutdown();
}

class Shutdown extends DockerComposeStep<ShutdownSettings> {

  @override
  List<String> format() => List.empty(growable: true)
    ..addAllNotNull(wise.composeFile, (v) => ["-f", path.basename(v.path)])
    ..add("down")
    ..addIf(wise.removeVolumes, "-v")
    ..addAllIf(wise.removeImages, [
      ["--rmi", "all"],
    ]);
}
