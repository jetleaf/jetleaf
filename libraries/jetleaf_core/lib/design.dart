// ignore_for_file: deprecated_member_use

/// **Jetleaf Standard Library**
///
/// This library exposes the core foundational utilities of the Jetleaf
/// framework—providing rich APIs for resource handling, I/O streams,
/// collections, math, reflection, system access, time utilities, and more.
library;

export 'src/lang/byte/byte_array.dart';
export 'src/lang/byte/byte_stream.dart';
export 'src/lang/byte/byte.dart';

export 'collections.dart';

export 'src/lang/comparator/comparator.dart';
export 'src/lang/comparator/order_comparator.dart';
export 'src/lang/comparator/ordered.dart';
export 'src/lang/comparator/package_order_comparator.dart';

export 'extensions.dart';
export 'io.dart';

export 'src/lang/garbage_collector/garbage_collector.dart';

export 'src/lang/math/big_decimal.dart';
export 'src/lang/math/big_integer.dart';

export 'src/lang/net/url.dart';
export 'src/lang/net/url_connection.dart';
export 'src/lang/net/extension.dart';

export 'src/lang/primitives/integer.dart';
export 'src/lang/primitives/long.dart';
export 'src/lang/primitives/float.dart';
export 'src/lang/primitives/double.dart';
export 'src/lang/primitives/character.dart';
export 'src/lang/primitives/boolean.dart';
export 'src/lang/primitives/short.dart';

export 'src/lang/time/zoned_date_time.dart';
export 'src/lang/time/local_date_time.dart';
export 'src/lang/time/local_date.dart';
export 'src/lang/time/local_time.dart';
export 'src/lang/time/zone_id.dart';
export 'src/lang/time/date_time_formatter.dart';

export 'src/lang/thread/thread.dart';
export 'src/lang/thread/local_thread.dart' hide LocalThreadKey;

export 'src/lang/synchronized/synchronized.dart';
export 'src/lang/synchronized/synchronized_lock.dart';

export 'src/lang/commons/optional.dart';
export 'src/lang/commons/string_builder.dart';
export 'src/lang/commons/commons.dart' hide TryWithAction;
export 'src/lang/commons/regex_utils.dart';
export 'src/lang/commons/typedefs.dart';
export 'src/lang/commons/version.dart';
export 'src/lang/commons/version_range.dart';

export 'src/lang/locale/locale.dart';
export 'src/lang/locale/language_range.dart';

export 'src/lang/currency/currency.dart';
export 'src/lang/uuid/uuid.dart';

export 'src/lang/uri/uri_template.dart';
export 'src/lang/uri/uri_validators.dart';
export 'src/lang/uri/uri_validator.dart';

export 'src/lang/utils/method_utils.dart';
export 'src/lang/utils/class_utils.dart';
export 'src/lang/utils/number_utils.dart';
export 'src/lang/utils/mime_type.dart';
export 'src/lang/utils/mime_type_utils.dart';

export 'src/lang/obs/obs.dart';
export 'src/lang/obs/obs_enums.dart';
export 'src/lang/obs/obs_event.dart';
export 'src/lang/obs/obs_types.dart';

export 'src/lang/exceptions.dart';
export 'src/lang/nested_runtime_exception.dart';