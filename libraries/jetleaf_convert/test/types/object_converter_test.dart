import 'package:jetleaf_convert/convert.dart';
import 'package:jetleaf_lang/lang.dart';
import 'package:test/test.dart';

import '../_test_models.dart';

@JetleafTest()
void main() {
  final service = DefaultConversionService();

  group('Object Converter Tests', () {
    group('Map to User Conversion', () {
      test('should convert simple user map to User object', () {
        final userMap = {
          'name': 'John Doe',
          'age': 30,
          'email': 'john@example.com',
          'isActive': true,
        };

        final result = service.convertTo(userMap, Class<User>());
        
        expect(result is User, isTrue);
        expect((result as User).name, 'John Doe');
        expect(result.age, 30);
        expect(result.email, 'john@example.com');
        expect(result.isActive, true);
      });

      test('should handle missing optional fields with defaults', () {
        final userMap = {
          'name': 'Jane Smith',
          'age': 25,
          'email': 'jane@example.com',
          // isActive is missing, should default to true
        };

        final result = service.convertTo(userMap, Class<User>());
        
        expect(result is User, isTrue);
        expect((result as User).name, 'Jane Smith');
        expect(result.isActive, true);
      });

      test('should throw exception for missing required fields', () {
        final incompleteMap = {
          'name': 'Incomplete User',
          // missing age and email
        };

        expect(() => service.convertTo(incompleteMap, Class<User>()),
            throwsA(isA<ConversionFailedException>()));
      });
    });

    group('Map to Address Conversion', () {
      test('should convert address map to Address object', () {
        final addressMap = {
          'street': '123 Main St',
          'city': 'Anytown',
          'state': 'CA',
          'zipCode': '12345',
          'country': 'USA',
        };

        final result = service.convertTo(addressMap, Class<Address>());
        
        expect(result is Address, isTrue);
        expect((result as Address).street, '123 Main St');
        expect(result.city, 'Anytown');
        expect(result.state, 'CA');
        expect(result.zipCode, '12345');
        expect(result.country, 'USA');
      });

      test('should use default country when not provided', () {
        final addressMap = {
          'street': '456 Oak Ave',
          'city': 'Springfield',
          'state': 'IL',
          'zipCode': '62701',
          // country is missing, should default to 'USA'
        };

        final result = service.convertTo(addressMap, Class<Address>());

        expect(result is Address, isTrue);
        expect((result as Address).country, 'USA');
      });
    });

    group('Map to House Conversion (with nested objects)', () {
      test('should convert complex house map with furniture list', () {
        final houseMap = {
          'address': '789 Pine Street',
          'bedrooms': 3,
          'bathrooms': 2,
          'squareFootage': 1500.5,
          'furniture': [
            {
              'name': 'Living Room Sofa',
              'type': 'Seating',
              'price': 899.99,
              'material': 'Leather',
            },
            {
              'name': 'Dining Table',
              'type': 'Table',
              'price': 450.00,
              'material': 'Oak',
            },
            {
              'name': 'Queen Bed',
              'type': 'Bed',
              'price': 1200.00,
              'material': 'Mahogany',
            },
          ],
          'location': {
            'street': '789 Pine Street',
            'city': 'Portland',
            'state': 'OR',
            'zipCode': '97201',
            'country': 'USA',
          },
        };

        final result = service.convertTo(houseMap, Class<House>());
        
        expect(result is House, isTrue);
        expect((result as House).address, '789 Pine Street');
        expect(result.bedrooms, 3);
        expect(result.bathrooms, 2);
        expect(result.squareFootage, 1500.5);
        expect(result.furniture.length, 3);
        
        // Check first furniture item
        expect(result.furniture[0].name, 'Living Room Sofa');
        expect(result.furniture[0].type, 'Seating');
        expect(result.furniture[0].price, 899.99);
        expect(result.furniture[0].material, 'Leather');
        
        // Check location
        expect(result.location.street, '789 Pine Street');
        expect(result.location.city, 'Portland');
        expect(result.location.state, 'OR');
      });

      test('should handle empty furniture list', () {
        final houseMap = {
          'address': '100 Empty St',
          'bedrooms': 1,
          'bathrooms': 1,
          'squareFootage': 800.0,
          'furniture': <Map<String, dynamic>>[],
          'location': {
            'street': '100 Empty St',
            'city': 'Minimalist City',
            'state': 'CA',
            'zipCode': '90210',
          },
        };

        final result = service.convertTo(houseMap, Class<House>());
        expect(result is House, isTrue);
        expect((result as House).furniture, isEmpty);
      });
    });

    group('Map to Company Conversion (complex nested)', () {
      test('should convert company map with employee list and metadata', () {
        final companyMap = {
          'name': 'Tech Innovations Inc',
          'employees': [
            {
              'name': 'Alice Johnson',
              'age': 28,
              'email': 'alice@techinnovations.com',
              'isActive': true,
            },
            {
              'name': 'Bob Wilson',
              'age': 35,
              'email': 'bob@techinnovations.com',
              'isActive': false,
            },
          ],
          'headquarters': {
            'street': '1000 Innovation Blvd',
            'city': 'San Francisco',
            'state': 'CA',
            'zipCode': '94105',
            'country': 'USA',
          },
          'metadata': {
            'founded': 2015,
            'industry': 'Technology',
            'revenue': 50000000,
            'publiclyTraded': false,
          },
        };

        final result = service.convertTo(companyMap, Class<Company>());
        
        expect(result is Company, isTrue);
        expect((result as Company).name, 'Tech Innovations Inc');
        expect(result.employees.length, 2);
        expect(result.employees[0].name, 'Alice Johnson');
        expect(result.employees[1].isActive, false);
        expect(result.headquarters.city, 'San Francisco');
        expect(result.metadata['founded'], 2015);
        expect(result.metadata['industry'], 'Technology');
      });
    });

    group('Object to Map Conversion', () {
      test('should convert User object back to map', () {
        final user = User(
          name: 'Test User',
          age: 42,
          email: 'test@example.com',
          isActive: false,
        );

        final result = service.convertTo(user, Class<Map<String, dynamic>>());
        
        expect(result is Map, isTrue);
        expect((result as Map)['name'], 'Test User');
        expect(result['age'], 42);
        expect(result['email'], 'test@example.com');
        expect(result['isActive'], false);
      });

      test('should convert House object with nested objects back to map', () {
        final house = House(
          address: 'Test Address',
          bedrooms: 2,
          bathrooms: 1,
          squareFootage: 1000.0,
          furniture: [
            Furniture(name: 'Test Chair', type: 'Seating', price: 100.0, material: 'Wood'),
          ],
          location: Address(
            street: 'Test Street',
            city: 'Test City',
            state: 'TS',
            zipCode: '12345',
          ),
        );

        final result = service.convertTo(house, Class<Map<String, dynamic>>());
        
        expect(result is Map, isTrue);
        expect((result as Map)['address'], 'Test Address');
        expect(result['bedrooms'], 2);
        expect(result['bathrooms'], 1);
        expect(result['squareFootage'], 1000.0);
        expect(result['furniture'], isA<List>());
        expect((result['furniture'] as List).length, 1);
      });
    });

    group('List of Objects Conversion', () {
      test('should convert list of maps to list via ObjectToObjectConverter', () {
        final userMaps = [
          {
            'name': 'User 1',
            'age': 25,
            'email': 'user1@example.com',
            'isActive': true,
          },
          {
            'name': 'User 2',
            'age': 30,
            'email': 'user2@example.com',
            'isActive': false,
          },
        ];

        final result = service.convertTo(userMaps, Class<List>());
        
        expect(result, isA<List>());
        expect((result as List).length, 2);
      });

      test('should convert list of User objects to list of maps', () {
        final users = [
          User(name: 'User A', age: 20, email: 'a@example.com'),
          User(name: 'User B', age: 25, email: 'b@example.com'),
        ];

        final result = service.convertTo(users, Class<List>());
        
        expect(result, isA<List>());
        expect((result as List).length, 2);
      });
    });

    group('Error Handling for Object Conversion', () {
      test('should throw exception for invalid object structure', () {
        final invalidMap = {
          'name': 'Invalid User',
          'age': 'not a number', // Invalid type
          'email': 'invalid@example.com',
        };

        expect(() => service.convertTo(invalidMap, Class<User>()),
            throwsA(isA<ConversionFailedException>()));
      });

      test('should throw exception for unsupported object type', () {
        final map = {'key': 'value'};
        
        expect(() => service.convertTo(map, Class<DateTime>()),
            throwsA(isA<Exception>()));
      });
    });
  });
}