import 'package:test/test.dart';

import 'annotation_test.dart' as annotation_test;
import 'exception_test.dart' as exception_test;
import 'impl_test.dart' as impl_test;

void main() {
  group('Annotation Tests', annotation_test.main);
  group('Exception Tests', exception_test.main);
  group('Implementation Tests', impl_test.main);
}
