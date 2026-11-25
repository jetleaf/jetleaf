/// {@template session_creation_policy}
/// Specifies how Jetleaf Security creates and manages HTTP sessions.
///
/// The policy is consumed when a chain is built: it selects the context
/// repository and the session authentication strategy used by the
/// authentication filter.
///
/// ### Contract and invariants
/// - `stateless` installs a null context repository and a no-op session
///   strategy, so no session is ever created or read.
/// - `never` uses a session-backed repository but forbids session creation.
/// - `always`, `ifRequired` and `never` permit an existing session to be used.
/// - `ifRequired` is the default for stateful applications.
///
/// ### Example
/// ```dart
/// HttpSecurity()
///   ..sessionManagement((session) {
///     session.sessionCreationPolicy(SessionCreationPolicy.stateless);
///   });
/// ```
/// {@endtemplate}
enum SessionCreationPolicy {
  /// Always create an HTTP session if one does not already exist.
  always,

  /// Create an HTTP session only if required (default for stateful apps).
  ifRequired,

  /// Never create an HTTP session, but use one if it already exists.
  never,

  /// Never create or use an HTTP session (recommended for REST / JWT APIs).
  stateless,
}

/// {@template session_management_configurer}
/// Configures session creation policy inside `HttpSecurity`.
///
/// The configurer is created for the duration of a `sessionManagement` callback
/// and its final [policy] value is read when the callback returns.
///
/// ### Example
/// ```dart
/// HttpSecurity()
///   ..sessionManagement((s) => s.sessionCreationPolicy(SessionCreationPolicy.never));
/// ```
/// {@endtemplate}
class SessionManagementConfigurer {
  /// Active session creation policy.
  SessionCreationPolicy policy = SessionCreationPolicy.ifRequired;

  /// Sets the [SessionCreationPolicy] to [policy].
  ///
  /// ### Parameters
  /// - [policy]: The desired session behavior for the chain.
  ///
  /// ### Returns
  /// Nothing; the receiver is mutated in place.
  ///
  /// ### Example
  /// ```dart
  /// configurer.sessionCreationPolicy(SessionCreationPolicy.stateless);
  /// ```
  void sessionCreationPolicy(SessionCreationPolicy policy) {
    this.policy = policy;
  }
}