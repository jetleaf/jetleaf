import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_utils/utils.dart';
import 'package:meta/meta.dart';

import '../profiles/profiles.dart';
import '../property_resolver/property_resolver.dart';
import '../property_resolver/property_sources_property_resolver.dart';
import '../property_source/mutable_property_sources.dart';
import 'environment.dart';

/// {@template abstract_environment}
/// Base class for creating environment implementations in Jetleaf.
///
/// `AbstractEnvironment` is a foundational implementation of [ConfigurableEnvironment]
/// that manages environment properties and profiles via:
/// - A [MutablePropertySources] collection,
/// - A [PropertySourcesPropertyResolver] for resolving properties,
/// - A [ConfigurableConversionService] for type conversions,
/// - and support for placeholder resolution and profile activation.
///
/// Subclasses should override [customizePropertySources] to register their own
/// sources, such as system properties, application config maps, or custom sources.
///
/// ### Example
/// ```dart
/// class MyEnvironment extends AbstractEnvironment {
///   @override
///   void customizePropertySources(MutablePropertySources sources) {
///     sources.addLast(MapPropertySource('my-config', {
///       'server.port': '8080',
///       'debug': 'true',
///     }));
///   }
/// }
///
/// void main() {
///   final env = MyEnvironment();
///   print(env.getProperty('server.port')); // 8080
/// }
/// ```
///
/// ### Profiles
/// Jetleaf supports both *active* and *default* profiles:
/// - Active profiles are those explicitly set using [setActiveProfiles] or [addActiveProfile].
/// - Default profiles are used when no active profile is set, and can be configured using [setDefaultProfiles].
///
/// A default profile name of `"default"` is always used unless overridden.
///
/// ### System properties and environment
/// You can access system properties and environment variables using [getSystemProperties]
/// and [getSystemEnvironment]. To suppress access to `System.getenv()`, set the
/// `jetleaf.getenv.ignore` flag via `JetleafProperties`.
///
/// {@endtemplate}
abstract class AbstractEnvironment extends ConfigurableEnvironment {
  /// {@template ignore_getenv_property_name}
  /// **System Environment Suppression Flag**
  ///
  /// Property key used to disable access to system environment variables.
  /// If this property is set to `true`, calls to [getSystemEnvironment]
  /// will return an empty map instead of reading the host OS environment.
  ///
  /// # Value
  /// `"jetleaf.getenv.ignore"`
  ///
  /// # Example
  /// ```properties
  /// jetleaf.getenv.ignore=true
  /// ```
  /// {@endtemplate}
  static final String IGNORE_GETENV_PROPERTY_NAME = "jetleaf.getenv.ignore";

  /// {@template active_profiles_property_name}
  /// **Active Profiles Property**
  ///
  /// Property key used to declare profiles that should be activated at runtime.
  /// Profiles specified here become part of the environment’s active profiles.
  ///
  /// # Value
  /// `"jetleaf.profiles.active"`
  ///
  /// # Example
  /// ```properties
  /// jetleaf.profiles.active=dev,staging
  /// ```
  /// {@endtemplate}
  static final String ACTIVE_PROFILES_PROPERTY_NAME = "jetleaf.profiles.active";

  /// {@template default_profiles_property_name}
  /// **Default Profiles Property**
  ///
  /// Property key used to declare fallback profiles when no active profiles
  /// are explicitly set. This allows developers to define baseline behavior
  /// without requiring manual activation.
  ///
  /// # Value
  /// `"jetleaf.profiles.default"`
  ///
  /// # Example
  /// ```properties
  /// jetleaf.profiles.default=dev
  /// ```
  /// {@endtemplate}
  static final String DEFAULT_PROFILES_PROPERTY_NAME = "jetleaf.profiles.default";

