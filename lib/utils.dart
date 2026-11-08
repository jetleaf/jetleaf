/// 🛠️ **Jetleaf Utilities & Helper Subsystem**
///
/// This library provides the reusable algorithmic primitives, assertion helpers,
/// string formatters, collection utilities, and hashing contracts used across the Jetleaf framework:
/// - **String Manipulation:** [StringUtils] (camelCase, kebab-case, snake_case, uncapitalize, cleanPath).
/// - **Equality & Hashing:** [EqualsAndHashCode], [ObjectUtils].
/// - **Defensive Checks:** [Assert], preconditions, and parameter validation.
/// - **Collection Tools:** [CollectionUtils], array and list slicing, deduplication.
/// - **Optional Values:** [Optional] monad for expressive nullable value handling.
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🔤 String & Path Utilities
/// - [StringUtils] — high-performance string operations: capitalization, substring splitting, token replacement, path normalization.
///
/// ### 🛡️ Preconditions & Assertions
/// - [Assert] — defensive programming validation contract throwing [IllegalArgumentException] on failure.
///
/// ### 📦 Optional Monad
/// - [Optional] — container object which may or may not contain a non-null value (`isPresent`, `ifPresent`, `orElse`, `map`).
///
/// ### ⚖️ Equality & Hashing
/// - [EqualsAndHashCode] — mixin providing deep equality and deterministic hash code computation.
/// - [ObjectUtils] — safe null-handling, identity comparisons, and string representations.
///
/// ---
///
/// ## 🎯 Usage Example: Defensive Assertions & Optional Handling
///
/// ```dart
/// import 'package:jetleaf/utils.dart';
///
/// class AccountService {
///   void deposit(String accountId, double amount) {
///     Assert.hasText(accountId, 'Account ID must not be blank');
///     Assert.isTrue(amount > 0, 'Deposit amount must be strictly positive');
///
///     print('Deposited \$$amount into $accountId');
///   }
///
///   Optional<String> findDiscountCode(String tier) {
///     if (tier == 'VIP') {
///       return Optional.of('VIP-DISCOUNT-50');
///     }
///     return Optional.empty();
///   }
/// }
///
/// void main() {
///   final service = AccountService();
///   service.deposit('ACC-4001', 150.0);
///
///   final discount = service.findDiscountCode('VIP');
///   print('Discount: ${discount.orElse('NO_DISCOUNT')}');
/// }
/// ```
///
/// {@category Jetleaf}
library;

export 'package:jetleaf_core/utils.dart';
