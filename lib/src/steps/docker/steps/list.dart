import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/docker/docker.dart';
import 'dart:core';

class ListsSettings with StepWiser<Docker, ListsSettings, Lists> {
  final bool all;
  const ListsSettings({this.all = false});
  @override
  Lists create() => Lists();
}

class Lists extends DockerStep<ListsSettings> {
  @override
  List<String> format() => List.empty(growable: true)
    ..add("ps")
    ..addIf(wise.all, "-a");
}
