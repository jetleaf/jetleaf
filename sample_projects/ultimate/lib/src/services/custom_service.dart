// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Custom Service demonstrating User-Defined Extended Annotations
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';
import '../annotations/custom_annotations.dart';

@CustomService('customService')
class CustomServiceImplementation {
  bool postConstructInvoked = false;
  bool customOnReadyInvoked = false;
  bool preDestroyInvoked = false;

  CustomServiceImplementation();

  @PostConstruct()
  void initialize() {
    postConstructInvoked = true;
  }

  @CustomOnReady()
  Future<void> onAppReady() async {
    customOnReadyInvoked = true;
  }

  @PreDestroy()
  void cleanup() {
    preDestroyInvoked = true;
  }

  @Audited('PROCESS_DATA')
  String processData(String input) {
    return 'Audited: $input';
  }
}
