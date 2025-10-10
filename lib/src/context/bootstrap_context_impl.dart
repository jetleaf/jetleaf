// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_pod/pod.dart';
import 'package:jetleaf_utils/utils.dart';

import 'bootstrap_context.dart';

/// {@template default_bootstrap_context}
/// Default implementation of [ConfigurableBootstrapContext] used during
/// application bootstrap phase in the JetLeaf framework.
///
/// It allows registration and lazy resolution of bootstrapped components
/// using type-safe keys (`Class<T>`). It also manages event listeners for
/// context closure events.
///
/// ### Features:
/// - Type-safe registration of components
/// - Lazy instantiation via `BootstrapRegistryInstanceSupplier`
/// - Singleton scope support
/// - Graceful fallback methods: `getOrElse`, `getOrElseSupply`, `getOrElseThrow`
/// - Close listeners for context lifecycle events
///
/// ### Example:
/// ```dart
/// final context = DefaultBootstrapContext();
/// context.register(MyService.classType, SingletonBootstrapSupplier((ctx) => MyService()));
///
/// final service = context.get(MyService.classType);
/// ```
/// {@endtemplate}
class DefaultBootstrapContext implements ConfigurableBootstrapContext {
	final Map<Class, BootstrapInstanceSupplier<Object>> _isps = {};
	final Map<Class, Object> _instances = {};
	final ApplicationEventBus _eventBus = _BootstrapEventBus();
  late Class<Object> _applicationClass;

	@override
	Class<Object> getApplicationClass() => _applicationClass;

	@override
	void setApplicationClass(Class<Object> applicationClass) {
		_applicationClass = applicationClass;
	}

	@override
	void register<T>(Class<T> type, BootstrapInstanceSupplier<T> supplier) {
		_register(type, supplier, true);
	}

  /// Registers an instance supplier with the option to override an existing registration.
  ///
  /// - [type] is the class type key for the instance.
  /// - [isp] provides the instance when requested.
  /// - [replaceExisting] determines whether to overwrite existing supplier.
  ///
  /// Throws [IllegalStateException] if an instance was already created.
	void _register<T>(Class<T> type, BootstrapInstanceSupplier<T> isp, bool replaceExisting) {
		return synchronized(_isps, () {
			bool alreadyRegistered = _isps.containsKey(type);
			if (replaceExisting || !alreadyRegistered) {
				Assert.state(!_instances.containsKey(type), '${type.getName()} has already been created');
				_isps[type] = isp as BootstrapInstanceSupplier<Object>;
			}
		});
	}

	@override
	bool isRegistered<T>(Class<T> type) {
		return synchronized(_isps, () {
			return _isps.containsKey(type);
		});
	}

	@override
	BootstrapInstanceSupplier<T> getSupplier<T>(Class<T> type) {
		return synchronized(_isps, () {
			return _isps[type] as BootstrapInstanceSupplier<T>;
		});
	}

	@override
	void addCloseListener(ApplicationEventListener<BootstrapContextClosedEvent> listener) {
		_eventBus.addApplicationListener(listener: listener);
	}

	@override
	T get<T>(Class<T> type, {T? orElse, Supplier<T>? orSupply}) {
    return synchronized(_isps, () {
      BootstrapInstanceSupplier<Object>? isp = _isps[type];

      if(orElse != null) {
        return isp != null ? _getInstance(type, isp) : orElse;
      } else if (orSupply != null) {
        return (isp != null) ? _getInstance(type, isp) : orSupply.call();
      } else {
        return getOrThrow(type, () => IllegalStateException("${type.getName()} has not been registered"));
      }
    });
	}

	@override
	T getOrThrow<T, X extends Throwable>(Class<T> type, Supplier<X> exceptionSupplier) {
		return synchronized(_isps, () {
			BootstrapInstanceSupplier<Object>? isp = _isps[type];
			if (isp == null) {
				throw exceptionSupplier.call();
			}
			return _getInstance(type, isp);
		});
	}

	/// Internal method for retrieving an instance from a registered supplier.
	///
	/// If the supplier scope is `SINGLETON`, the instance is cached.
	T _getInstance<T>(Class<T> type, BootstrapInstanceSupplier<Object> isp) {
		Object? instance = _instances[type];
		if (instance == null) {
			instance = isp.get(this);
			if (isp.scope == ScopeType.SINGLETON) {
				_instances[type] = instance;
			}
		}

		return instance as T;
	}

	@override
	void close(ConfigurableApplicationContext applicationContext) {
		_eventBus.onEvent(BootstrapContextClosedEvent(this, applicationContext));
    _eventBus.removeAllListeners();
	}
  
   @override
   bool isClassRegistered<T>(Class<T> type) {
     return synchronized(_isps, () {
       return _isps.containsKey(type);
     });
   }
}

