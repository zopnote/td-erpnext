import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

/// Please have in mind, that these Settings are not valid anymore after dumping new settings to disk.
final Settings settingsAtProgramStart = Settings.load();

class Json {
  final String name;
  const Json(this.name);
}

class Settings {


  /// Sets the port this manager tries to connect to of the
  /// frontend of the running erpnext in the docker container.
  @Json('connect_port')
  final int connectionPort;

  /// Sets the current site this manager tries to connect to
  /// of the frontend of the running erpnext in the docker container.
  @Json('connect_site_name')
  final String currentSite;

  /// Sets the docker container name this manager tries to connect
  /// to of the frontend of the running erpnext in the docker container.
  @Json('connect_docker_container')
  final String dockerContainerName;

  /// Location relative to the apps root where the data files and
  /// directories of the working process are stored.
  @Json('app_directory')
  final String appDirectoryName;

  /// The backup source directory is the location where backups
  /// will be retrieved from. The entire path is in the corresponding
  /// docker container.
  @Json('log_directory')
  final String logDirectoryName;

  /// The backup directory is the location where backups will be stored.
  /// The entire path is in the corresponding docker container.
  @Json('backup_src')
  late final String backupSourcePath;

  /// Location relative to the apps root where the log
  /// files of the working process are stored.
  @Json('backup_dist')
  final String backupDestinationPath;

  /// The root password of the database of the erpnext installation.
  @Json('db_root_password')
  final String dbRootPassword;

  //__________________________________________________________________________________________________________
  // v HARD CODED PARAMETER

  /// Name of the systemd services installed by this application.
  static const String serviceName = "td_erpnext";

  /// Location relative to the apps binary root where the configuration file gets stored.
  static const String settingsFileName = "conf.json";

  /// Location of the configuration file, where the essential settings get stored for persistence.
  static String get configurationFilePath =>
      path.join(rootDirectoryPath, settingsFileName);

  /// The location where the erpnext, the docker image and process files are located.
  String get appDirectoryPath => path.join(rootDirectoryPath, appDirectoryName);

  /// The location where the binaries are located.
  static String get binDirectoryPath => path.dirname(Platform.script.path);

  /// The app bundles root directory.
  static String get rootDirectoryPath => path.dirname(binDirectoryPath);

  /// The name of the binary directory inside the app bundles root.
  static String get binDirectoryName => path.basename(binDirectoryPath);

  // ^ HARD CODED PARAMETER
  //__________________________________________________________________________________________________________
  Settings({
    this.connectionPort = 8080,
    this.currentSite = "frontend",
    this.dockerContainerName = "frappe_docker_frontend_1",
    this.appDirectoryName = "erpnext",
    final String backupSourcePath = "/home/frappe/frappe-bench/sites/<erpnext_site_name>/private/backups",
    this.logDirectoryName = "logs",
    this.backupDestinationPath = "/var/backups/erpnext",
    this.dbRootPassword = "admin",
  }) {
    this.backupSourcePath = backupSourcePath.replaceAll("<erpnext_site_name>", currentSite);
  }


  static Settings load() {
    try {
      final File file = File(configurationFilePath);
      if (!file.existsSync()) return Settings();

      final Uint8List bytes = file.readAsBytesSync();
      final Map<String, dynamic> document = jsonDecode(
        String.fromCharCodes(bytes),
      );
      final def = Settings();

      return Settings(
        connectionPort:
            document[json(#connectionPort)] as int? ??
            def.connectionPort,
        currentSite:
            document[json(#currentSite)] as String? ??
            def.currentSite,
        dockerContainerName:
            document[json(#dockerContainerName)] as String? ??
            def.dockerContainerName,
        appDirectoryName:
            document[json(#appDirectoryName)] as String? ??
            def.appDirectoryName,
        logDirectoryName:
            document[json(#logDirectoryName)] as String? ??
            def.logDirectoryName,
        backupSourcePath:
            document[json(#backupSourcePath)] as String? ??
            def.backupSourcePath,
        backupDestinationPath:
            document[json(#backupDestinationPath)] as String? ??
            def.backupDestinationPath,
        dbRootPassword:
            document[json(#dbRootPassword)] as String? ?? def.dbRootPassword,
      );
    } catch (e) {
      print("[Settings.load] Error loading configuration: $e");
      return Settings();
    }
  }
  late final Map<String, dynamic> document = {
    json(#connectionPort): connectionPort,
    json(#currentSite): currentSite,
    json(#dockerContainerName): dockerContainerName,
    json(#appDirectoryName): appDirectoryName,
    json(#logDirectoryName): logDirectoryName,
    json(#backupSourcePath): backupSourcePath,
    json(#backupDestinationPath): backupDestinationPath,
    json(#dbRootPassword): dbRootPassword,
  };

  /// Saves the current settings to the configuration file.
  void dump() {
    try {
      final File file = File(configurationFilePath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }

      final String content = JsonEncoder.withIndent('  ').convert(document);
      file.writeAsStringSync(content);
    } catch (e) {
      print("[Settings.save] Error saving configuration: $e");
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Settings &&
          runtimeType == other.runtimeType &&
          connectionPort == other.connectionPort &&
          currentSite == other.currentSite &&
          dockerContainerName == other.dockerContainerName &&
          appDirectoryName == other.appDirectoryName &&
          logDirectoryName == other.logDirectoryName &&
          backupSourcePath == other.backupSourcePath &&
          backupDestinationPath == other.backupDestinationPath;

  @override
  int get hashCode =>
      connectionPort.hashCode ^
      currentSite.hashCode ^
      dockerContainerName.hashCode ^
      appDirectoryName.hashCode ^
      logDirectoryName.hashCode ^
      backupSourcePath.hashCode ^
      backupDestinationPath.hashCode;

  /// Returns the json field name of a field in the [Settings] class.
  static String json(Symbol fieldSymbol) {
    const mapping = {
      #connectionPort: 'connect_port',
      #currentSite: 'connect_site_name',
      #dockerContainerName: 'connect_docker_container',
      #appDirectoryName: 'app_directory',
      #logDirectoryName: 'log_directory',
      #backupSourcePath: 'backup_src',
      #backupDestinationPath: 'backup_dist',
      #dbRootPassword: 'db_root_password',
    };

    if (mapping.containsKey(fieldSymbol)) {
      return mapping[fieldSymbol]!;
    }

    // Fallback if a symbol is not in the mapping.
    // We extract the name from the symbol representation Symbol("name") -> name
    String symbolString = fieldSymbol.toString();
    // Symbol("name") or Symbol('name')
    if (symbolString.startsWith('Symbol("') || symbolString.startsWith("Symbol('")) {
      return symbolString.substring(8, symbolString.length - 2);
    }
    return symbolString;
  }
}
