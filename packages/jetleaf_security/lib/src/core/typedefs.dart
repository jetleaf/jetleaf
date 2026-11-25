import 'authentication.dart';
import 'security_context.dart';

/// {@template authentication_supplier}
/// Supplies the [Authentication] bound to the current execution context.
///
/// Authorization managers receive a supplier rather than a value so the
/// security context is read lazily. A rule that grants access without
/// inspecting the principal never touches the context at all.
///
/// A `null` result means the request is unauthenticated.
///
/// ### Example
/// ```dart
/// AuthenticationSupplier current = () => SecurityContextHolder.getContext().authentication;
/// final authentication = current();
/// ```
/// {@endtemplate}
typedef AuthenticationSupplier = Authentication? Function();

/// {@template security_context_loader}
/// Lazily produces a [SecurityContext] for the current request.
///
/// Returning `null` asks the caller to use a fresh empty context. The loader is
/// invoked at most once per request by [DeferredSecurityContext].
/// {@endtemplate}
typedef SecurityContextLoader = Future<SecurityContext?> Function();