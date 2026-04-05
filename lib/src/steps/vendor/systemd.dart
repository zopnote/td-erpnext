import 'dart:io';

import 'package:stepflow/core.dart';
import 'package:stepflow/io.dart';

import 'package:td_erpnext/src/settings.dart';

export 'package:td_erpnext/src/steps/vendor/systemd/remove_autostart.dart';
export 'package:td_erpnext/src/steps/vendor/systemd/remove_schedule.dart';
export 'package:td_erpnext/src/steps/vendor/systemd/setup_autostart.dart';
export 'package:td_erpnext/src/steps/vendor/systemd/setup_schedule.dart';
export 'package:td_erpnext/src/steps/vendor/systemd/update_schedule.dart';
export 'package:td_erpnext/src/steps/vendor/systemd/get_schedule.dart';
export 'package:td_erpnext/src/steps/vendor/systemd/schedule_duration.dart';
export 'package:td_erpnext/src/steps/vendor/systemd/service.dart';

abstract class SystemdStep extends ConfigureStep {
  const SystemdStep();
  @override
  Step configure() {
    final ProcessInterfaceOptions options = const ProcessInterfaceOptions(
      runAsAdministrator: true,
    );
    return run(options);
  }

  Step run(ProcessInterfaceOptions options);
}

String _serviceName = Settings.serviceName;
String get serviceName => _serviceName;
void setServiceName(String name) => _serviceName = name;

/// Checks if a recurring (timer) service with the given [serviceName] is installed.
///
/// Returns `true` if the `.timer` file exists in `/etc/systemd/system/`.
bool hasSchedule() {
  return File('/etc/systemd/system/$serviceName-scheduler.timer').existsSync();
}

/// Checks if a boot service with the given [serviceName] is installed.
///
/// Returns `true` if the `.service` file exists in `/etc/systemd/system/`.
bool hasAutostart() {
  return File('/etc/systemd/system/$serviceName.service').existsSync();
}
