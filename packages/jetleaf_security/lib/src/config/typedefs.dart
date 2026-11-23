/// {@template configurer}
/// Configures a builder object before it is used.
///
/// The lambda DSL passes one configurer to each `HttpSecurity` section, so the
/// same shape appears throughout the configuration API. Naming it keeps the
/// public signatures consistent and avoids repeating the closure type.
///
/// ### Example
/// ```dart
/// Configurer<CorsConfigurer> cors = (cors) => cors.configuration(config);
/// ```
/// {@endtemplate}
typedef Configurer<T> = void Function(T configurer);
