import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_convert/src/helpers/_commons.dart';
import 'package:jetleaf_lang/lang.dart';

// --- Dummy Classes and Enums for Testing ---

enum TestEnum {
  value1,
  value2,
  value3,
}

class MyClass {
  final String name;
  final int age;

  MyClass(this.name, this.age);

  MyClass.fromMap(Map<String, dynamic> map)
      : name = map['name'] as String,
        age = map['age'] as int;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyClass && runtimeType == other.runtimeType && name == other.name && age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;

  @override
  String toString() => 'MyClass(name: $name, age: $age)';
}

class MySubClass extends MyClass {
  MySubClass(super.name, super.age);
}

class CustomConverter extends CommonConverter<String, int> {
  @override
  int convert(String source) {
    return int.parse(source) * 2;
  }
}

class CustomGenericConverter extends CommonPairedConverter {
  @override
  Set<ConvertiblePair>? getConvertibleTypes() {
    return {
      ConvertiblePair(Class<String>(), Class<bool>()),
    };
  }

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source is String && targetType.getType() == bool) {
      return source == 'yes';
    }
    return null;
  }
}

class CustomConverterFactory extends CommonConverterFactory<String, num> {
  @override
  Converter<String, T>? getConverter<T>(Class<T> targetType) {
    if (targetType.getType() == int) {
      return StringToIntConverter() as Converter<String, T>;
    } else if (targetType.getType() == double) {
      return StringToDoubleConverter() as Converter<String, T>;
    }
    return null;
  }
}

class StringToIntConverter extends CommonConverter<String, int> {
  @override
  int convert(String source) => int.parse(source);
}

class StringToDoubleConverter extends CommonConverter<String, double> {
  @override
  double convert(String source) => double.parse(source);
}

// Test model classes for object conversion
class User {
  final String name;
  final int age;
  final String email;
  final bool isActive;

  User({
    required this.name,
    required this.age,
    required this.email,
    this.isActive = true,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] as String,
      age: map['age'] as int,
      email: map['email'] as String,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'email': email,
      'isActive': isActive,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.name == name &&
        other.age == age &&
        other.email == email &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(name, age, email, isActive);
}

class Address {
  final String street;
  final String city;
  final String state;
  final String zipCode;
  final String country;

  Address({
    required this.street,
    required this.city,
    required this.state,
    required this.zipCode,
    this.country = 'USA',
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] as String,
      city: map['city'] as String,
      state: map['state'] as String,
      zipCode: map['zipCode'] as String,
      country: map['country'] as String? ?? 'USA',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'country': country,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.street == street &&
        other.city == city &&
        other.state == state &&
        other.zipCode == zipCode &&
        other.country == country;
  }

  @override
  int get hashCode => Object.hash(street, city, state, zipCode, country);
}

class Furniture {
  final String name;
  final String type;
  final double price;
  final String material;

  Furniture({
    required this.name,
    required this.type,
    required this.price,
    required this.material,
  });

  factory Furniture.fromMap(Map<String, dynamic> map) {
    return Furniture(
      name: map['name'] as String,
      type: map['type'] as String,
      price: (map['price'] as num).toDouble(),
      material: map['material'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'price': price,
      'material': material,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Furniture &&
        other.name == name &&
        other.type == type &&
        other.price == price &&
        other.material == material;
  }

  @override
  int get hashCode => Object.hash(name, type, price, material);
}

class House {
  final String address;
  final int bedrooms;
  final int bathrooms;
  final double squareFootage;
  final List<Furniture> furniture;
  final Address location;

  House({
    required this.address,
    required this.bedrooms,
    required this.bathrooms,
    required this.squareFootage,
    required this.furniture,
    required this.location,
  });

  factory House.fromMap(Map<String, dynamic> map) {
    return House(
      address: map['address'] as String,
      bedrooms: map['bedrooms'] as int,
      bathrooms: map['bathrooms'] as int,
      squareFootage: (map['squareFootage'] as num).toDouble(),
      furniture: (map['furniture'] as List<dynamic>)
          .map((item) => Furniture.fromMap(item as Map<String, dynamic>))
          .toList(),
      location: Address.fromMap(map['location'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'squareFootage': squareFootage,
      'furniture': furniture.map((f) => f.toMap()).toList(),
      'location': location.toMap(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is House &&
        other.address == address &&
        other.bedrooms == bedrooms &&
        other.bathrooms == bathrooms &&
        other.squareFootage == squareFootage &&
        _listEquals(other.furniture, furniture) &&
        other.location == location;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(address, bedrooms, bathrooms, squareFootage, furniture, location);
}

class Company {
  final String name;
  final List<User> employees;
  final Address headquarters;
  final Map<String, dynamic> metadata;

  Company({
    required this.name,
    required this.employees,
    required this.headquarters,
    required this.metadata,
  });

  factory Company.fromMap(Map<String, dynamic> map) {
    return Company(
      name: map['name'] as String,
      employees: (map['employees'] as List<dynamic>)
          .map((item) => User.fromMap(item as Map<String, dynamic>))
          .toList(),
      headquarters: Address.fromMap(map['headquarters'] as Map<String, dynamic>),
      metadata: Map<String, dynamic>.from(map['metadata'] as Map),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'employees': employees.map((e) => e.toMap()).toList(),
      'headquarters': headquarters.toMap(),
      'metadata': metadata,
    };
  }
}