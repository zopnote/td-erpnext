import 'package:td_erpnext/src/steps/vendor/docker.dart';
import 'package:td_erpnext/src/utils.dart';

final class Remove extends DockerStep {
  final List<Container> containers;
  final bool force;
  final bool volumes;

  /// Removes one or more containers.
  const Remove({
    super.callback,
    super.workingDirectory,
    super.programCallLiteral,
    required this.containers,
    this.force = false,
    this.volumes = false,
  });
  @override
  List<String> format() => List.empty(growable: true)
    ..add("rm")
    ..addIf(force, "--force")
    ..addIf(volumes, "--volumes")
    ..addAll(containers.map((c) => c.name));
}
