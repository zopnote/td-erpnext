import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/docker/docker.dart';


class StopSettings with StepWiser<Docker, StopSettings, Stop> {
  final List<DockerContainer> containers;
  final int? timeout;
  const StopSettings({required this.containers, this.timeout});
  @override
  Stop create() => Stop();
}

class Stop extends DockerStep<StopSettings> {

  @override
  List<String> format() => List.empty(growable: true)
    ..add("stop")
    ..addAllNotNull(wise.timeout, (v) => ["--time", v.toString()])
    ..addAll(wise.containers.map((c) => c.name));
}
