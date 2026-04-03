import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/docker/docker.dart';


class CopySettings with StepWiser<Docker, CopySettings, Copy> {
  final DockerLocation source;
  final DockerLocation destination;
  const CopySettings({required this.source, required this.destination});
  @override
  Copy create() => Copy();
}

class Copy extends DockerStep<CopySettings> {
  @override
  List<String> format() => [
    "cp",
    wise.source.toString(),
    wise.destination.toString(),
  ];
}
