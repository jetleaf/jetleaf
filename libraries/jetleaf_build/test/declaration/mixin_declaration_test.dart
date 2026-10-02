import 'package:test/test.dart';
import 'package:jetleaf_build/jetleaf_build.dart';

// Base classes for mixin constraints
abstract class BaseModel {
  String get id;
  DateTime get createdAt;
}

abstract class Disposable {
  void dispose();
}

abstract class Serializable {
  Map<String, dynamic> toJson();
}

// Simple mixin
mixin TimestampMixin {
  DateTime? _createdAt;
  DateTime? _updatedAt;
  
  DateTime? get createdAt => _createdAt;
  DateTime? get updatedAt => _updatedAt;
  
  void updateTimestamp() {
    _updatedAt = DateTime.now();
    _createdAt ??= _updatedAt;
  }
}

// Mixin with constraints
mixin LoggingMixin on BaseModel {
  void log(String message) {
    print('[$id] $message at ${DateTime.now()}');
  }
  
  String get debugInfo => '$id created at $createdAt';
}

// Generic mixin
@Generic(GenericMixin)
mixin GenericMixin<T> {
  final List<T> _items = [];
  
  void addItem(T item) {
    _items.add(item);
  }
  
  List<T> get items => List.unmodifiable(_items);
  
  bool contains(T item) => _items.contains(item);
}

// Mixin with multiple constraints
mixin AdvancedMixin on BaseModel implements Disposable, Serializable {
  bool _isDisposed = false;
  
  @override
  void dispose() {
    _isDisposed = true;
    print('$id disposed');
  }
  
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'isDisposed': _isDisposed,
    };
  }
  
  bool get isDisposed => _isDisposed;
}

// Mixin with static members
mixin StaticMixin {
  static int instanceCount = 0;
  static const String MIXIN_NAME = 'StaticMixin';
  
  static void incrementCount() {
    instanceCount++;
  }
  
  String get mixinInfo => '$MIXIN_NAME (instances: $instanceCount)';
}

// Mixin with private members
mixin PrivateMixin {
  final String _privateData = 'secret';
  
  String get publicData => _privateData.toUpperCase();
  
  void _privateMethod() {
    print('Private method called');
  }
  
  void publicMethod() {
    _privateMethod();
    print('Public method: $publicData');
  }
}

// Classes using mixins
class MixinUser with TimestampMixin, GenericMixin<String> {
  final String id;
  final String name;
  
  MixinUser(this.id, this.name) {
    updateTimestamp();
  }
}

class Product extends BaseModel with LoggingMixin, AdvancedMixin {
  @override
  final String id;
  @override
  final DateTime createdAt;
  final String name;
  final double price;
  
  Product(this.id, this.name, this.price) : createdAt = DateTime.now();
}

class Service with StaticMixin, PrivateMixin {
  final String serviceName;
  
  Service(this.serviceName);
  
  void run() {
    print('Running $serviceName');
    publicMethod();
  }
}

mixin class Base {}

// Mixin application class
class MixedClassMixin = Base with TimestampMixin, GenericMixin<int>;

// Constrained generic mixin
mixin ComparableMixin<T extends Comparable<T>> {
  int compareTo(T other);
  
  bool operator >(T other) => compareTo(other) > 0;
  bool operator <(T other) => compareTo(other) < 0;
  bool operator >=(T other) => compareTo(other) >= 0;
  bool operator <=(T other) => compareTo(other) <= 0;
}

@JetleafTest()
void main() async {
  group('MixinDeclaration Basic Properties', () {
    test('should identify TimestampMixin in runtime', () {
      final mixinClass = Runtime.findClassByName('TimestampMixin');
      expect(mixinClass, isNotNull);
      expect(mixinClass.getName(), equals('TimestampMixin'));
    });

    test('should identify GenericMixin in runtime', () {
      final mixinClass = Runtime.findClassByName('GenericMixin');
      expect(mixinClass, isNotNull);
      expect(mixinClass.getName(), equals('GenericMixin'));
    });

    test('should identify ComparableMixin in runtime', () {
      final mixinClass = Runtime.findClassByName('ComparableMixin');
      expect(mixinClass, isNotNull);
      expect(mixinClass.getName(), equals('ComparableMixin'));
    });
  });

  group('MixinDeclaration Usage in Classes', () {
    test('should find classes that use mixins', () {
      final userClass = Runtime.findClass<MixinUser>();
      
      expect(userClass, isNotNull);
      expect(userClass.getName(), equals('MixinUser'));
    });

    test('should find Product class with multiple mixins', () {
      final productClass = Runtime.findClass<Product>();
      
      expect(productClass, isNotNull);
      expect(productClass.getName(), equals('Product'));
    });

    test('should find Service class', () {
      final serviceClass = Runtime.findClass<Service>();
      
      expect(serviceClass, isNotNull);
      expect(serviceClass.getName(), equals('Service'));
    });
  });

  group('MixinDeclaration Concrete Usage', () {
    test('should instantiate MixinUser and use mixed-in methods', () {
      final user = MixinUser('u1', 'Alice');
      expect(user.name, equals('Alice'));
      expect(user.id, equals('u1'));
      
      // Method from TimestampMixin
      user.updateTimestamp();
      expect(user.createdAt, isNotNull);
      expect(user.updatedAt, isNotNull);
      
      // Method from GenericMixin
      user.addItem('item1');
      user.addItem('item2');
      expect(user.items, equals(['item1', 'item2']));
      expect(user.contains('item1'), isTrue);
      expect(user.contains('missing'), isFalse);
    });

    test('should instantiate Product and use mixin methods', () {
      final product = Product('p1', 'Widget', 9.99);
      expect(product.name, equals('Widget'));
      expect(product.price, equals(9.99));
      
      // From AdvancedMixin
      expect(product.isDisposed, isFalse);
      final json = product.toJson();
      expect(json['id'], equals('p1'));
      expect(json['isDisposed'], isFalse);
      
      // From Disposable
      product.dispose();
      expect(product.isDisposed, isTrue);
    });

    test('should handle StaticMixin static members', () {
      final initialCount = StaticMixin.instanceCount;
      StaticMixin.incrementCount();
      expect(StaticMixin.instanceCount, equals(initialCount + 1));
      expect(StaticMixin.MIXIN_NAME, equals('StaticMixin'));
    });

    test('should handle PrivateMixin', () {
      final service = Service('myService');
      expect(service.publicData, equals('SECRET'));
      expect(service.serviceName, equals('myService'));
    });
  });

  group('MixinDeclaration MixedClassMixin', () {
    test('should instantiate MixedClassMixin', () {
      final instance = MixedClassMixin();
      expect(instance, isNotNull);
    });
  });

  group('MixinDeclaration Generic Mixins', () {
    test('should handle generic mixin in class', () {
      final user = MixinUser('u2', 'Bob');
      
      // GenericMixin<String> - addItem only accepts String
      user.addItem('hello');
      expect(user.items, contains('hello'));
    });
  });
}
