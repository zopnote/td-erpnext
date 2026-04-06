import 'dart:io';

import 'package:natrix/core.dart';
import 'package:natrix/theme.dart';
import 'package:td_erpnext/src/settings.dart';

NatrixSection get settingsListSection {
  late final int terminalWidth;
  try {
    terminalWidth = stdout.terminalColumns;
  } catch (_) {
    terminalWidth = 65;
  }
  Settings.fromDisk();
  final List<NatrixColumn> columns = [];
  final _s = List.of(settings);
  _s.sort((a, b) => b.key.length.compareTo(a.key.length));
  settings.forEach((e) {
    String name = e.key;
    name += " " * (_s.first.key.length + 2 - name.length);
    final List<NatrixText> tooltip = NatrixText(
      e.description,
    ).wrap(terminalWidth - _s.first.key.length - 2);

    bool first = true;
    final List<NatrixText> lines = [];
    int i = 0;
    while (i < tooltip.length) {
      if (first) {
        lines.add(
          NatrixText(name) +
              NatrixText(
                "(value: ${e.value.toString()})",
                foreground: .grayAccent,
              ),
        );
        first = false;
        continue;
      }
      lines.add(NatrixText(" " * (name.length) + tooltip[i].text));
      i++;
    }
    columns.add(NatrixColumn(lines: lines));
  });

  return NatrixDocument(
    header: NatrixColumn(
      lines: NatrixText(
        "Current settings:",
        style: .bold,
      ).wrap(terminalWidth),
    ),
    content: NatrixStructure(sections: columns),
    footer: NatrixBlock.empty(),
  );
}
