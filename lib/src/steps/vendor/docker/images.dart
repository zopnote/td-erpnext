import 'package:td_erpnext/src/steps/vendor/docker.dart';
import 'package:td_erpnext/src/utils.dart';

final class Images extends DockerStep {
  final bool all;

  /// Lists images.
  const Images({
    super.callback,
    super.workingDirectory,
    super.programCallLiteral,
    this.all = false,
  });
  @override
  List<String> format() => List.empty(growable: true)
    ..add("images")
    ..addIf(all, "-a");
}