  /// {@template reserved_default_profile_name}
  /// **Reserved Default Profile Name**
  ///
  /// Constant string `"default"`, representing the canonical reserved profile.
  /// This profile is always available as a baseline configuration context,
  /// ensuring that the environment never operates without at least one profile.
  ///
  /// # Value
  /// `"default"`
  ///
  /// # Notes
  /// - Used by [getReservedDefaultProfiles].
  /// - Cannot be removed or overridden by configuration.
  /// {@endtemplate}
  static final String RESERVED_DEFAULT_PROFILE_NAME = "default";

  /// {@template active_profiles_field}
  /// **Internal Active Profiles Set**
  ///
  /// Stores the active profiles currently applied to the environment.
  /// This set is populated from:
  /// - Explicit configuration (via [setActiveProfiles]).
  /// - Properties loaded from [ACTIVE_PROFILES_PROPERTY_NAME].
  ///
  /// # Notes
  /// - Thread-safe access is enforced using [synchronized].
  /// - Consumers should access via [doGetActiveProfiles] instead of directly.
  /// {@endtemplate}
  final Set<String> _activeProfiles = <String>{};

  /// {@template default_profiles_field}
  /// **Internal Default Profiles Set**
  ///
  /// Stores the default profiles applied when no explicit active profiles exist.
  /// This set is populated from:
  /// - Reserved defaults ([getReservedDefaultProfiles]).
  /// - Properties loaded from [DEFAULT_PROFILES_PROPERTY_NAME].
  ///
  /// # Notes
  /// - Thread-safe access is enforced using [synchronized].
  /// - Consumers should access via [doGetDefaultProfiles] instead of directly.
  /// {@endtemplate}
  final Set<String> _defaultProfiles = <String>{};

  /// {@template property_sources_field}
  /// **Backing Property Sources**
  ///
  /// Ordered collection of property sources for this environment. Each source
  /// represents a configuration provider, such as system properties, property
  /// files, or environment variables. Sources are searched in order when
  /// resolving property values.
  ///
  /// # Notes
  /// - Initialized by the constructor.
  /// - Subclasses can customize via [customizePropertySources].
  /// {@endtemplate}
  late final MutablePropertySources _propertySources;

  /// {@template property_resolver_field}
  /// **Backing Property Resolver**
  ///
  /// The [ConfigurablePropertyResolver] instance used to resolve properties
  /// against the current [MutablePropertySources].
  ///
  /// # Notes
  /// - Initialized alongside [_propertySources].
  /// - Retrieved via [getPropertyResolver].
  /// {@endtemplate}
  late final ConfigurablePropertyResolver _propertyResolver;

  /// {@macro abstract_environment}
  AbstractEnvironment() : this.source(MutablePropertySources());

  /// {@template environment_source_ctor}
  /// **Constructor with Pre-Created Sources**
  ///
  /// Initializes the environment with a caller-supplied
  /// [MutablePropertySources] list. This constructor is used internally
  /// and by subclasses that want to directly control the initial set
  /// and ordering of property sources.
  ///
  /// # Behavior
  /// - Assigns the provided [propertySources] to the internal state.
  /// - Creates a resolver via [createPropertyResolver].
  /// - Calls [customizePropertySources] to allow further subclass
  ///   modifications.
  /// - Populates default profiles with reserved defaults.
  ///
  /// # Example
  /// ```dart
  /// final customSources = MutablePropertySources();
  /// final env = MyEnvironment.source(customSources);
  /// ```
  ///
  /// # Notes
  /// - Typically used by framework code, not by application developers.
  /// {@endtemplate}
  /// 
  /// {@macro abstract_environment}
  @protected
  AbstractEnvironment.source(MutablePropertySources propertySources) {
    _propertySources = propertySources;
    _propertyResolver = createPropertyResolver(propertySources);
    customizePropertySources(propertySources);
    _defaultProfiles.addAll(getReservedDefaultProfiles());
  }

