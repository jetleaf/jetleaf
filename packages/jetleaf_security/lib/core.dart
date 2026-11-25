/// 🛡️ **Jetleaf Security Core Subsystem**
///
/// This library defines the domain model shared by every security mechanism in
/// Jetleaf: principals and their authorities, the context that carries the
/// current identity, and the repository strategies that persist it between
/// requests.
///
/// - **Authentication & Authorities:** token contracts and trust classification.
/// - **Context Propagation:** zone-scoped storage for the active identity.
/// - **Repositories:** deferred, session-backed, and stateless persistence.
/// - **User Details:** provider contracts and ready-to-use implementations.
/// - **Failures:** a typed hierarchy of security and authentication exceptions.
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🔐 Identity & Trust
/// - [Authentication] — the token contract for a request or authenticated principal.
/// - [GrantedAuthority], [SimpleGrantedAuthority] — individual permissions held by a principal.
/// - [AuthenticationTrustResolver], [AuthenticationTrustResolverImpl] — classify anonymous, remembered, and fully authenticated tokens.
///
/// ### 🧭 Context & Propagation
/// - [SecurityContext] — mutable holder for the current authentication.
/// - [SecurityContextHolder] — binds a context to an asynchronous zone.
/// - [DeferredSecurityContext] — lazy loader that resolves a context at most once.
///
/// ### 💾 Persistence Strategies
/// - [SecurityContextRepository] — strategy for loading and saving a context.
/// - [HttpSessionSecurityContextRepository] — session-backed storage with configurable session creation.
/// - [NullSecurityContextRepository] — stateless storage for token-based authentication.
///
/// ### 👤 User Information
/// - [UserDetails], [SecurityUser] — account information and account-state flags.
/// - [UserDetailsService], [InMemoryUserDetailsManager] — provider contract and in-memory implementation.
///
/// ### ⚠️ Security Failures
/// - [SecurityException], [AuthenticationException], [AccountStatusException], [AccessDeniedException] — base failure categories.
/// - [BadCredentialsException], [UsernameNotFoundException], [DisabledException], [LockedException] — specific authentication failures.
/// - [AccountExpiredException], [CredentialsExpiredException], [InsufficientAuthenticationException], [InvalidCsrfTokenException] — additional denial reasons.
///
/// ---
///
/// ## 🎯 Usage Example
///
/// ```dart
/// import 'package:jetleaf_security/core.dart';
///
/// Future<void> handle(ServerHttpRequest request) async {
///   final repository = HttpSessionSecurityContextRepository();
///   final context = await repository.loadDeferredContext(request).get();
///
///   await SecurityContextHolder.runWithContext(() async {
///     SecurityContextHolder.setContext(context);
///     final authentication = SecurityContextHolder.getContext().authentication;
///     if (authentication == null || !authentication.isAuthenticated) {
///       throw InsufficientAuthenticationException();
///     }
///     print('Welcome, ${authentication.name}');
///   });
/// }
/// ```
library;

export 'src/core/authentication.dart';
export 'src/core/authentication_trust_resolver.dart';
export 'src/core/exceptions.dart';
export 'src/core/granted_authority.dart';
export 'src/core/http_session_security_context_repository.dart';
export 'src/core/in_memory_user_details_manager.dart';
export 'src/core/null_security_context_repository.dart';
export 'src/core/security_context.dart';
export 'src/core/security_context_holder.dart';
export 'src/core/security_context_repository.dart';
export 'src/core/simple_granted_authority.dart';
export 'src/core/user_details.dart';
export 'src/core/user_details_service.dart';
export 'src/core/typedefs.dart';