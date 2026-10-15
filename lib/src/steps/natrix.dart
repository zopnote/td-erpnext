import 'package:natrix/io.dart';
import 'package:stepflow/core.dart';

final class PrintNatrixLine extends ConfigureStep {
  final NatrixText? text;
  const PrintNatrixLine({this.text});
  @override
  Step configure() =>
      Runnable(() => NatrixStdio().pipe(text: text ?? NatrixText.empty()));
}

final class RenewNatrixLine extends ConfigureStep {
  final NatrixText? text;
  final NatrixMount mount;
  const RenewNatrixLine({required this.mount, this.text});
  @override
  Step configure() => Runnable(
    () => NatrixStdio().setLine(mount: mount, text: text ?? NatrixText.empty()),
  );
}
