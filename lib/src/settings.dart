import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

final class Settings {
  /// Sets the port this manager tries to connect to of the
  /// frontend of the running erpnext in the docker container.
  final Setting<int> connectionPort;

  /// Sets the current site this manager tries to connect to
  /// of the frontend of the running erpnext in the docker container.
  final Setting<String> currentSite;

  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  final Setting<String> dockerContainerName;

  /// Location relative to the apps root where the data files and
  /// directories of the working process are stored.
  final Setting<String> appDirectoryName;

  /// The backup source directory is the location where backups
  /// will be retrieved from. The entire path is in the corresponding
  /// docker container.
  final Setting<String> logDirectoryName;

  /// The backup directory is the location where backups will be stored.
  /// The entire path is in the corresponding docker container.
  final DependingSetting backupSourcePath;

  /// Location relative to the apps root where the log
  /// files of the working process are stored.
  final Setting<String> backupDestinationPath;

  /// The root password of the database of the erpnext installation.
  final Setting<String> dbRootPassword;

  /// The location where the erpnext, the docker image and process files are located.
  String get appDirectoryPath =>
      path.join(rootDirectoryPath, appDirectoryName.value);

  //__________________________________________________________________________________________________________
  // v HARD CODED PARAMETER

  /// Name of the systemd services installed by this application.
  static String get serviceName => "td_erpnext";

  /// Location relative to the apps binary root where the configuration file gets stored.
  static String get settingsFileName => "conf.json";

  /// Location of the configuration file, where the essential settings get stored for persistence.
  static String get configurationFilePath =>
      path.join(rootDirectoryPath, settingsFileName);

  /// The location where the binaries are located.
  static String get binDirectoryPath => path.dirname(Platform.script.path);

  /// The app bundles root directory.
  static String get rootDirectoryPath => path.dirname(binDirectoryPath);

  /// The name of the binary directory inside the app bundles root.
  static String get binDirectoryName => path.basename(binDirectoryPath);

  // ^ HARD CODED PARAMETER
  //__________________________________________________________________________________________________________

  factory Settings.new({
    required String? currentSite,
    required int? connectionPort,
    required String? dockerContainerName,
    required String? appDirectoryName,
    required String? logDirectoryName,
    required String? backupSourcePath,
    required String? backupDestinationPath,
    required String? dbRootPassword,
  }) {
    final Setting<String> _currentSite = Setting(
      key: "current_site",
      value: currentSite ?? "frontend",
      description:
          "Sets the current site this manager tries "
          "to connect to of the frontend of the running "
          "erpnext in the docker container.",
    );
    return Settings._internal(
      connectionPort: Setting(
        key: "connect_port",
        value: connectionPort ?? 8080,
        description:
            "Sets the port this manager tries to connect "
            "to of the frontend of the running erpnext"
            "in the docker container.",
      ),
      currentSite: _currentSite,
      dockerContainerName: Setting(
        key: "docker_container",
        value: dockerContainerName ?? "frappe_docker_frontend_1",
        description:
            "Sets the docker container id this manager tries "
            "to connect to of the frontend of the running "
            "erpnext in the docker container.",
      ),
      appDirectoryName: Setting(
        key: "app_directory",
        value: appDirectoryName ?? "erpnext",
        description:
            "Location relative to the apps root where the data "
            "files and directories of the working process are stored.",
      ),
      logDirectoryName: Setting(
        key: "log_directory",
        value: logDirectoryName ?? "logs",
        description:
            "Location relative to the apps root where the log "
            "files of the working process are stored.",
      ),
      backupSourcePath: DependingSetting(
        key: "backup_src",
        value:
            backupSourcePath ??
            "/home/frappe/frappe-bench/sites/<erpnext_site_name>/private/backups",
        dependency: () => _currentSite.value,
        placeholder: "<erpnext_site_name>",
        description:
            "Sets the backup source directory where backups "
            "will be retrieved from. The entire path is in the corresponding "
            "docker container.",
      ),
      backupDestinationPath: Setting(
        key: "backup_dist",
        value: backupDestinationPath ?? "/var/backups/erpnext",
        description:
            "Sets the backup directory where backups get stored. "
            "Path in the filesystem.",
      ),
      dbRootPassword: Setting(
        key: "db_password",
        value: dbRootPassword ?? "admin",
        description:
            "The root password of the database of the erpnext installation.",
      ),
    );
  }

  Settings._internal({
    required this.connectionPort,
    required this.currentSite,
    required this.dockerContainerName,
    required this.appDirectoryName,
    required this.logDirectoryName,
    required this.backupSourcePath,
    required this.backupDestinationPath,
    required this.dbRootPassword,
  });

  factory Settings.base() => Settings(
    currentSite: null,
    connectionPort: null,
    dockerContainerName: null,
    appDirectoryName: null,
    logDirectoryName: null,
    backupSourcePath: null,
    backupDestinationPath: null,
    dbRootPassword: null,
  );

  static Settings load() {
    final Settings s = Settings.base();
    try {
      final File file = File(configurationFilePath);
      if (!file.existsSync()) return s;

      final Uint8List bytes = file.readAsBytesSync();
      final Map<String, dynamic> doc = jsonDecode(String.fromCharCodes(bytes));
      return Settings(
        currentSite: doc[s.currentSite.key],
        connectionPort: doc[s.connectionPort.key],
        dockerContainerName: doc[s.dockerContainerName.key],
        appDirectoryName: doc[s.appDirectoryName.key],
        logDirectoryName: doc[s.logDirectoryName.key],
        backupSourcePath: doc[s.backupSourcePath.key],
        backupDestinationPath: doc[s.backupDestinationPath.key],
        dbRootPassword: doc[s.dbRootPassword.key],
      );
    } catch (e) {
      print("[Settings.load] Error loading configuration: $e");
      return s;
    }
  }

  /// Saves the current settings to the configuration file.
  void dump() {
    try {
      final File file = File(configurationFilePath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }

      final String content = JsonEncoder.withIndent(
        '  ',
      ).convert(Map.fromEntries(_mapping.map((e) => MapEntry(e.key, e.value))));
      file.writeAsStringSync(content);
    } catch (e) {
      print("[Settings.save] Error saving configuration: $e");
    }
  }
}

class DependingSetting extends Setting<String> {
  final String placeholder;
  final String Function() dependency;
  DependingSetting({
    required super.key,
    required super.value,
    required this.dependency,
    required this.placeholder,
    required super.description,
  }) : super();
  String get value => super.value.replaceAll(placeholder, dependency());
}

class Setting<T> {
  final String key;
  final String description;
  T value;
  Setting({required this.key, required this.value, required this.description}) {
    if (key.isEmpty) {
      return;
    }
    _mapping.removeWhere((e) => e.key == key);
    _mapping.add(this);
  }
}

final List<Setting> _mapping = [];
