import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/steps/docker/docker.dart';

class RunSettings with StepWiser<Docker, RunSettings, Run> {
  final DockerImage image;
  final String program;
  final List<String>? args;
  final DockerRunConfig config;
  const RunSettings({
    required this.image,
    required this.program,
    this.args,
    this.config = const DockerRunConfig(),
  });
  @override
  Run create() => Run();
}

class Run extends DockerStep<RunSettings> {
  @override
  List<String> format() => List.empty(growable: true)
    ..add("run")
    ..addIf(wise.config.remove, "--rm")
    ..addAllNotNull(wise.config.name, (v) => ["--name", v])
    ..addAllIf(
      wise.config.volumesFrom.isNotEmpty,
      wise.config.volumesFrom.map((e) => ["--volumes-from", e.name]),
    )
    ..addAllIf(
      wise.config.volumes.isNotEmpty,
      wise.config.volumes.map((e) => ["-v", e.toString()]),
    )
    ..addAllIf(
      wise.config.env.entries.isNotEmpty,
      wise.config.env.entries.map((e) => ["-e", "${e.key}=${e.value}"]),
    )
    ..add(wise.image.toString())
    ..addAll([wise.program] + (wise.args ?? []));
}
