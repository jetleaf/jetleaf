// ignore_for_file: avoid_print

import 'dart:async';

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_core/convert.dart';
import 'package:jetleaf_core/env.dart';
import 'package:jetleaf_core/lang.dart';
import 'package:jetleaf_core/logging.dart';
import 'package:jetleaf_core/pod.dart';
import 'package:jetleaf_core/property.dart';

// ============================================================================
// 1. DOMAIN MODELS & EVENTS
// ============================================================================

/// Domain entity representing an active user.
class User {
  final String id;
  final String email;
  final String role;

  const User({required this.id, required this.email, required this.role});

  @override
  String toString() => 'User(id: $id, email: $email, role: $role)';
}

/// Custom event dispatched over the Jetleaf event bus when a new user signs up.
class UserRegisteredEvent {
  final User user;
  final DateTime registeredAt;

  UserRegisteredEvent({required this.user, DateTime? registeredAt})
      : registeredAt = registeredAt ?? DateTime.now();

  @override
  String toString() =>
      'UserRegisteredEvent(user: ${user.email}, at: $registeredAt)';
}

// ============================================================================
// 2. POD SERVICES & LIFECYCLE HOOKS
// ============================================================================

/// Repository managing user data storage.
class UserRepository implements InitializingPod, DisposablePod {
  final Map<String, User> _storage = {};
  bool _initialized = false;

  @override
  String getPackageName() => 'jetleaf_core_example';

  @override
  Future<void> onReady() async {
    _initialized = true;
    _storage['usr_01'] = const User(
      id: 'usr_01',
      email: 'admin@jetleaf.dev',
      role: 'ADMIN',
    );
  }

  Future<User?> findById(String id) async => _storage[id];

  Future<User> save(User user) async {
    _storage[user.id] = user;
    return user;
  }

  int get count => _storage.length;

  @override
  Future<void> onDestroy() async {
    _storage.clear();
    _initialized = false;
  }

  bool get isInitialized => _initialized;
}

/// Service handling business workflows and dispatching lifecycle events.
class UserService implements InitializingPod {
  final UserRepository repository;
  final Environment environment;
  final List<void Function(UserRegisteredEvent)> _listeners = [];

  UserService({
    required this.repository,
    required this.environment,
  });

  @override
  String getPackageName() => 'jetleaf_core_example';

  void addListener(void Function(UserRegisteredEvent) listener) {
    _listeners.add(listener);
  }

  @override
  Future<void> onReady() async {
    assert(repository.isInitialized, 'Repository must be initialized');
  }

  Future<User> registerUser(String id, String email, String role) async {
    final user = User(id: id, email: email, role: role);
    final saved = await repository.save(user);

    final event = UserRegisteredEvent(user: saved);
    for (final listener in _listeners) {
      listener(event);
    }

    return saved;
  }

  Future<User?> getUser(String id) => repository.findById(id);
}

// ============================================================================
// 3. MAIN ENTRYPOINT: BOOTSTRAP & DEMONSTRATION
// ============================================================================

void main() async {
  final log = Logger(name: 'JetleafCoreExample');
  log.info('========================================================');
  log.info('  🍃 Jetleaf Core 2.0.0 Feature Showcase');
  log.info('========================================================');

  // --- A. Environment & Property Resolution ---
  log.info('\n[1] Environment Subsystem:');
  final env = ApplicationEnvironment();
  env.getPropertySources().addLast(MapPropertySource('app-config', {
    'app.name': 'Jetleaf Demo',
    'app.timeout': '00:05',
    'app.max_users': 100,
  }));

  final appName = env.getProperty('app.name', 'Unknown');
  final maxUsers = env.getPropertyAs<int>('app.max_users', Class<int>(), 10);
  log.info('  App Name: $appName');
  log.info('  Max Users: $maxUsers');

  // --- B. Type Conversion Service ---
  log.info('\n[2] Conversion Subsystem:');
  final conversionService = DefaultConversionService();
  final timeoutStr = env.getProperty('app.timeout', '00:01')!;
  final parsedDuration = conversionService.convert(timeoutStr, Class<Duration>());
  log.info('  Converted "$timeoutStr" -> ${parsedDuration?.inMilliseconds} ms');

  // --- C. Pod Factory & Dependency Injection ---
  log.info('\n[3] Inversion of Control & Pod Factory:');
  final podFactory = DefaultListablePodFactory();

  // Register UserRepository definition
  await podFactory.registerDefinition('userRepository', RootPodDefinition(
    type: Class<UserRepository>(),
    instanceSupplier: (factory) => UserRepository(),
  ));

  // Register UserService definition with constructor injection
  await podFactory.registerDefinition('userService', RootPodDefinition(
    type: Class<UserService>(),
    instanceSupplier: (factory) async {
      final repo = await factory.getPod('userRepository');
      return UserService(
        repository: repo as UserRepository,
        environment: env,
      );
    },
  ));

  // Pre-instantiate singletons & trigger InitializingPod.onReady()
  await podFactory.preInstantiateSingletons();

  // Retrieve UserService pod
  final userService = (await podFactory.getPod('userService')) as UserService;
  final userRepository = (await podFactory.getPod('userRepository')) as UserRepository;

  log.info('  UserRepository seeded with count: ${userRepository.count}');

  // --- D. Event-Driven Workflow ---
  log.info('\n[4] Event Subsystem:');
  userService.addListener((event) {
    log.info('  [AUDIT] Event captured: ${event.user.email} (Role: ${event.user.role})');
  });

  // Execute business operation
  log.info('  Registering new user...');
  final newUser = await userService.registerUser('usr_02', 'developer@jetleaf.dev', 'DEVELOPER');
  log.info('  Successfully saved: $newUser');
  log.info('  Total repository count: ${userRepository.count}');

  // --- E. Graceful Shutdown & Disposal ---
  log.info('\n[5] Lifecycle Disposal:');
  await podFactory.destroySingletons();
  log.info('  Singletons destroyed. Repository count: ${userRepository.count}');

  log.info('\n========================================================');
  log.info('  ✅ All Jetleaf Core subsystems completed successfully!');
  log.info('========================================================');
}
