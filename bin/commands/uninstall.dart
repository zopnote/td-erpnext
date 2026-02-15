
import 'package:stepflow/io.dart';
import 'package:td_erpnext/src/settings.dart';
Future<Response> uninstallCommand(CommandInformation info) async {
  if (info.getFlag("help").value) {
    return Response(info.command.formatSyntax(spacer: 13), Level.normal);
  }
  final Settings settings = Settings.load();

  return Response();
}
