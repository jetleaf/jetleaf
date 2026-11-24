// ignore_for_file: unused_local_variable, deprecated_member_use_from_same_package

import 'package:test/test.dart';
import 'package:jetleaf_core/lang.dart';
import 'runtime_hint_implementations.dart';
import '../helpers/aot_test_setup.dart';

@JetleafTest()
void main() {
  ensureTestAotRegisteredSync();
  group('RuntimeHint Discovery and Registration', () {
    test('should find annotations that are RuntimeHints', () {
      final annotatedClass = Runtime.findClass<AnnotatedStringUser>();
      
      final annotations = annotatedClass.getAnnotations();
      
      // Should find StringRuntimeHintAnnotation annotation
      final hintAnnotations = annotations.where((a) {
        final instance = a.getInstance();
        return instance is RuntimeHint;
      }).toList();
      
      expect(hintAnnotations, isNotEmpty);
      expect(hintAnnotations.first.getInstance(), isA<StringRuntimeHintAnnotation>());
    });

    test('should find annotations that are RuntimeHintProviders', () {
      final annotatedClass = Runtime.findClass<AnnotatedIntUser>();
      
      final annotations = annotatedClass.getAnnotations();
      
      final providerAnnotations = annotations.where((a) {
        final instance = a.getInstance();
        return instance is RuntimeHintProvider;
      }).toList();
      
      expect(providerAnnotations, isNotEmpty);
      expect(providerAnnotations.first.getInstance(), isA<IntRuntimeHintProviderAnnotation>());
    });
  });

  group('RuntimeHintDescriptor Resolution', () {
    test('should not instantiate abstract RuntimeHint classes', () {
      final abstractClass = Runtime.findClassByType(AbstractRuntimeHintClass);
      
      expect(abstractClass.getIsAbstract(), isTrue);
    });
  });

  group('RuntimeHint Integration with ClassDeclaration', () {
    test('ClassDeclaration.newInstance should use RuntimeHint if available', () {
      final userClass = Runtime.findClass<User>();
      
      // Create a User instance through reflection
      final instance = userClass.newInstance({
        'name': 'John',
        'age': 30,
      });
      
      expect(instance, isA<User>());
      final user = instance as User;
      expect(user.name, equals('John'));
      expect(user.age, equals(30));
    });

    test('MethodDeclaration.invoke should use RuntimeHint for method calls', () {
      final userClass = Runtime.findClass<User>();
      
      final instance = User('Alice', 25);
      final methods = userClass.getMethods();
      
      final greetingMethod = methods.firstWhere((m) => m.getName() == 'greeting');
      final result = greetingMethod.invoke(instance, {});
      
      expect(result, equals('Hello, Alice!'));
    });

    test('FieldDeclaration.getValue should use RuntimeHint for field access', () {
      final userClass = Runtime.findClass<User>();
      
      final instance = User('Bob', 35);
      final fields = userClass.getFields();
      
      final nameField = fields.firstWhere((f) => f.getName() == 'name');
      final nameValue = nameField.getValue(instance);
      
      expect(nameValue, equals('Bob'));
      
      final ageField = fields.firstWhere((f) => f.getName() == 'age');
      final ageValue = ageField.getValue(instance);
      
      expect(ageValue, equals(35));
    });

    test('should handle String operations with RuntimeHint', () {
      // The AOT runtime does not enumerate SDK methods; SDK types are
      // reached through runtime hints. The String hint executes operations
      // registered for it.
      const hint = StringRuntimeHint();
      expect(hint.obtainTypeOfRuntimeHint(), equals(String));

      final result = hint.invokeMethod<String>(
        'Hello World',
        'toUpperCase',
        ExecutableArgument.unmodified(const {}, const []),
      );

      expect(result.getIsExecuted(), isTrue);
      expect(result.getResult(), equals('HELLO WORLD'));
    });

    test('should handle int operations with RuntimeHint', () {
      // Same contract for int: SDK invocation is limited to operations a
      // registered hint covers.
      const hint = IntRuntimeHint();
      expect(hint.obtainTypeOfRuntimeHint(), equals(int));

      final absResult = hint.invokeMethod<int>(
        -42,
        'abs',
        ExecutableArgument.unmodified(const {}, const []),
      );
      expect(absResult.getIsExecuted(), isTrue);
      expect(absResult.getResult(), equals(42));

      final toStringResult = hint.invokeMethod<int>(
        42,
        'toString',
        ExecutableArgument.unmodified(const {}, const []),
      );
      expect(toStringResult.getIsExecuted(), isTrue);
      expect(toStringResult.getResult(), equals('42'));
    });
  });

  group('RuntimeHint Edge Cases', () {
    test('should handle RuntimeHintProvider creating RuntimeHint', () {
      final provider = ComplexRuntimeHintProvider();
      final hint = provider.createHint();
      
      expect(hint, isA<ComplexRuntimeHint>());
      expect(hint.obtainTypeOfRuntimeHint(), equals(Map));
    });

    test('should handle annotation-based RuntimeHintProvider', () {
      final provider = IntRuntimeHintProviderAnnotation();
      final hint = provider.createHint();
      
      expect(hint, isA<VerboseIntRuntimeHint>());
    });
  });

  group('RuntimeHint Execution Flow', () {
    test('should demonstrate hint execution chain', () {
      // Create a hint descriptor and add our hints
      final descriptor = DefaultRuntimeHintDescriptor();
      descriptor.addHint(const StringRuntimeHint());
      descriptor.addHint(const IntRuntimeHint());
      descriptor.addHint(const UserRuntimeHint());
      
      // Get hints from descriptor
      final stringHint = descriptor.getHint<String>();
      expect(stringHint, isNotNull);
      expect(stringHint!.obtainTypeOfRuntimeHint(), equals(String));
      
      final intHint = descriptor.getHint<int>();
      expect(intHint, isNotNull);
      expect(intHint!.obtainTypeOfRuntimeHint(), equals(int));
      
      final userHint = descriptor.getHint<User>();
      expect(userHint, isNotNull);
      expect(userHint!.obtainTypeOfRuntimeHint(), equals(User));
    });

    test('should show hint iteration', () {
      final descriptor = DefaultRuntimeHintDescriptor();
      descriptor.addHint(const StringRuntimeHint());
      descriptor.addHint(const IntRuntimeHint());
      descriptor.addHint(const UserRuntimeHint());
      
      final hints = descriptor.toList();
      expect(hints.length, equals(3));
      
      final hintTypes = hints.map((h) => h.obtainTypeOfRuntimeHint()).toList();
      expect(hintTypes, contains(String));
      expect(hintTypes, contains(int));
      expect(hintTypes, contains(User));
    });
  });
}