  /// {@template get_property_resolver}
  /// **Access to the Property Resolver**
  ///
  /// Returns the [ConfigurablePropertyResolver] associated with this
  /// environment. The resolver is responsible for:
  /// - Resolving property values from the configured [MutablePropertySources].
  /// - Performing type conversion for property values.
  /// - Handling placeholder substitution in strings.
  ///
  /// # Example
  /// ```dart
  /// final resolver = getPropertyResolver();
  /// final port = resolver.getProperty('server.port', int);
  /// ```
  ///
  /// # Notes
  /// - Marked `@protected`: intended for subclasses and framework internals.
  /// - The resolver instance is initialized when the environment is created.
  /// {@endtemplate}
  @protected
  ConfigurablePropertyResolver getPropertyResolver() => _propertyResolver;

  /// {@template get_reserved_default_profiles}
  /// **Reserved Default Profiles**
  ///
  /// Returns the reserved set of default profiles. By default, this is
  /// the singleton set containing only `"default"`. These profiles act as
  /// a safety net to ensure the environment always has a baseline profile.
  ///
  /// # Example
  /// ```dart
  /// final reserved = getReservedDefaultProfiles();
  /// print(reserved); // { "default" }
  /// ```
  ///
  /// # Notes
  /// - Subclasses may override to provide additional reserved profiles.
  /// - This set is used when no active or explicit default profiles
  ///   have been configured.
  /// {@endtemplate}
  @protected
  Set<String> getReservedDefaultProfiles() => <String>{RESERVED_DEFAULT_PROFILE_NAME};

  /// {@template create_property_resolver}
  /// **Factory for Property Resolver**
  ///
  /// Creates a new [PropertySourcesPropertyResolver] bound to the given
  /// [propertySources]. This resolver provides property lookup, conversion,
  /// and placeholder resolution based on the ordered list of sources.
  ///
  /// # Parameters
  /// - [propertySources]: a mutable, ordered collection of property sources
  ///   (e.g., environment variables, property files, system properties).
  ///
  /// # Returns
  /// A [ConfigurablePropertyResolver] implementation backed by the provided
  /// property sources.
  ///
  /// # Example
  /// ```dart
  /// final sources = MutablePropertySources();
  /// final resolver = createPropertyResolver(sources);
  /// print(resolver.getProperty('app.name'));
  /// ```
  ///
  /// # Notes
  /// - Marked `@protected`, intended for subclass customization.
  /// - Subclasses can override to provide an alternate resolver strategy.
  /// {@endtemplate}
  @protected
  ConfigurablePropertyResolver createPropertyResolver(MutablePropertySources propertySources) {
    return PropertySourcesPropertyResolver(propertySources);
  }

  /// {@template suppress_getenv_access}
  /// **Suppresses System Environment Access**
  ///
  /// Determines whether system environment access (via [getSystemEnvironment])
  /// should be disabled. This is controlled by the
  /// [IGNORE_GETENV_PROPERTY_NAME] flag, retrieved using [JetleafProperties].
  ///
  /// # Returns
  /// - `true` if system environment access is disabled.
  /// - `false` if system environment variables should be accessible.
  ///
  /// # Example
  /// ```dart
  /// if (suppressGetenvAccess()) {
  ///   print('System environment access suppressed.');
  /// }
  /// ```
  ///
  /// # Notes
  /// - When suppressed, [getSystemEnvironment] always returns an empty map.
  /// - Useful for security-sensitive contexts where environment access
  ///   must be restricted.
  /// {@endtemplate}
  @protected
  bool suppressGetenvAccess() => getPropertyAs<bool>(IGNORE_GETENV_PROPERTY_NAME, Class<bool>()) ?? false;

