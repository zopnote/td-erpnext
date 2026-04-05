import 'package:td_erpnext/src/steps/vendor/docker.dart';
import 'package:td_erpnext/src/utils.dart';

final class Lists extends DockerStep {
  final bool all;

  /// Lists containers.
  const Lists({
    super.callback,
    super.workingDirectory,
    super.programCallLiteral,
    this.all = false,
  });
  @override
  List<String> format() => List.empty(growable: true)
    ..add("ps")
    ..addIf(all, "-a");
}
