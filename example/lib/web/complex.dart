import 'package:jetleaf_web/jetleaf_web.dart';

class Address {
  final String street;
  final String city;
  final String zip;

  Address({required this.street, required this.city, required this.zip});

  Map<String, dynamic> toJson() => {
        "street": street,
        "city": city,
        "zip": zip,
      };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        street: json["street"],
        city: json["city"],
        zip: json["zip"],
      );
}

class Tenant {
  final String name;
  final int age;

  Tenant({required this.name, required this.age});

  Map<String, dynamic> toJson() => {
        "name": name,
        "age": age,
      };

  factory Tenant.fromJson(Map<String, dynamic> json) => Tenant(
        name: json["name"],
        age: json["age"],
      );
}

@FromJson(Home.from)
class Home {
  final String id;
  final String owner;
  final Address address;
  final List<Tenant> tenants;

  Home({
    required this.id,
    required this.owner,
    required this.address,
    required this.tenants,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "owner": owner,
        "address": address.toJson(),
        "tenants": tenants.map((t) => t.toJson()).toList(),
      };

  factory Home.fromJson(Map<String, dynamic> json) => Home(
        id: json["id"],
        owner: json["owner"],
        address: Address.fromJson(json["address"]),
        tenants: (json["tenants"] as List<dynamic>)
            .map((t) => Tenant.fromJson(t))
            .toList(),
      );

  factory Home.from(Map<String, dynamic> json) {
    return Home(
        id: json["id"],
        owner: json["owner"],
        address: json["address"],
        tenants: (json["tenants"] as List<Object>)
            .map((t) {
              print(t);
              return t as Tenant;
            })
            .toList(),
      );
  }

  Home copyWith({String? id}) => Home(id: id ?? this.id, owner: owner, address: address, tenants: tenants);
}

@RestController("/homes")
class HomeController {
  /// POST `/homes`
  ///
  /// Demonstrates nested request body:
  /// ```json
  /// {
  ///   "id": "H001",
  ///   "owner": "Alice",
  ///   "address": { "street": "123 Elm", "city": "Denver", "zip": "80202" },
  ///   "tenants": [
  ///     { "name": "Bob", "age": 29 },
  ///     { "name": "Charlie", "age": 35 }
  ///   ]
  /// }
  /// ```
  @PostMapping()
  Future<ResponseBody<Home>> createHome(@RequestBody() Home home) async {
    // Example processing
    final saved = home.copyWith(id: "H-${DateTime.now().millisecondsSinceEpoch}");
    return ResponseBody.of(HttpStatus.CREATED, saved);
  }

  /// GET `/homes/{id}`
  ///
  /// Returns a nested response object with full data hierarchy.
  @GetMapping(path: "/{id}")
  Future<ResponseBody<Home>> getHome(@PathVariable() String id) async {
    final home = Home(
      id: id,
      owner: "Frank",
      address: Address(street: "42 Jetleaf Ave", city: "Lagos", zip: "12345"),
      tenants: [
        Tenant(name: "James", age: 32),
        Tenant(name: "Lydia", age: 28),
      ],
    );

    return ResponseBody.of(HttpStatus.OK, home);
  }

  /// PUT `/homes/{id}`
  ///
  /// Demonstrates updating nested objects.
  @PutMapping(path: "/{id}")
  Future<ResponseBody<Home>> updateHome(
    @PathVariable() String id,
    @RequestBody() Home updatedHome,
  ) async {
    // Here you might merge old and new data
    final merged = updatedHome.copyWith(id: id);
    return ResponseBody.of(HttpStatus.OK, merged);
  }

  /// GET `/homes/list`
  ///
  /// Demonstrates a list response of complex objects.
  @GetMapping(path: "/list")
  Future<ResponseBody<List<Home>>> listHomes() async {
    final homes = [
      Home(
        id: "H100",
        owner: "Alice",
        address: Address(street: "Main Street", city: "Boston", zip: "02110"),
        tenants: [Tenant(name: "Bob", age: 25)],
      ),
      Home(
        id: "H101",
        owner: "Eve",
        address: Address(street: "Market Road", city: "Dallas", zip: "75201"),
        tenants: [
          Tenant(name: "Mike", age: 31),
          Tenant(name: "Sophia", age: 27),
        ],
      ),
    ];

    return ResponseBody.of(HttpStatus.OK, homes);
  }

  /// DELETE `/homes/{id}`
  @DeleteMapping(path: "/{id}")
  Future<ResponseBody> deleteHome(@PathVariable() String id) async {
    return ResponseBody.of(HttpStatus.OK, {
      "deleted": true,
      "id": id,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }
}
