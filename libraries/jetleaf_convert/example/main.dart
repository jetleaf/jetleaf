import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';

/// Small application entry used to verify `@JetleafEntry` VM execution.
@JetleafEntry()
void main(List<String> args) {
  final source = args.isEmpty ? '42' : args.first;
  final service = DefaultConversionService();
  final converted = service.convert<int>(source, Class<int>());

  print('Converted "$source" to int: $converted');
}
