import 'package:stepflow/core.dart';
import 'package:td_erpnext/src/steps/docker/docker.dart';


class UpdateSettings with StepWiser<Docker, UpdateSettings, Update> {
  final List<DockerContainer> containers;
  final DockerUpdateConfig config;
  const UpdateSettings({
    required this.containers,
    this.config = const DockerUpdateConfig(),
  });
  @override
  Update create() => Update();
}

class Update extends DockerStep<UpdateSettings> {
  @override
  List<String> format() => List.empty(growable: true)
    ..add("update")
    ..addAllNotNull(
      wise.config.blkioWeight,
      (v) => ["--blkio-weight", v.toString()],
    )
    ..addAllNotNull(
      wise.config.cpuPeriod,
      (v) => ["--cpu-period", v.toString()],
    )
    ..addAllNotNull(wise.config.cpuQuota, (v) => ["--cpu-quota", v.toString()])
    ..addAllNotNull(
      wise.config.cpuRealtimePeriod,
      (v) => ["--cpu-rt-period", v.toString()],
    )
    ..addAllNotNull(
      wise.config.cpuRealtimeRuntime,
      (v) => ["--cpu-rt-runtime", v.toString()],
    )
    ..addAllNotNull(
      wise.config.cpuShares,
      (v) => ["--cpu-shares", v.toString()],
    )
    ..addAllNotNull(wise.config.cpus, (v) => ["--cpus", v.toString()])
    ..addAllNotNull(wise.config.cpuSetCpus, (v) => ["--cpuset-cpus", v])
    ..addAllNotNull(wise.config.cpuSetMems, (v) => ["--cpuset-mems", v])
    ..addAllNotNull(wise.config.memory, (v) => ["--memory", v])
    ..addAllNotNull(
      wise.config.memoryReservation,
      (v) => ["--memory-reservation", v],
    )
    ..addAllNotNull(wise.config.memorySwap, (v) => ["--memory-swap", v])
    ..addAllNotNull(wise.config.restart, (v) => ["--restart", v.toString()])
    ..addAll(wise.containers.map((c) => c.name));
}