  /// {@template validate_profile}
  /// **Profile Name Validation**
  ///
  /// Ensures the given [profile] is valid before use.
  ///
  /// # Rules
  /// - Must not be `null` or empty.
  /// - Must not start with `'!'` (reserved for logical negation in profile
  ///   expressions).
  ///
  /// # Throws
  /// - [IllegalArgumentException] if validation fails.
  ///
  /// # Example
  /// ```dart
  /// validateProfile('dev'); // OK
  /// validateProfile('');    // throws
  /// validateProfile('!test'); // throws
  /// ```
  /// {@endtemplate}
  @protected
  void validateProfile(String profile) {
    if (profile.isEmpty) {
      throw IllegalArgumentException("Invalid profile [$profile]: must contain text");
    }

    if (profile.startsWith('!')) {
      throw IllegalArgumentException("Invalid profile [$profile]: must not begin with ! operator");
    }
  }

  /// {@template is_profile_active}
  /// **Checks Profile Activation**
  ///
  /// Determines whether the specified [profile] is currently active.
  ///
  /// # Behavior
  /// - Validates the [profile] using [validateProfile].
  /// - If the active profiles set is non-empty, checks membership directly.
  /// - If no profiles are active, falls back to checking default profiles.
  ///
  /// # Returns
  /// - `true` if the profile is active or part of the defaults.
  /// - `false` otherwise.
  ///
  /// # Example
  /// ```dart
  /// if (isProfileActive('prod')) {
  ///   enableProductionMode();
  /// }
  /// ```
  ///
  /// # Notes
  /// - Case sensitivity depends on the environment’s profile handling.
  /// {@endtemplate}
  @protected
  bool isProfileActive(String profile) {
    validateProfile(profile);
    final profiles = doGetActiveProfiles();
    return (profiles.contains(profile) || (profiles.isEmpty && doGetDefaultProfiles().contains(profile)));
  }

  /// {@template do_get_active_profiles}
  /// **Resolves Active Profiles**
  ///
  /// Computes the effective set of active profiles, reading from the
  /// [ACTIVE_PROFILES_PROPERTY_NAME] if necessary.
  ///
  /// # Behavior
  /// - If [_activeProfiles] is empty, attempts to read the active profiles
  ///   property.
  /// - Parses and applies the property value as a comma-delimited list.
  /// - Updates the internal [_activeProfiles] set.
  ///
  /// # Returns
  /// A synchronized [Set] of active profile names.
  ///
  /// # Example
  /// ```dart
  /// final activeProfiles = doGetActiveProfiles();
  /// print(activeProfiles);
  /// ```
  ///
  /// # Notes
  /// - Thread-safe: access is synchronized on [_activeProfiles].
  /// - Avoids repeated property lookups once populated.
  /// {@endtemplate}
  @protected
  Set<String> doGetActiveProfiles() {
    return synchronized(_activeProfiles, () {
      if (_activeProfiles.isEmpty) {
        final profiles = doGetActiveProfilesProperty();
        if (profiles?.isNotEmpty ?? false) {
          setActiveProfiles(StringUtils.commaDelimitedListToStringList(StringUtils.trimAllWhitespace(profiles!)));
        }
      }
      return _activeProfiles;
    });
  }

  /// {@template do_get_active_profiles_property}
  /// **Reads Active Profiles Property**
  ///
  /// Reads the value of the `jetleaf.profiles.active` property.
  ///
  /// # Returns
  /// - A raw string of comma-delimited profile names, or `null` if unset.
  ///
  /// # Example
  /// ```dart
  /// final prop = doGetActiveProfilesProperty();
  /// print(prop); // e.g., "dev,staging"
  /// ```
  ///
  /// # Notes
  /// - Parsing is handled by [doGetActiveProfiles].
  /// - Property names are standardized constants.
  /// {@endtemplate}
  @protected
  String? doGetActiveProfilesProperty() => getProperty(ACTIVE_PROFILES_PROPERTY_NAME);

