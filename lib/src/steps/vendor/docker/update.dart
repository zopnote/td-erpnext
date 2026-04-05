import 'package:td_erpnext/src/steps/vendor/docker.dart';
import 'package:td_erpnext/src/utils.dart';

/// Possible Docker restart policies.
enum RestartPolicy {
  no,
  always,
  unlessStopped,
  onFailure;

  @override
  String toString() {
    switch (this) {
      case RestartPolicy.no:
        return "no";
      case RestartPolicy.always:
        return "always";
      case RestartPolicy.unlessStopped:
        return "unless-stopped";
      case RestartPolicy.onFailure:
        return "on-failure";
    }
  }
}

final class Update extends DockerStep {
  final List<Container> containers;
  final int? blkioWeight;
  final int? cpuPeriod;
  final int? cpuQuota;
  final int? cpuRealtimePeriod;
  final int? cpuRealtimeRuntime;
  final int? cpuShares;
  final double? cpus;
  final String? cpuSetCpus;
  final String? cpuSetMems;
  final String? memory;
  final String? memoryReservation;
  final String? memorySwap;
  final RestartPolicy? restart;

  /// Updates configuration of one or more containers.
  const Update({
    super.callback,
    super.workingDirectory,
    super.programCallLiteral,
    required this.containers,
    this.blkioWeight,
    this.cpuPeriod,
    this.cpuQuota,
    this.cpuRealtimePeriod,
    this.cpuRealtimeRuntime,
    this.cpuShares,
    this.cpus,
    this.cpuSetCpus,
    this.cpuSetMems,
    this.memory,
    this.memoryReservation,
    this.memorySwap,
    this.restart,
  });
  @override
  List<String> format() => List.empty(growable: true)
    ..add("update")
    ..addAllNotNull(blkioWeight, (v) => ["--blkio-weight", v.toString()])
    ..addAllNotNull(cpuPeriod, (v) => ["--cpu-period", v.toString()])
    ..addAllNotNull(cpuQuota, (v) => ["--cpu-quota", v.toString()])
    ..addAllNotNull(cpuRealtimePeriod, (v) => ["--cpu-rt-period", v.toString()])
    ..addAllNotNull(
      cpuRealtimeRuntime,
      (v) => ["--cpu-rt-runtime", v.toString()],
    )
    ..addAllNotNull(cpuShares, (v) => ["--cpu-shares", v.toString()])
    ..addAllNotNull(cpus, (v) => ["--cpus", v.toString()])
    ..addAllNotNull(cpuSetCpus, (v) => ["--cpuset-cpus", v])
    ..addAllNotNull(cpuSetMems, (v) => ["--cpuset-mems", v])
    ..addAllNotNull(memory, (v) => ["--memory", v])
    ..addAllNotNull(memoryReservation, (v) => ["--memory-reservation", v])
    ..addAllNotNull(memorySwap, (v) => ["--memory-swap", v])
    ..addAllNotNull(restart, (v) => ["--restart", v.toString()])
    ..addAll(containers.map((c) => c.name));
}
