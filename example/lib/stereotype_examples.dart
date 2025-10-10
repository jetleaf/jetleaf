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

// ----------------------------------------------------------------------------------------------------------
// COMPONENTS
// ----------------------------------------------------------------------------------------------------------

import 'package:jetleaf/jetleaf.dart';
import 'common_infrastructure.dart';

@Component()
class EmailProvider {
  Future<void> send({required String to, required String subject, required String body}) async {
    print("Sending email to $to: $subject");
  }
}

final class ValidationError {
  final String field;
  final String message;
  final String rejectedValue;
  final String validationType;

  ValidationError({
    required this.field,
    required this.message,
    required this.rejectedValue,
    required this.validationType,
  });
}

abstract interface class Validator<T> {
  List<ValidationError> validate(T value, String fieldName);
  bool supports(Type type);
}

@Component('customValidator')
class CustomValidator implements Validator<String> {
  @override
  List<ValidationError> validate(String value, String fieldName) {
    final errors = <ValidationError>[];
    if (value.contains('forbidden')) {
      errors.add(ValidationError(
        field: fieldName,
        message: 'Forbidden content detected',
        rejectedValue: value,
        validationType: 'CustomValidator',
      ));
    }
    return errors;
  }

  @override
  bool supports(Type type) => type == String;
}

// ----------------------------------------------------------------------------------------------------------
// SERVICE
// ----------------------------------------------------------------------------------------------------------

@Service()
class EmailService {
  late final EmailProvider emailProvider;

  EmailService();

  Future<void> sendWelcomeEmail(String email) async {
    await emailProvider.send(
      to: email,
      subject: 'Welcome!',
      body: 'Welcome to our application!',
    );
  }

  Future<void> sendGoodbyeEmail(String email) async {
    await emailProvider.send(
      to: email,
      subject: 'Goodbye!',
      body: "We're sorry to see you go!",
    );
  }
}

@Service()
@RequiredAll()
class StereotypeUserService {
  late final UserRepository userRepository;
  late final EmailService emailService;

  StereotypeUserService();

  Future<List<User>> findAll() => userRepository.findAll();

  Future<User> createUser(String name, String email) async {
    final user = User(name: name, email: email);
    final saved = await userRepository.save(user);
    await emailService.sendWelcomeEmail(saved.email);
    return saved;
  }
}

// ----------------------------------------------------------------------------------------------------------
// REPOSITORY
// ----------------------------------------------------------------------------------------------------------

@Repository()
@RequiredAll()
class UserRepository {
  late final Database database;

  UserRepository();

  Future<List<User>> findAll() async {
    return database.query('SELECT * FROM users');
  }

  Future<User> save(User user) async {
    await database.execute('INSERT INTO users (name, email) VALUES (?, ?)', [user.name, user.email]);
    return user;
  }
}

// ----------------------------------------------------------------------------------------------------------
// CONTROLLER
// ----------------------------------------------------------------------------------------------------------

@RequiredAll()
@Controller('/users')
class UserController {
  late final StereotypeUserService userService;

  UserController();

  Future<List<User>> listUsers() async => userService.findAll();

  Future<User> createUser(Map<String, dynamic> body) async {
    return userService.createUser(body['name'], body['email']);
  }
}

// ----------------------------------------------------------------------------------------------------------
// COMPONENT SCAN
// ----------------------------------------------------------------------------------------------------------

@Configuration()
@ComponentScan(
  basePackages: ['com.example.app.services', 'com.example.app.repositories'],
  includeFilters: [
    ComponentScanFilter(type: FilterType.ANNOTATION, classes: [ClassType<Service>(), ClassType<Repository>()]),
  ],
  excludeFilters: [
    ComponentScanFilter(type: FilterType.REGEX, pattern: '.*Internal.*'),
  ],
)
class ApplicationConfig {}