  /// {@template do_get_default_profiles}
  /// **Resolves Default Profiles**
  ///
  /// Computes the effective set of default profiles, reading from the
  /// [DEFAULT_PROFILES_PROPERTY_NAME] if applicable.
  ///
  /// # Behavior
  /// - If [_defaultProfiles] contains only the reserved `"default"`, attempts
  ///   to resolve configured defaults from properties.
  /// - Parses and applies the property value as a comma-delimited list.
  /// - Updates the internal [_defaultProfiles] set.
  ///
  /// # Returns
  /// A synchronized [Set] of default profile names.
  ///
  /// # Example
  /// ```dart
  /// final defaults = doGetDefaultProfiles();
  /// print(defaults); // e.g., ["default"]
  /// ```
  ///
  /// # Notes
  /// - Thread-safe: access is synchronized on [_defaultProfiles].
  /// - Ensures fallback profiles exist when no actives are configured.
  /// {@endtemplate}
  @protected
  Set<String> doGetDefaultProfiles() {
    return synchronized(_defaultProfiles, () {
      if (_defaultProfiles.equals(getReservedDefaultProfiles())) {
        final profiles = doGetDefaultProfilesProperty();
        if (profiles?.isNotEmpty ?? false) {
          setDefaultProfiles(StringUtils.commaDelimitedListToStringList(StringUtils.trimAllWhitespace(profiles!)));
        }
      }
      return _defaultProfiles;
    });
  }

  /// {@template do_get_default_profiles_property}
  /// **Reads Default Profiles Property**
  ///
  /// Reads the value of the `jetleaf.profiles.default` property.
  ///
  /// # Returns
  /// - A raw string of comma-delimited default profile names, or `null` if unset.
  ///
  /// # Example
  /// ```dart
  /// final prop = doGetDefaultProfilesProperty();
  /// print(prop); // e.g., "dev"
  /// ```
  ///
  /// # Notes
  /// - Parsing is handled by [doGetDefaultProfiles].
  /// - Defaults provide fallback when no active profiles exist.
  /// {@endtemplate}
  @protected
  String? doGetDefaultProfilesProperty() => getProperty(DEFAULT_PROFILES_PROPERTY_NAME);

  /// {@template customize_property_sources}
  /// Called during construction to allow subclasses to register default property sources.
  ///
  /// Override this method in your custom environment implementation to add
  /// system properties, YAML or map-based configuration sources, etc.
  ///
  /// ### Example
  /// ```dart
  /// @override
  /// void customizePropertySources(MutablePropertySources sources) {
  ///   sources.addLast(MapPropertySource('app', {
  ///     'env': 'production',
  ///     'debug': 'false',
  ///   }));
  /// }
  /// ```
  /// {@endtemplate}
  void customizePropertySources(MutablePropertySources sources);

  @override
	List<String> getActiveProfiles() => doGetActiveProfiles().toList();

  @override
	void setActiveProfiles(List<String> profiles) {
		return synchronized(_activeProfiles, () {
			_activeProfiles.clear();
			for (final profile in profiles) {
				validateProfile(profile);
				_activeProfiles.add(profile);
			}
		});
	}

	@override
	void addActiveProfile(String profile) {
		validateProfile(profile);
		doGetActiveProfiles();

		return synchronized(_activeProfiles, () => _activeProfiles.add(profile));
	}

	@override
	List<String> getDefaultProfiles() => doGetDefaultProfiles().toList();

	/// Specify the set of profiles to be made active by default if no other profiles
	/// are explicitly made active through {@link #setActiveProfiles}.
	/// <p>Calling this method removes overrides any reserved default profiles
	/// that may have been added during construction of the environment.
	/// @see #AbstractEnvironment()
	/// @see #getReservedDefaultProfiles()
	@override
	void setDefaultProfiles(List<String> profiles) {
		return synchronized(_defaultProfiles, () {
			_defaultProfiles.clear();
			for (final profile in profiles) {
				validateProfile(profile);
				_defaultProfiles.add(profile);
			}
		});
	}

	@override
	bool acceptsProfiles(Profiles profiles) => profiles.matches((profile) => isProfileActive(profile));

	@override
	MutablePropertySources getPropertySources() => _propertySources;

