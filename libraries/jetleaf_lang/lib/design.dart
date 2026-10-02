// ignore_for_file: deprecated_member_use

/// **Jetleaf Standard Library**
///
/// This library exposes the core foundational utilities of the Jetleaf
/// framework—providing rich APIs for resource handling, I/O streams,
/// collections, math, reflection, system access, time utilities, and more.
///
/// It functions as the **general-purpose toolkit** for Jetleaf applications,
/// similar to a standard library or runtime utility layer.
///
///
/// ## 🧩 Major Capability Areas
///
/// ### 📦 Resource & Asset Loading
/// Supports resolving and loading resources from:
/// - application bundles
/// - asset paths
/// - classpath locations  
/// Includes loaders, resource abstractions, and path utilities.
///
///
/// ### 🔢 Byte & Stream Utilities
/// Low-level binary and streaming primitives:
/// - `Byte`, `ByteArray`, `ByteStream`
/// - Input & output streams (buffered, file, network, in-memory)
/// - Stream builders and adapters
///
/// Enables efficient data processing and I/O pipelines.
///
///
/// ### 📚 Collections Framework
/// Enhanced data structures beyond core Dart:
/// - `ArrayList`, `LinkedList`, `Stack`, `Queue`
/// - `HashMap`, `HashSet`
/// - case-insensitive maps
/// - collectors (inspired by Java Streams)
///
///
/// ### 🧮 Math & Big Numbers
/// Arbitrary-precision numeric types:
/// - `BigDecimal`
/// - `BigInteger`
///
///
/// ### 🌐 Networking
/// Lightweight networking primitives:
/// - `Url`
/// - `UrlConnection`
/// - extension helpers
///
///
/// ### 🔤 Primitive Wrappers
/// Object-style number and boolean types:
/// - `Integer`, `Long`, `Float`, `Double`, `Short`, `Boolean`, `Character`
///
/// Useful for reflection, typed metadata, and JVM-style APIs.
///
///
/// ### 🖥 System & Properties
/// Runtime system inspection and configuration:
/// - platform detectors
/// - system properties
/// - environment-driven behavior
///
///
/// ### ⏱ Time & Date API
/// Inspired by Java Time:
/// - `ZonedDateTime`
/// - `LocalDateTime`, `LocalDate`, `LocalTime`
/// - `ZoneId`
/// - `DateTimeFormatter`
///
///
/// ### 🧵 Threading & Synchronization
/// Cooperative thread abstractions:
/// - logical thread model
/// - synchronization primitives
/// - locks
///
/// *Note:* hides internal `LocalThreadKey`.
///
/// ### 🗂 URI Tools
/// - URI templates
/// - validators and validation rules
///
///
/// ### 🔔 Observability (OBS)
/// Eventing system:
/// - observables
/// - event types & enums
///
///
/// ### 🧰 Common Utilities
/// - `Optional`
/// - `StringBuilder`
/// - regex utilities
/// - typedef helpers
///
///
/// ### 🆔 Other Features
/// - locale & language ranges
/// - currency utilities
/// - UUID generation
/// - exception hierarchy
///
///
/// ## ✅ Intended Usage
///
/// Import once for broad utility access:
/// ```dart
/// import 'package:jetleaf_lang/design.dart';
/// ```
///
/// Designed for framework-level and advanced application use.
library;

export 'src/byte/byte_array.dart';
export 'src/byte/byte_stream.dart';
export 'src/byte/byte.dart';

export 'collections.dart';

export 'src/comparator/comparator.dart';
export 'src/comparator/order_comparator.dart';
export 'src/comparator/ordered.dart';
export 'src/comparator/package_order_comparator.dart';

export 'extensions.dart';
export 'io.dart';

export 'src/garbage_collector/garbage_collector.dart';

export 'src/math/big_decimal.dart';
export 'src/math/big_integer.dart';

export 'src/net/url.dart';
export 'src/net/url_connection.dart';
export 'src/net/extension.dart';

export 'src/primitives/integer.dart';
export 'src/primitives/long.dart';
export 'src/primitives/float.dart';
export 'src/primitives/double.dart';
export 'src/primitives/character.dart';
export 'src/primitives/boolean.dart';
export 'src/primitives/short.dart';

export 'src/time/zoned_date_time.dart';
export 'src/time/local_date_time.dart';
export 'src/time/local_date.dart';
export 'src/time/local_time.dart';
export 'src/time/zone_id.dart';
export 'src/time/date_time_formatter.dart';

export 'src/thread/thread.dart';
export 'src/thread/local_thread.dart' hide LocalThreadKey;

export 'src/synchronized/synchronized.dart';
export 'src/synchronized/synchronized_lock.dart';

export 'src/commons/optional.dart';
export 'src/commons/string_builder.dart';
export 'src/commons/commons.dart' hide TryWithAction;
export 'src/commons/regex_utils.dart';
export 'src/commons/typedefs.dart';
export 'src/commons/version.dart';
export 'src/commons/version_range.dart';

export 'src/locale/locale.dart';
export 'src/locale/language_range.dart';

export 'src/currency/currency.dart';
export 'src/uuid/uuid.dart';

export 'src/uri/uri_template.dart';
export 'src/uri/uri_validators.dart';
export 'src/uri/uri_validator.dart';

export 'src/utils/method_utils.dart';
export 'src/utils/class_utils.dart';
export 'src/utils/number_utils.dart';
export 'src/utils/mime_type.dart';
export 'src/utils/mime_type_utils.dart';

export 'src/obs/obs.dart';
export 'src/obs/obs_enums.dart';
export 'src/obs/obs_event.dart';
export 'src/obs/obs_types.dart';

export 'src/exceptions.dart';
export 'src/nested_runtime_exception.dart';