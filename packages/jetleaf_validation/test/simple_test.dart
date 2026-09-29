import 'package:test/test.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:jetleaf_validation/jetleaf_validation.dart';

void main() {
  group('Annotations', () {
    test('Email annotation', () {
      const email = Email();
      expect(email.getMessage(), 'must be a valid email address');
      expect(email.annotationType, Email);
    });

    test('InFuture annotation', () {
      const inFuture = InFuture();
      expect(inFuture.getMessage(), 'must be a future date');
      expect(inFuture.annotationType, InFuture);
    });

    test('Size annotation', () {
      const size = Size(min: 3, max: 20);
      expect(size.min, 3);
      expect(size.max, 20);
      expect(size.annotationType, Size);
    });

    test('Max annotation', () {
      const max = Max(100);
      expect(max.value, 100);
      expect(max.annotationType, Max);
    });

    test('Min annotation', () {
      const min = Min(1);
      expect(min.value, 1);
      expect(min.annotationType, Min);
    });

    test('Negative annotation', () {
      const negative = Negative();
      expect(negative.annotationType, Negative);
    });

    test('Positive annotation', () {
      const positive = Positive();
      expect(positive.annotationType, Positive);
    });

    test('NotBlank annotation', () {
      const notBlank = NotBlank();
      expect(notBlank.getMessage(), 'must not be blank');
      expect(notBlank.annotationType, NotBlank);
    });

    test('NotEmpty annotation', () {
      const notEmpty = NotEmpty();
      expect(notEmpty.getMessage(), 'must not be empty');
      expect(notEmpty.annotationType, NotEmpty);
    });

    test('NotNull annotation', () {
      const notNull = NotNull();
      expect(notNull.getMessage(), 'must not be null');
      expect(notNull.annotationType, NotNull);
    });

    test('InPast annotation', () {
      const inPast = InPast();
      expect(inPast.getMessage(), 'must be a past date');
      expect(inPast.annotationType, InPast);
    });

    test('Pattern annotation', () {
      const pattern = Pattern(r'^[a-z]+$');
      expect(pattern.regexp, r'^[a-z]+$');
      expect(pattern.annotationType, Pattern);
    });

    test('Valid annotation', () {
      const valid = Valid();
      expect(valid.annotationType, Valid);
    });

    test('Validated annotation', () {
      const validated = Validated();
      expect(validated.annotationType, Validated);
    });

    test('Constraint annotation', () {
      const constraint = Constraint([EmailConstraintValidator()]);
      expect(constraint.validators.length, 1);
      expect(constraint.annotationType, Constraint);
    });

    test('DefaultGroup', () {
      final clazz = DefaultGroup.getClass();
      expect(clazz.getName(), 'DefaultGroup');
    });
  });

  group('ValidationFactory', () {
    test('is a Validator', () {
      final factory = ValidationFactory();
      expect(factory, isA<Validator>());
    });

    test('is an ExecutableValidator', () {
      final factory = ValidationFactory();
      expect(factory, isA<ExecutableValidator>());
    });

    test('forExecutables returns itself', () {
      final factory = ValidationFactory();
      expect(factory.forExecutables(), same(factory));
    });
  });

  group('ValidationAutoConfiguration', () {
    test('has correct pod name', () {
      expect(
        ValidationAutoConfiguration.VALIDATION_AUTO_CONFIGURATION_POD_NAME,
        'jetleaf.validation.configuration',
      );
    });

    test('has correct factory pod name', () {
      expect(
        ValidationAutoConfiguration.VALIDATION_FACTORY_POD_NAME,
        'jetleaf.validation.factory',
      );
    });

    test('validationFactory returns ValidationFactory instance', () {
      const config = ValidationAutoConfiguration();
      final factory = config.validationFactory();
      expect(factory, isA<ValidationFactory>());
    });

    test('is const constructible', () {
      const config = ValidationAutoConfiguration();
      expect(config, isA<ValidationAutoConfiguration>());
    });
  });

  group('ConstraintViolationException', () {
    test('is a RuntimeException', () {
      final report = TestValidationReport();
      final exception = ConstraintViolationException(report);
      expect(exception, isA<RuntimeException>());
    });

    test('custom message overrides default', () {
      final report = TestValidationReport();
      final exception = ConstraintViolationException(report, message: 'Custom error');
      expect(exception.message, 'Custom error');
    });

    test('cause is stored when provided', () {
      final report = TestValidationReport();
      final cause = Exception('root cause');
      final exception = ConstraintViolationException(report, cause: cause);
      expect(exception.cause, cause);
    });
  });

  group('Annotation equality', () {
    test('same annotations are equal', () {
      const email1 = Email();
      const email2 = Email();
      expect(email1, equals(email2));
    });

    test('different messages are not equal', () {
      const email1 = Email(message: 'msg1');
      const email2 = Email(message: 'msg2');
      expect(email1, isNot(equals(email2)));
    });

    test('different patterns are not equal', () {
      const email1 = Email(pattern: r'^test@');
      const email2 = Email(pattern: r'^admin@');
      expect(email1, isNot(equals(email2)));
    });

    test('Size annotations with same params are equal', () {
      const size1 = Size(min: 3, max: 20);
      const size2 = Size(min: 3, max: 20);
      expect(size1, equals(size2));
    });

    test('Max annotations with same value are equal', () {
      const max1 = Max(100);
      const max2 = Max(100);
      expect(max1, equals(max2));
    });

    test('Min annotations with same value are equal', () {
      const min1 = Min(1);
      const min2 = Min(1);
      expect(min1, equals(min2));
    });
  });
}

// Simple test helper
class TestValidationReport implements ValidationReport {
  @override
  bool isValid() => true;

  @override
  Set<ConstraintViolation> getViolations() => {};

  @override
  Set<ConstraintViolation> getViolationsForProperty(String propertyPath) => {};

  @override
  String? getFirstViolationMessage() => null;

  @override
  List<Object?> equalizedProperties() => [];
}