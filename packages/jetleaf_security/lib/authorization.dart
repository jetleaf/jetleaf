/// 🛡️ **Jetleaf Security — Authorization & Method Security**
///
/// This library brings together the authorization decision engine, the
/// security expression language, request-level rules and method-level guards.
/// Every rule is expressed as an [AuthorizationManager] that turns a lazy
/// authentication supplier and a context into an [AuthorizationDecision], so
/// request checks and method checks share one policy model.
///
/// ---
///
/// ## 🧭 Decision Flow
///
/// ```text
/// ┌──────────────────────────────────────────────────────────────────┐
/// │  Request or method invocation                                    │
/// │          │                                                       │
/// │  Metadata source / matcher selects the applicable rules          │
/// │          │                                                       │
/// │  AuthorizationManager.check(authentication, context)             │
/// │          │                                                       │
/// │  AuthorizationDecision.granted → continue                        │
/// │  AuthorizationDecision.denied  → AccessDeniedException           │
/// └──────────────────────────────────────────────────────────────────┘
/// ```
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### ⚖️ Core decision contract
/// - [AuthorizationManager] — typed contract for authorization decisions.
/// - [AuthorizationDecision] — immutable granted/denied result.
/// - [RequestAuthorizationContext] — request context passed to managers.
///
/// ### 🔀 Composition and terminals
/// - [AuthorizationManagers] — `anyOf` / `allOf` combinators for managers.
/// - [PermitAllAuthorizationManager] — always grants.
/// - [DenyAllAuthorizationManager] — always denies.
///
/// ### 👤 Principal-based managers
/// - [AuthenticatedAuthorizationManager] — requires a signed-in principal.
/// - [AuthorityAuthorizationManager] — checks one authority or role.
/// - [ExpressionAuthorizationManager] — evaluates an expression string.
/// - [RoleHierarchy] — expands roles into the authorities they imply.
///
/// ### 🌐 Request authorization
/// - [RequestMatcherDelegatingAuthorizationManager] — first matching rule wins.
/// - [RequestAuthorizationEntry] — a matcher paired with its manager.
/// - [AuthenticationEntryPoint] — starts an authentication scheme on 401.
/// - [BearerAuthenticationEntryPoint] — bearer-token entry point.
/// - [AccessDeniedHandler] — handles authenticated-but-forbidden failures.
/// - [JsonAccessDeniedHandler] — JSON 403 response handler.
///
/// ### 🧮 Expression language
/// - [SecurityExpressionParser] — tokenizes and evaluates expressions.
/// - [SecurityExpressionContext] — authentication, arguments, and return value.
/// - [SecurityExpressionHandler] — injectable expression entry point.
/// - [SecurityExpressionPropertyResolver] — custom dotted-path resolution.
/// - [SecurityExpressionPropertyResolvers] — resolver registry.
///
/// ### 🧩 Method security
/// - [MethodAuthorizationContext] — arguments and return value for method rules.
/// - [PreAuthorizeAuthorizationManager] — evaluates `@PreAuthorize`.
/// - [PostAuthorizeAuthorizationManager] — evaluates `@PostAuthorize`.
/// - [SecuredAuthorizationManager] — enforces `@Secured` authorities.
/// - [Jsr250AuthorizationManager] — enforces `@RolesAllowed` roles.
/// - [MethodSecurityMetadataSource] — discovers method security attributes.
/// - [PrePostAnnotationSecurityMetadataSource] — reflection-backed source.
/// - [AuthorizationManagerBeforeMethodInterceptor] — pre-invocation guard.
/// - [AuthorizationManagerAfterMethodInterceptor] — post-invocation guard.
/// - [MethodSecurityInterceptor] — manual invocation facade.
/// - [bindMethodArguments] — binds parameter names for expression variables.
///
/// ---
///
/// ## 🎯 Usage Example
///
/// ```dart
/// import 'package:jetleaf_security/annotation.dart';
/// import 'package:jetleaf_security/authorization.dart';
/// import 'package:jetleaf_web/jetleaf_web.dart';
///
/// @RestController()
/// class ReportController {
///   @GetMapping(path: '/api/reports/{owner}')
///   @PreAuthorize("hasRole('ADMIN') or #owner == authentication.name")
///   Future<Map<String, Object?>> reports(String owner) async {
///     return {'owner': owner, 'count': 3};
///   }
///
///   @GetMapping(path: '/api/reports/{owner}/audit')
///   @PostAuthorize('returnObject.owner == authentication.name')
///   Future<Map<String, Object?>> audit(String owner) async {
///     return {'owner': owner};
///   }
/// }
///
/// void main() {
///   // Programmatic checks use the same decision contract.
///   final rule = AuthorityAuthorizationManager.hasRole('ADMIN');
///   final decision = rule.check(() => currentAuthentication, context);
///   print(decision.isGranted);
/// }
/// ```
library;

export 'src/authorization/access_denied_handler.dart';
export 'src/authorization/authenticated_authorization_manager.dart';
export 'src/authorization/authentication_entry_point.dart';
export 'src/authorization/authority_authorization_manager.dart';
export 'src/authorization/authorization_decision.dart';
export 'src/authorization/authorization_manager.dart';
export 'src/authorization/authorization_managers.dart';
export 'src/authorization/expression/property_resolver.dart';
export 'src/authorization/expression/security_expression_handler.dart';
export 'src/authorization/expression_authorization_manager.dart';
export 'src/authorization/expression_parser.dart';
export 'src/authorization/method/enablement_aware_method_security_metadata_source.dart';
export 'src/authorization/method/method_authorization.dart';
export 'src/authorization/method/method_security_interceptors.dart';
export 'src/authorization/method/method_security_metadata_source.dart';
export 'src/authorization/method_security_interceptor.dart';
export 'src/authorization/request_matcher_delegating_authorization_manager.dart';
export 'src/authorization/role_hierarchy.dart';
export 'src/authorization/typedefs.dart';