	@override
	Map<String, String> getSystemProperties() => System.getProperties();

	@override
	Map<String, String> getSystemEnvironment() {
		if (suppressGetenvAccess()) {
			return {};
		}

		return System.getEnv();
	}

	@override
	void merge(ConfigurableEnvironment parent) {
		for (final ps in parent.getPropertySources()) {
			if (!_propertySources.containsName(ps.getName())) {
				_propertySources.addLast(ps);
			}
		}

		final parentActiveProfiles = parent.getActiveProfiles();
		if (parentActiveProfiles.isNotEmpty) {
			synchronized(_activeProfiles, () {
				_activeProfiles.addAll(parentActiveProfiles);
			});
		}

		final parentDefaultProfiles = parent.getDefaultProfiles();
		if (parentDefaultProfiles.isNotEmpty) {
			synchronized(_defaultProfiles, () {
				_defaultProfiles.remove(RESERVED_DEFAULT_PROFILE_NAME);
				_defaultProfiles.addAll(parentDefaultProfiles);
			});
		}
	}

	//---------------------------------------------------------------------
	// Implementation of ConfigurablePropertyResolver interface
	//---------------------------------------------------------------------

	@override
	ConfigurableConversionService getConversionService() => _propertyResolver.getConversionService();

	@override
	void setConversionService(ConfigurableConversionService conversionService) {
		_propertyResolver.setConversionService(conversionService);
	}

	@override
	void setPlaceholderPrefix(String placeholderPrefix) {
		_propertyResolver.setPlaceholderPrefix(placeholderPrefix);
	}

	@override
	void setPlaceholderSuffix(String placeholderSuffix) {
		_propertyResolver.setPlaceholderSuffix(placeholderSuffix);
	}

	@override
	void setValueSeparator(String? valueSeparator) {
		if (valueSeparator != null) {
			_propertyResolver.setValueSeparator(valueSeparator);
		}
	}

	@override
	void setEscapeCharacter(Character? escapeCharacter) {
		if (escapeCharacter != null) {
			_propertyResolver.setEscapeCharacter(escapeCharacter);
		}
	}

	@override
	void setIgnoreUnresolvableNestedPlaceholders(bool ignoreUnresolvableNestedPlaceholders) {
		_propertyResolver.setIgnoreUnresolvableNestedPlaceholders(ignoreUnresolvableNestedPlaceholders);
	}

	@override
	void setRequiredProperties(List<String> requiredProperties) {
		_propertyResolver.setRequiredProperties(requiredProperties);
	}

	@override
	void validateRequiredProperties() {
		_propertyResolver.validateRequiredProperties();
	}

	//---------------------------------------------------------------------
	// Implementation of PropertyResolver interface
	//---------------------------------------------------------------------

	@override
	bool containsProperty(String key) => _propertyResolver.containsProperty(key);

	@override
	String? getProperty(String key, [String? defaultValue]) => _propertyResolver.getProperty(key, defaultValue);

	@override
	T? getPropertyAs<T>(String key, Class<T> targetType, [T? defaultValue]) {
		return _propertyResolver.getPropertyAs(key, targetType, defaultValue);
	}

	@override
	String getRequiredProperty(String key) => _propertyResolver.getRequiredProperty(key);

	@override
	T getRequiredPropertyAs<T>(String key, Class<T> targetType) => _propertyResolver.getRequiredPropertyAs(key, targetType);

	@override
	String resolvePlaceholders(String text) => _propertyResolver.resolvePlaceholders(text);

	@override
	String resolveRequiredPlaceholders(String text) => _propertyResolver.resolveRequiredPlaceholders(text);

	@override
	List<String> suggestions(String key) => _propertyResolver.suggestions(key);

	@override
	String toString() => "$runtimeType(activeProfiles= $_activeProfiles, defaultProfiles= $_defaultProfiles, propertySources= $_propertySources)";
}