import 'package:jetleaf_core/lang.dart' show IllegalArgumentException;
import '../core/authentication.dart';
import '../core/exceptions.dart';
import 'authentication_event_publisher.dart';
import 'authentication_manager.dart';
import 'authentication_provider.dart';

/// {@template provider_manager}
/// An [AuthenticationManager] that consults an ordered list of
/// [AuthenticationProvider]s and optionally delegates to a [parent] manager.
///
/// For each provider, the manager asks [AuthenticationProvider.supports]
/// and skips those that decline. A provider may return `null` to pass the token
/// to the next candidate. Recoverable [AuthenticationException]s are remembered
/// so the most informative failure can be reported if every candidate declines,
/// while [AccountStatusException]s are propagated immediately because they
/// describe the account rather than the credential mechanism.
///
/// ### Contract and invariants
/// - At least one provider or a [parent] must be supplied; the constructor
///   throws [ArgumentError] otherwise.
/// - The provider list is copied into an unmodifiable list at construction.
/// - A successfully returned token has its credentials erased when
///   [eraseCredentialsAfterAuthentication] is `true` (the default).
/// - A success or failure event is published through [eventPublisher]; publisher
///   errors are swallowed so observability cannot alter the outcome.
/// - The manager is safe to share across concurrent requests.
///
/// ### Example
/// ```dart
/// final manager = ProviderManager([
///   DaoAuthenticationProvider(
///     userDetailsService: userDetailsService,
///     passwordEncoder: passwordEncoder,
///   ),
/// ]);
///
/// final trusted = await manager.authenticate(unauthenticatedToken);
/// ```
/// {@endtemplate}
class ProviderManager implements AuthenticationManager {
  /// The ordered list of authentication providers to consult.
  final List<AuthenticationProvider> providers;

  /// Optional parent manager consulted if no local provider handles the token.
  final AuthenticationManager? parent;

  /// Whether to erase credentials on the returned [Authentication] object.
  final bool eraseCredentialsAfterAuthentication;

  /// Publisher notified of successful and failed authentication attempts.
  final AuthenticationEventPublisher eventPublisher;

  /// {@macro provider_manager}
  ProviderManager(
    List<AuthenticationProvider> providers, {
    this.parent,
    this.eraseCredentialsAfterAuthentication = true,
    AuthenticationEventPublisher? eventPublisher,
  })  : providers = List.unmodifiable(providers),
        eventPublisher = eventPublisher ?? const NoOpAuthenticationEventPublisher() {
          if (this.providers.isEmpty && parent == null) {
            throw IllegalArgumentException('At least one AuthenticationProvider or parent must be provided.');
          }
        }

  /// Authenticates [authentication] by trying each supporting provider in turn.
  ///
  /// Providers that return `null` allow the search to continue. If none
  /// succeeds and a [parent] is configured, the parent is asked next. On
  /// success the result is sanitised and a success event is published; on
  /// failure the last recorded exception is published and rethrown.
  ///
  /// ### Parameters
  /// - [authentication] — the untrusted token to verify.
  ///
  /// ### Returns
  /// A future completing with the trusted [Authentication] produced by the
  /// first successful provider or by the parent.
  ///
  /// ### Throws
  /// [AccountStatusException] immediately when a provider reports an unusable
  /// account; otherwise the most recent [AuthenticationException], or a fresh
  /// one when no provider supported the token.
  ///
  /// ### Example
  /// ```dart
  /// try {
  ///   final result = await manager.authenticate(attempt);
  ///   print('authenticated: ${result.name}');
  /// } on AuthenticationException catch (e) {
  ///   print('rejected: ${e.message}');
  /// }
  /// ```
  @override
  Future<Authentication> authenticate(Authentication authentication) async {
    AuthenticationException? lastException;
    Authentication? result;

    for (final provider in providers) {
      if (!provider.supports(authentication)) {
        continue;
      }
      try {
        result = await provider.authenticate(authentication);
        if (result != null) {
          break;
        }
      } on AccountStatusException catch (e) {
        lastException = e;
        _publishFailure(authentication, e);
        rethrow;
      } on AuthenticationException catch (e) {
        lastException = e;
      }
    }

    if (result == null && parent != null) {
      try {
        result = await parent!.authenticate(authentication);
      } on AuthenticationException catch (e) {
        lastException = e;
      }
    }

    if (result != null) {
      if (eraseCredentialsAfterAuthentication) {
        result.eraseCredentials();
      }
      _publishSuccess(result);
      return result;
    }

    final failure = lastException ??
        AuthenticationException(
          'No AuthenticationProvider found for ${authentication.runtimeType}',
        );
    _publishFailure(authentication, failure);
    throw failure;
  }

  /// {@template provider_manager._publish_success}
  /// Notifies the configured publisher that [authentication] succeeded.
  ///
  /// Exceptions thrown by the publisher are deliberately discarded: event
  /// delivery is an observability concern and must not turn a successful
  /// authentication into a failure.
  ///
  /// ### Parameters
  /// - [authentication] — the trusted result to report.
  /// {@endtemplate}
  void _publishSuccess(Authentication authentication) {
    try {
      eventPublisher.publishAuthenticationSuccess(authentication);
    } catch (_) {
      // Observability must never change the authentication outcome.
    }
  }

  /// {@template provider_manager._publish_failure}
  /// Notifies the configured publisher that [authentication] failed.
  ///
  /// Exceptions thrown by the publisher are deliberately discarded so the
  /// original [exception] remains the one reported to the caller.
  ///
  /// ### Parameters
  /// - [authentication] — the token that failed authentication.
  /// - [exception] — the [AuthenticationException] describing the failure.
  /// {@endtemplate}
  void _publishFailure(
    Authentication authentication,
    AuthenticationException exception,
  ) {
    try {
      eventPublisher.publishAuthenticationFailure(authentication, exception);
    } catch (_) {
      // Observability must never change the authentication outcome.
    }
  }
}
