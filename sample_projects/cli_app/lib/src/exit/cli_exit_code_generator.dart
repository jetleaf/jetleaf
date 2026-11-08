import 'package:jetleaf_core/annotation.dart';
import 'package:jetleaf_core/context.dart';

@Component()
class CliExitCodeGenerator implements ExitCodeGenerator {
  int _code = 0;

  void setExitCode(int code) {
    _code = code;
  }

  @override
  int getExitCode() => _code;

  @override
  String getPackageName() => 'cli_app';
}