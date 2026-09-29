/// 🌐 **Jetleaf Core Message**
///
/// Provides infrastructure for message retrieval, internationalization (i18n),
/// and localization in Jetleaf applications. This library allows developers
/// to manage messages, load them from various sources, and support
/// parent-child hierarchies for fallback message resolution.
///
/// ## 🔑 Core Components
///
/// ### Message Source
/// - `message_source.dart` — core interface for retrieving messages by key,
///   supporting locale-specific lookups and parameterized messages.
///
/// ### Message Source Loader
/// - `message_source_loader.dart` — strategy interface for loading messages
///   from different sources and formats (e.g., JSON, YAML, properties files).
///
/// ### Abstract Message Source
/// - `abstract_message_source.dart` — base implementation providing
///   common functionality for message sources, including support for
///   parent-child message resolution.
///
/// ### Configurable Message Source
/// - `configurable_message_source.dart` — full-featured, configurable
///   message source implementation with the ability to customize
///   message loading, caching, and fallback mechanisms.
///
///
/// ## 🎯 Intended Usage
///
/// Import this library to manage internationalized messages in Jetleaf:
///
/// ```dart
/// import 'package:jetleaf_core/message.dart';
///
/// final messages = ConfigurableMessageSource();
/// messages.loadFromJson('messages_en.json');
/// final greeting = messages.getMessage('hello', locale: 'en');
/// ```
///
/// Provides a standard foundation for i18n, message retrieval,
/// and localization in Jetleaf applications.
///
/// {@category Internationalization}
library;

/// Core interface for message retrieval and internationalization support.
export 'src/message/message_source.dart';

/// Strategy interface for loading messages from various sources and formats.
export 'src/message/message_source_loader.dart';

/// Base implementation with common message source functionality and parent-child support.
export 'src/message/abstract_message_source.dart';

/// Full-featured message source implementation with configuration capabilities.
export 'src/message/configurable_message_source.dart';