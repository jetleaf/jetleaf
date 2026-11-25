/// 🏷️ **Jetleaf Security Annotations Subsystem**
///
/// This library provides the declarative metadata used to switch security
/// infrastructure on and to guard individual methods. Annotations keep routing
/// and authorization policy next to the code they protect.
///
/// - **Enablement:** opt a configuration class into web and method security.
/// - **Expression Guards:** evaluate conditions before or after invocation.
/// - **Authority Guards:** require named authorities or roles.
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### ⚙️ Enablement
/// - [EnableWebSecurity] — installs the web security filter chain and configuration.
/// - [EnableMethodSecurity] — activates method-level authorization processing.
///
/// ### 🧪 Expression-Based Guards
/// - [PreAuthorize] — evaluates an expression before the method runs.
/// - [PostAuthorize] — evaluates an expression after the method returns.
///
/// ### 🔑 Authority & Role Guards
/// - [Secured] — requires at least one listed authority.
/// - [RolesAllowed] — requires at least one listed role, normalized with a `ROLE_` prefix.
///
/// ---
///
/// ## 🎯 Usage Example
///
/// ```dart
/// import 'package:jetleaf_security/annotation.dart';
///
/// @EnableWebSecurity()
/// @EnableMethodSecurity(securedEnabled: true)
/// class SecurityConfiguration {
///   // Security Pods and policy configuration live here.
/// }
///
/// class AccountService {
///   @PreAuthorize("hasRole('ADMIN') or #username == authentication.name")
///   void updateProfile(String username) {
///     // ...
///   }
///
///   @RolesAllowed(['AUDITOR'])
///   Report readAuditReport() => Report();
/// }
/// ```
library;

export 'src/annotation/security_annotations.dart';
export 'src/annotation/enable_web_security.dart';