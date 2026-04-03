import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/docker/docker.dart';

class ImagesSettings with StepWiser<Docker, ImagesSettings, Images> {
  final bool all;
  const ImagesSettings({this.all = false});
  @override
  Images create() => Images();
}

class Images extends DockerStep<ImagesSettings> {
  @override
  List<String> format() => List.empty(growable: true)
    ..add("images")
    ..addIf(wise.all, "-a");
}
