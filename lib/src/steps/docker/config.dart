import 'package:td_erpnext/src/steps/docker/volume.dart';

import 'container.dart';

/// Settings for the `docker run` command.
class DockerRunConfig {
  final bool remove;
  final String? name;
  final List<DockerContainer> volumesFrom;
  final List<DockerVolume> volumes;
  final Map<String, String> env;

  const DockerRunConfig({
    this.remove = false,
    this.name,
    this.volumesFrom = const [],
    this.volumes = const [],
    this.env = const {},
  });
}

/// Settings for the `docker exec` command.
class DockerExecConfig {
  final bool interactive;
  final bool tty;
  final String? user;
  final String? workingDirectory;
  final Map<String, String> env;

  const DockerExecConfig({
    this.interactive = false,
    this.tty = false,
    this.user,
    this.workingDirectory,
    this.env = const {},
  });
}

/// Settings for the `docker update` command.
class DockerUpdateConfig {
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
  final DockerRestartPolicy? restart;

  const DockerUpdateConfig({
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
}

/// Possible Docker restart policies.
enum DockerRestartPolicy {
  no,
  always,
  unlessStopped,
  onFailure;

  @override
  String toString() {
    switch (this) {
      case DockerRestartPolicy.no:
        return "no";
      case DockerRestartPolicy.always:
        return "always";
      case DockerRestartPolicy.unlessStopped:
        return "unless-stopped";
      case DockerRestartPolicy.onFailure:
        return "on-failure";
    }
  }
}