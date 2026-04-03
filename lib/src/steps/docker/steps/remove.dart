import 'package:stepflow/core.dart';

import 'package:td_erpnext/src/steps/docker/docker.dart';

class RemoveSettings with StepWiser<Docker, RemoveSettings, Remove> {
  final List<DockerContainer> containers;
  final bool force;
  final bool volumes;
  const RemoveSettings({
    required this.containers,
    this.force = false,
    this.volumes = false,
  });
  @override
  Remove create() => Remove();
}

class Remove extends DockerStep<RemoveSettings> {
  @override
  List<String> format() => List.empty(growable: true)
    ..add("rm")
    ..addIf(wise.force, "--force")
    ..addIf(wise.volumes, "--volumes")
    ..addAll(wise.containers.map((c) => c.name));
}
