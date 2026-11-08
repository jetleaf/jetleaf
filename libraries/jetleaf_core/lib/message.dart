/// 🌐 **Jetleaf Internationalization (i18n) & Message Subsystem**
///
/// This library provides the message resolution and internationalization (i18n)
/// infrastructure for Jetleaf applications, enabling parameter-driven localized text,
/// message bundles, and hierarchical fallback resolution.
///
/// ---
///
/// ## 📦 Exports Categorization
///
/// ### 🗣️ Message Sources
/// - [MessageSource] — strategy interface for resolving messages, supporting parameterized arguments and internationalization.
/// - [AbstractMessageSource] — base implementation handling parameter interpolation and hierarchical parent delegation.
/// - [ConfigurableMessageSource] — mutable message source allowing runtime message registration.
/// - [MessageSourceLoader] — utility for loading message bundles from property files or JSON assets.
///
/// ---
///
/// ## 🎯 Usage Example: Localized Message Resolution
///
/// ```dart
/// import 'package:jetleaf_core/message.dart';
///
/// void main() {
///   final source = ConfigurableMessageSource();
///   source.addMessage('user.welcome', 'en', 'Welcome back, {0}!');
///   source.addMessage('user.welcome', 'fr', 'Bienvenue, {0}!');
///
///   final enMsg = source.getMessage('user.welcome', args: ['Alice'], locale: 'en');
///   final frMsg = source.getMessage('user.welcome', args: ['Alice'], locale: 'fr');
///
///   print(enMsg); // Welcome back, Alice!
///   print(frMsg); // Bienvenue, Alice!
/// }
/// ```
library;

export 'src/core/message/message_source.dart';
export 'src/core/message/message_source_loader.dart';
export 'src/core/message/abstract_message_source.dart';
export 'src/core/message/configurable_message_source.dart';