import 'package:jetleaf_web/jetleaf_web.dart';

/// {@template client_key_extractor}
/// Derives the rate-limit bucket key for a request.
///
/// Implementations must not trust client-controlled headers unless the direct
/// peer is configured as a trusted proxy.
/// {@endtemplate}
typedef ClientKeyExtractor = String Function(ServerHttpRequest request);

/// {@template clock_supplier}
/// Supplies the current time.
///
/// Injectable so time-dependent filters can be tested deterministically.
/// {@endtemplate}
typedef ClockSupplier = DateTime Function();