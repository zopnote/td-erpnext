import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

final class Settings {
  /// Sets the port this manager tries to connect to of the
  /// frontend of the running erpnext in the docker container.
  final Setting<int> port;

  /// Sets the current site this manager tries to connect to
  /// of the frontend of the running erpnext in the docker container.
  final Setting<String> frontendSite;

  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  final Setting<String> frontendContainer;

  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  final Setting<String> backendContainer;

  /// Location relative to the apps root where the log
  /// files of the working process are stored.
  final Setting<String> backupStoragePath;

  /// The root password of the database of the erpnext installation.
  final Setting<String> databasePassword;

  /// Name of the systemd services installed by this application.
  static String get serviceName => "td_erpnext";

  /// Location relative to the apps binary root where the configuration file gets stored.
  static String get settingsFileName => "conf.json";

  /// Location of the configuration file, where the essential settings get stored for persistence.
  static String get configurationFilePath =>
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
    required String? frontendSite,
    required int? port,
    required String? frontendContainer,
    required String? backendContainer,
    required String? backupStoragePath,
    required String? databasePassword,
  }) {
    return Settings._internal(
      port: IntSetting(
        key: "port",
        value: port ?? 8080,
        description:
            "The port this manager tries to connect "
            "to of the frontend of the running erpnext"
            "in the docker container.",
      ),
      frontendSite: StringSetting(
        key: "site",
        value: frontendSite ?? "frontend",
        description:
            "Sets the current site this manager tries "
            "to connect to of the frontend of the running "
            "erpnext in the docker container.",
      ),
      frontendContainer: StringSetting(
        key: "frontend_container",
        value: frontendContainer ?? "frappe_docker_frontend_1",
        description:
            "The docker container id this manager tries "
            "to connect to of the frontend of the running "
            "erpnext in the docker container.",
      ),
      backendContainer: StringSetting(
        key: "backend_container",
        value: backendContainer ?? "frappe_docker_backend_1",
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
      databasePassword: StringSetting(
        key: "password",
        value: databasePassword ?? "admin",
        description:
            "The root password of the database of the erpnext installation.",
      ),
    );
  }

  Settings._internal({
    required this.port,
    required this.frontendSite,
    required this.frontendContainer,
    required this.backendContainer,
    required this.backupStoragePath,
    required this.databasePassword,
  });

  factory Settings.new() => Settings._build(
    frontendSite: null,
    port: null,
    frontendContainer: null,
    backendContainer: null,
    backupStoragePath: null,
    databasePassword: null,
  );

  static Settings fromDisk() {
    final Settings s = Settings();
    try {
      final File file = File(configurationFilePath);
      if (!file.existsSync()) return s;

      final Uint8List bytes = file.readAsBytesSync();
      final Map<String, dynamic> doc = jsonDecode(String.fromCharCodes(bytes));
      return Settings._build(
        frontendSite: doc[s.frontendSite.key],
        port: doc[s.port.key],
        frontendContainer: doc[s.frontendContainer.key],
        backendContainer: doc[s.backendContainer.key],
        backupStoragePath: doc[s.backupStoragePath.key],
        databasePassword: doc[s.databasePassword.key],
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
