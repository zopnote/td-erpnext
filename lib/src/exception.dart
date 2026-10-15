import 'package:td_erpnext/src/settings.dart';

class InstallationNotFoundException implements Exception {
  @override
  String toString() =>
      "Couldn't find an installation at \"${Settings.repositoryPath}\".";
}

class AlreadyInstalledException implements Exception {
  @override
  String toString() =>
      "There is already an installation at \"${Settings.repositoryPath}\".";
}

class AlreadyRunningException implements Exception {
  const AlreadyRunningException();

  @override
  String toString() =>
      "The containers associated with the compose file are "
          "already running.";
}

class NotRunningException implements Exception {
  const NotRunningException();

  @override
  String toString() =>
      "The containers associated with the compose file aren't running.";
}

class UnavailableDependenciesException implements Exception {
  const UnavailableDependenciesException(this.dependencies);
  final List<String> dependencies;

  @override
  String toString() =>
      "The following dependencies aren't satisfied: ${dependencies.join(", ")}. ";

  @override
  bool operator ==(Object other) {
    if (other is! UnavailableDependenciesException) {
      return false;
    }
    return other.dependencies == dependencies;
  }
}
