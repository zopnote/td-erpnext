import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/docker/docker.dart';


class StartSettings with StepWiser<Docker, StartSettings, Start> {
  final List<DockerContainer> containers;
  const StartSettings({required this.containers});
  @override
  Start create() => Start();
}

class Start extends DockerStep<StartSettings> {
  @override
  List<String> format() => ["start", ...wise.containers.map((c) => c.name)];
}
