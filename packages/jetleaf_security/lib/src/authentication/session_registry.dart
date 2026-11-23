import 'package:jetleaf_core/lang.dart' show EqualsAndHashCode;

/// {@template session_information}
/// A record describing one session belonging to a principal.
///
/// SessionInformation holds the identifier, owner, last-request timestamp, and
/// expiry state needed for session tracking and concurrency control.
///
/// ### Contract and invariants
/// - [sessionId] and [principal] are fixed at construction.
/// - [lastRequest] starts at the current UTC time and is updated by [touch].
/// - Expiry is one-way: once [expire] is called, [isExpired] remains `true`.
///
/// ### Example
/// ```dart
/// final info = SessionInformation('abc123', 'alice');
/// info.touch();
/// print(info.isExpired); // false
/// info.expire();
/// print(info.isExpired); // true
/// ```
///
/// ### See also
/// - [SessionRegistry]
/// {@endtemplate}
final class SessionInformation with EqualsAndHashCode {
  /// Session id.
  final String sessionId;

  /// Principal the session belongs to.
  final Object principal;

  /// Time of the most recent request using this session.
  DateTime lastRequest;

  /// {@template session_information._expired}
  /// Backing flag for [isExpired].
  ///
  /// It is initialised to `false` and can only ever transition to `true`.
  /// {@endtemplate}
  bool _expired = false;

  /// {@macro session_information}
  SessionInformation(this.sessionId, this.principal)
    : lastRequest = DateTime.now().toUtc();

  /// Whether this session has been explicitly expired.
  bool get isExpired => _expired;

  /// Marks the session as expired.
  ///
  /// This operation is irreversible for the instance.
  void expire() => _expired = true;

  /// Refreshes the last-request timestamp to the current UTC time.
  void touch() => lastRequest = DateTime.now().toUtc();

  @override
  String toString() => 'SessionInformation(sessionId: $sessionId, expired: $_expired)';

  /// Contributes the stable session identity to equality and hashing.
  ///
  /// The mutable [lastRequest] timestamp is excluded.
  ///
  /// ### Returns
  /// The ordered list of properties used by [EqualsAndHashCode].
  @override
  List<Object?> equalizedProperties() => [runtimeType, sessionId, principal, isExpired];
}

/// {@template session_registry}
/// An in-memory registry that tracks sessions by principal.
///
/// The registry is the hook through which concurrency control, maximum-session
/// limits, and forced logout can be added without changing the public
/// authentication API. It stores [SessionInformation] records keyed by session
/// identifier and supports lookup by identifier or by owner.
///
/// ### Contract and invariants
/// - Registering the same session id again replaces its previous record.
/// - Lookup by an unknown session id returns `null`.
/// - [getAllSessions] excludes expired records unless explicitly requested.
/// - Instances are mutable and intended to be shared by the components that
///   create and destroy sessions; callers coordinating across isolates must
///   provide their own synchronisation.
///
/// ### Example
/// ```dart
/// final registry = SessionRegistry();
/// registry.registerNewSession('abc123', 'alice');
///
/// final sessions = registry.getAllSessions('alice');
/// print(sessions.single.sessionId); // abc123
/// ```
///
/// ### See also
/// - [SessionInformation]
/// {@endtemplate}
final class SessionRegistry {
  /// {@template session_registry._sessions}
  /// Session records keyed by session identifier.
  /// {@endtemplate}
  final Map<String, SessionInformation> _sessions = {};

  /// Registers a newly created session for [principal].
  ///
  /// If a session with the same [sessionId] already exists, its record is
  /// replaced with a fresh, unexpired one.
  ///
  /// ### Parameters
  /// - [sessionId] — the identifier of the new session.
  /// - [principal] — the identity the session belongs to.
  ///
  /// ### Returns
  /// The newly created [SessionInformation] record.
  SessionInformation registerNewSession(String sessionId, Object principal) {
    final information = SessionInformation(sessionId, principal);
    _sessions[sessionId] = information;
    return information;
  }

  /// Returns the information recorded for [sessionId], if it is tracked.
  ///
  /// ### Parameters
  /// - [sessionId] — the identifier to look up.
  ///
  /// ### Returns
  /// The matching [SessionInformation], or `null` when the session is unknown
  /// or has been removed.
  SessionInformation? getSessionInformation(String sessionId) => _sessions[sessionId];

  /// Stops tracking [sessionId].
  ///
  /// ### Parameters
  /// - [sessionId] — the identifier to forget. Unknown identifiers are ignored.
  void removeSessionInformation(String sessionId) => _sessions.remove(sessionId);

  /// Returns all sessions belonging to [principal].
  ///
  /// ### Parameters
  /// - [principal] — the identity whose sessions should be collected.
  /// - [includeExpired] — whether expired records should be included; defaults
  ///   to `false`.
  ///
  /// ### Returns
  /// A new list of matching [SessionInformation] records.
  List<SessionInformation> getAllSessions(Object principal, {
    bool includeExpired = false,
  }) => _sessions.values
      .where((info) => info.principal == principal && (includeExpired || !info.isExpired))
      .toList();
}
