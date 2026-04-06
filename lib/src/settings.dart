import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

final class Settings {
  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  final Setting<String> sitesVolume;

  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  final Setting<String> databaseVolume;


  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  final Setting<String> redisCacheVolume;

  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  final Setting<String> redisQueueVolume;

  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  final Setting<String> frontendContainer;

  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  final Setting<String> backendContainer;

  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  final Setting<String> websocketContainer;

  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  final Setting<String> schedulerContainer;

  /// Location relative to the apps root where the log
  /// files of the working process are stored.
  final Setting<String> backupStoragePath;

  /// Name of the systemd services installed by this application.
  static String get serviceName => "td_erpnext";

  /// Location relative to the apps binary root where the configuration file gets stored.
  static String get settingsFileName => "settings.json";

  /// Location of the configuration file, where the essential settings get stored for persistence.
  static String get settingsFilePath =>
      path.join(rootDirectoryPath, settingsFileName);

  /// Location relative to the apps root where the log files are stored.
  static String get logDirectoryName => "log";

  /// Location relative to the apps root where the data files and
  /// directories of the working process are stored.
  static String get appDirectoryName => "app";

  static String get repositoryName => "frappe_docker";

  /// The location where the erpnext, the docker image and process files are located.
  static String get appDirectoryPath =>
      path.join(rootDirectoryPath, appDirectoryName);

  /// The location where the binaries are located.
  static String get binDirectoryPath => path.dirname(Platform.script.path);

  /// The app bundles root directory.
  static String get rootDirectoryPath => path.dirname(binDirectoryPath);

  /// The name of the binary directory inside the app bundles root.
  static String get binDirectoryName => path.basename(binDirectoryPath);

  static String get repositoryPath =>
      path.join(appDirectoryPath, repositoryName);
  static String get composeFilePath => path.join(repositoryPath, "pwd.yml");

  factory Settings._build({
    required String? sitesVolume,
    required String? databaseVolume,
    required String? backupStoragePath,
  }) {
    return Settings._internal(
      backendContainer: StringSetting(
        key: "backend_container",
        value: "frappe_docker_backend_1",
        description:
            "The docker container id this manager tries "
            "to connect to of the backend of the running "
            "erpnext in the docker container.",
      ),
      frontendContainer: StringSetting(
        key: "frontend_container",
        value: "frappe_docker_frontend_1",
        description:
            "The docker container id this manager tries "
            "to connect to of the frontend of the running "
            "erpnext in the docker container.",
      ),
      schedulerContainer: StringSetting(
        key: "scheduler_container",
        value: "frappe_docker_scheduler_1",
        description:
            "The docker container id this manager tries "
            "to connect to of the backend of the running "
            "erpnext in the docker container.",
      ),
      websocketContainer: StringSetting(
        key: "websocket_container",
        value: "frappe_docker_websocket_1",
        description:
            "The docker container id this manager tries "
            "to connect to of the frontend of the running "
            "erpnext in the docker container.",
      ),
      redisCacheVolume: StringSetting(
        key: "redis_cache_volume",
        value: "frappe_docker_redis-cache",
        description:
            "The docker container id this manager tries "
            "to connect to of the backend of the running "
            "erpnext in the docker container.",
      ),
      redisQueueVolume: StringSetting(
        key: "redis_queue_volume",
        value: "frappe_docker_redis-queue-data",
        description:
            "The docker container id this manager tries "
            "to connect to of the frontend of the running "
            "erpnext in the docker container.",
      ),
      sitesVolume: StringSetting(
        key: "sites_volume",
        value: sitesVolume ?? "frappe_docker_sites",
        description:
            "The docker container id this manager tries "
            "to connect to of the frontend of the running "
            "erpnext in the docker container.",
      ),
      databaseVolume: StringSetting(
        key: "database_volume",
        value: databaseVolume ?? "frappe_docker_db-data",
        description:
            "The docker container id this manager tries "
            "to connect to of the backend of the running "
            "erpnext in the docker container.",
      ),

      backupStoragePath: StringSetting(
        key: "backup_storage",
        value: backupStoragePath ?? "/var/backups/erpnext",
        description:
            "The backup directory where backups get stored. "
            "Path in the filesystem.",
      ),
    );
  }

  Settings._internal({
    required this.sitesVolume,
    required this.databaseVolume,
    required this.backupStoragePath,
    required this.frontendContainer,
    required this.backendContainer,
    required this.redisCacheVolume,
    required this.redisQueueVolume, required this.websocketContainer, required this.schedulerContainer,
  });

  factory Settings.new() => Settings._build(
    sitesVolume: null,
    databaseVolume: null,
    backupStoragePath: null,
  );

  static Settings fromDisk() {
    final Settings s = Settings();
    try {
      final File file = File(settingsFilePath);
      if (!file.existsSync()) return s;

      final Uint8List bytes = file.readAsBytesSync();
      final Map<String, dynamic> doc = jsonDecode(String.fromCharCodes(bytes));
      return Settings._build(
        sitesVolume: doc[s.sitesVolume.key],
        databaseVolume: doc[s.databaseVolume.key],
        backupStoragePath: doc[s.backupStoragePath.key],
      );
    } catch (e) {
      print("[Settings.load] Error loading configuration: $e");
      return s;
    }
  }

  /// Saves the current settings to the configuration file.
  void dump() {
    try {
      final File file = File(settingsFilePath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }

      final String content = JsonEncoder.withIndent(
        '  ',
      ).convert(Map.fromEntries(settings.map((e) => MapEntry(e.key, e.value))));
      file.writeAsStringSync(content);
    } catch (e) {
      print("[Settings.save] Error saving configuration: $e");
    }
  }
}

class DependingSetting extends StringSetting {
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

class IntSetting extends Setting<int> {
  IntSetting({
    required super.key,
    required super.value,
    required super.description,
  });

  @override
  int parse(String raw) => int.parse(raw);
}

class StringSetting extends Setting<String> {
  StringSetting({
    required super.key,
    required super.value,
    required super.description,
  });

  @override
  String parse(String raw) => raw;
}

abstract class Setting<T> {
  final String key;
  final String description;
  T _value;
  T get value => _value;
  set value(T value) => _value = value;
  T parse(String raw);

  Setting({required this.key, required T value, required this.description})
    : _value = value {
    if (key.isEmpty) {
      return;
    }
    settings.removeWhere((e) => e.key == key);
    settings.add(this);
  }
}

final List<Setting> settings = [];
