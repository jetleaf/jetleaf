// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Custom Application Event
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';

final class CustomNotificationEvent extends ApplicationEvent {
  final String message;
  final DateTime timestamp;

  CustomNotificationEvent(this.message, [Object? source])
      : timestamp = DateTime.now(),
        super(source ?? Object());

  @override
  String getPackageName() => 'ultimate';
}
