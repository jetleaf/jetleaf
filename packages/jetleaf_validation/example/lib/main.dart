// ignore_for_file: avoid_print

import 'package:jetleaf_core/context.dart';
import 'package:jetleaf_validation/jetleaf_validation.dart';

void main() {
  print('========================================================');
  print('  🍃 Jetleaf Validation 2.0.0 Engine Showcase');
  print('========================================================\n');

  final context = SimpleValidationContext(ApplicationEnvironment());

  // 1. Inspecting Declarative Constraints
  print('[1] Declarative Constraint Annotations:');
  const emailConstraint = Email(message: 'Invalid user email address');
  print('Email Annotation: message="${emailConstraint.getMessage()}"');

  const sizeConstraint = Size(min: 8, max: 64, message: 'Password must be 8-64 characters');
  print('Size Annotation: min=${sizeConstraint.min}, max=${sizeConstraint.max}');

  const ageConstraint = Min(18, message: 'Must be at least 18 years of age');
  print('Min Annotation: value=${ageConstraint.value}\n');

  // 2. Constraint Validator Execution
  print('[2] Direct Constraint Validator Execution:');
  const emailValidator = EmailConstraintValidator();

  final validEmail = emailValidator.isValid('developer@jetleaf.dev', emailConstraint, context);
  final invalidEmail = emailValidator.isValid('not-an-email', emailConstraint, context);

  print('Validating "developer@jetleaf.dev": is valid = $validEmail');
  print('Validating "not-an-email": is valid = $invalidEmail\n');

  // 3. String & Size Validation
  print('[3] NotBlank & Size Validation:');
  const notBlankValidator = NotBlankConstraintValidator();
  final validNotBlank = notBlankValidator.isValid('Jetleaf Server', const NotBlank(), context);
  final blankTest = notBlankValidator.isValid('   ', const NotBlank(), context);
  print('Validating "Jetleaf Server": is valid = $validNotBlank');
  print('Validating "   ": is valid = $blankTest');

  print('\n========================================================');
  print('  ✅ Jetleaf Validation Example executed successfully!');
  print('========================================================');
}