/// {@template bootstrap_event_bus}
/// A minimal [ApplicationEventBus] implementation used during the bootstrap phase.
///
/// Unlike the fully featured event bus available after the application context
/// is refreshed, this implementation provides just enough functionality to:
///
/// - Register [ApplicationEventListener]s either directly or by pod name.
/// - Remove registered listeners.
/// - Dispatch [ApplicationEvent]s to all matching listeners.
///
/// This is useful in the early stages of application startup where dependency
/// injection and advanced facilities (like a `PodFactory`) may not yet be
/// available.
///
/// ### Example
/// ```dart
/// final eventBus = _BootstrapEventBus();
///
/// // Add a listener directly
/// eventBus.addApplicationListener(listener: StartupListener());
///
/// // Publish an event
/// eventBus.onEvent(AppStartedEvent());
///
/// // Remove all listeners
/// eventBus.removeAllListeners();
/// ```
///
/// Typically, `_BootstrapEventBus` is replaced by a more advanced event bus
/// (e.g., [SimpleApplicationEventBus]) once the application context has
/// been fully initialized.
/// {@endtemplate}
class _BootstrapEventBus extends ApplicationEventBus {
  final List<ApplicationEventListener> _listeners = [];
  final Map<String, ApplicationEventListener> _mappedListeners = {};

  /// {@macro bootstrap_event_bus}
  _BootstrapEventBus();

  @override
  Future<void> addApplicationListener({ApplicationEventListener<ApplicationEvent>? listener, String? podName}) async {
    if(podName != null && listener != null) {
      _mappedListeners.add(podName, listener);
    } else if(listener != null) {
      _listeners.add(listener);
    }
  }

  @override
  Future<void> removeApplicationListener({ApplicationEventListener<ApplicationEvent>? listener, String? podName}) async {
    if(podName != null && listener != null) {
      _mappedListeners.remove(podName);
    } else if(listener != null) {
      _listeners.remove(listener);
    }
  }

  @override
  Future<void> removeApplicationListeners({Predicate<ApplicationEventListener<ApplicationEvent>>? listener, Predicate<String>? podName}) async {
    if(podName != null && listener != null) {
      _mappedListeners.entries.process((v) {
        if(podName(v.key) && listener(v.value)) {
          _mappedListeners.remove(v.key);
        }
      });
    } else if(listener != null) {
      _listeners.process((v) {
        if(listener(v)) {
          _listeners.remove(v);
        }
      });
    }
  }

  @override
  Future<void> removeAllListeners() async {
    _mappedListeners.clear();
    _listeners.clear();
  }

  @override
  Future<void> onEvent(ApplicationEvent event) async {
    if(_mappedListeners.isNotEmpty) {
      _mappedListeners.entries.process((m) {
        if(m.value.supportsEventOf(event)) {
          m.value.onApplicationEvent(event);
        }
      });
    }

    if(_listeners.isNotEmpty) {
      _listeners.process((l) {
        if(l.supportsEventOf(event)) {
          l.onApplicationEvent(event);
        }
      });
    }
  }
}

/// {@template bootstrap_context_closed_event}
/// An [ApplicationEvent] published when the [BootstrapContext] is closed,
/// typically just before or during the early phase of starting a full
/// [ConfigurableApplicationContext].
///
/// This event signals that the bootstrap phase is complete and allows
/// interested listeners to perform cleanup, finalize preparation, or transition
/// to the full application context.
///
/// Example:
/// ```dart
/// class MyListener implements ApplicationListener<BootstrapContextClosedEvent> {
///   @override
///   void onApplicationEvent(BootstrapContextClosedEvent event) {
///     final bootstrap = event.getBootstrapContext();
///     final appContext = event.getApplicationContext();
///     print("Bootstrap context closed, switching to: $appContext");
///   }
/// }
/// ```
/// {@endtemplate}
class BootstrapContextClosedEvent extends ApplicationEvent {
  /// The [ConfigurableApplicationContext] prepared after bootstrap.
  final ConfigurableApplicationContext applicationContext;

  /// {@macro bootstrap_context_closed_event}
  ///
  /// Creates a new event that indicates the [source] bootstrap context
  /// has been closed and [applicationContext] is now in use.
  BootstrapContextClosedEvent(BootstrapContext super.source, this.applicationContext);

  /// {@template get_bootstrap_context}
  /// Returns the [BootstrapContext] that was closed.
  ///
  /// Example:
  /// ```dart
  /// final bootstrap = event.getBootstrapContext();
  /// ```
  /// {@endtemplate}
  BootstrapContext getBootstrapContext() => getSource() as BootstrapContext;

  /// {@template get_application_context}
  /// Returns the full [ConfigurableApplicationContext] that will be used
  /// after the bootstrap phase.
  ///
  /// Example:
  /// ```dart
  /// final ctx = event.getApplicationContext();
  /// ctx.refresh();
  /// ```
  /// {@endtemplate}
  ConfigurableApplicationContext getApplicationContext() => applicationContext;

  @override
  String getPackageName() => PackageNames.MAIN;
}