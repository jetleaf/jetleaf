/// {@template observable_event}
/// A base class representing an event in an observable system.
///
/// Classes that extend [ObsEvent] define specific types of
/// events that can be emitted, observed, or dispatched in reactive
/// or event-driven architectures.
///
/// This is an abstract class and cannot be instantiated directly.
/// Subclasses should provide additional context or payload relevant
/// to the event.
///
/// Example:
/// ```dart
/// class UserLoggedInEvent extends ObservableEvent {
///   final String userId;
///
///   const UserLoggedInEvent(this.userId);
/// }
///
/// // Usage
/// final event = UserLoggedInEvent("12345");
/// ```
/// 
/// {@endtemplate}
abstract class ObsEvent {
  /// Creates a new [ObsEvent].
  ///
  /// This is a `const` constructor so that subclasses can also
  /// define constant event instances if needed.
  /// 
  /// {@macro observable_event}
  const ObsEvent();
}