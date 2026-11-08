// ---------------------------------------------------------------------------
// 🍃 Jetleaf Framework - Ultimate Test Suite
// Event Service Handling Core Application Events and Custom Events
// ---------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';
import 'custom_event.dart';

@Component('eventService')
class EventService {
  final List<String> receivedEvents = [];
  bool onStartingFired = false;
  bool onStartedFired = false;
  bool onReadyFired = false;
  bool onRefreshedFired = false;

  EventService();

  @OnApplicationStarting()
  void onStarting() {
    onStartingFired = true;
  }

  @OnApplicationStarted()
  void onStarted() {
    onStartedFired = true;
  }

  @OnApplicationReady()
  void onReady() {
    onReadyFired = true;
  }

  @OnContextPrepared()
  void onPrepared() {
    onRefreshedFired = true;
  }

  @EventListener()
  void handleCustomNotification(CustomNotificationEvent event) {
    receivedEvents.add(event.message);
  }
}