import 'package:jetleaf/jetleaf.dart';
import 'package:jetleaf_web/jetleaf_web.dart';

/// Represents a product inside the store
class Product {
  final String sku;
  final String name;
  final double price;
  final bool inStock;

  Product({
    required this.sku,
    required this.name,
    required this.price,
    required this.inStock,
  });

  Map<String, dynamic> toJson() => {
        "sku": sku,
        "name": name,
        "price": price,
        "inStock": inStock,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        sku: json["sku"],
        name: json["name"],
        price: (json["price"] as num).toDouble(),
        inStock: json["inStock"],
      );
}

/// Represents a category of products
class Category {
  final String id;
  final String title;

  Category({required this.id, required this.title});

  Map<String, dynamic> toJson() => {
        "id": id,
        "title": title,
      };

  factory Category.fromJson(Map<String, dynamic> json) =>
      Category(id: json["id"], title: json["title"]);
}

/// Represents a store containing a catalog of products,
/// multiple categories, and optional media uploads.
@FromJson(Store.from)
class Store {
  final String id;
  final String owner;
  final String location;

  /// A key-value catalog of products by SKU
  /// Example:
  /// ```json
  /// "products": {
  ///   "P100": { "sku": "P100", "name": "Laptop", "price": 1200.50, "inStock": true },
  ///   "P101": { "sku": "P101", "name": "Mouse", "price": 25.0, "inStock": true }
  /// }
  /// ```
  final Map<String, Product> products;

  /// A list of categories
  final List<Category> categories;

  /// Optional logo file upload (e.g., image)
  final MultipartFile? logo;

  /// Optional extra binary part (e.g., a PDF or document)
  final Part? document;

  Store({
    required this.id,
    required this.owner,
    required this.location,
    required this.products,
    required this.categories,
    this.logo,
    this.document,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "owner": owner,
        "location": location,
        "products": products.map((k, v) => MapEntry(k, v.toJson())),
        "categories": categories.map((c) => c.toJson()).toList(),
        // Multipart fields are excluded from normal JSON serialization
      };

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: json["id"],
        owner: json["owner"],
        location: json["location"],
        products: AdaptableMap.create(json['products']).adapt<String, Product>(),
        categories: AdaptableList.create(json['categories']).adapt<Category>(),
        logo: null, // multipart parts are handled separately
        document: null,
      );

  /// Used by @FromJson annotation for deserialization
  factory Store.from(Map<String, dynamic> json) => Store.fromJson(json);

  Store copyWith({
    String? id,
    String? owner,
    String? location,
    Map<String, Product>? products,
    List<Category>? categories,
    MultipartFile? logo,
    Part? document,
  }) =>
      Store(
        id: id ?? this.id,
        owner: owner ?? this.owner,
        location: location ?? this.location,
        products: products ?? this.products,
        categories: categories ?? this.categories,
        logo: logo ?? this.logo,
        document: document ?? this.document,
      );
}

@RestController("/stores")
class StoreController {
  /// POST `/stores`
  ///
  /// Example JSON body:
  /// ```json
  /// {
  ///   "id": "S001",
  ///   "owner": "Alice",
  ///   "location": "New York",
  ///   "products": {
  ///     "P100": { "sku": "P100", "name": "Laptop", "price": 1200.5, "inStock": true },
  ///     "P101": { "sku": "P101", "name": "Mouse", "price": 25.0, "inStock": true }
  ///   },
  ///   "categories": [
  ///     { "id": "C1", "title": "Electronics" },
  ///     { "id": "C2", "title": "Accessories" }
  ///   ]
  /// }
  /// ```
  @PostMapping(consumes: [MediaType.APPLICATION_JSON, MediaType.MULTIPART_FORM_DATA])
  Future<ResponseBody<Store>> createStore(
    @RequestBody() Store store, {
    @RequestPart(value: "logo") MultipartFile? logo,
    @RequestPart(value: "document") Part? document,
  }) async {
    final created = store.copyWith(
      id: "S-${DateTime.now().millisecondsSinceEpoch}",
      logo: logo,
      document: document,
    );
    return ResponseBody.of(HttpStatus.CREATED, created);
  }

  @PostMapping(path: "/upload", consumes: [MediaType.MULTIPART_FORM_DATA])
  Future<ResponseBody<void>> upload(
    @RequestPart(value: "logo") MultipartFile? logo,
    @RequestPart(value: "document") Part? document
  ) async {
    print("$logo - $document");
    return ResponseBody.of(HttpStatus.CREATED);
  }

  /// GET `/stores/{id}`
  @GetMapping(path: "/{id}")
  Future<ResponseBody<Store>> getStore(@PathVariable() String id) async {
    final store = Store(
      id: id,
      owner: "Bob",
      location: "Chicago",
      products: {
        "P200": Product(sku: "P200", name: "Desk Chair", price: 150.0, inStock: true),
        "P201": Product(sku: "P201", name: "Monitor", price: 320.0, inStock: false),
      },
      categories: [
        Category(id: "C10", title: "Office Furniture"),
        Category(id: "C11", title: "Displays"),
      ],
      logo: null,
      document: null,
    );

    return ResponseBody.of(HttpStatus.OK, store);
  }

  /// PUT `/stores/{id}`
  @PutMapping(path: "/{id}")
  Future<ResponseBody<Store>> updateStore(
    @PathVariable() String id,
    @RequestBody() Store updatedStore, {
    @RequestPart(value: "logo") MultipartFile? logo,
    @RequestPart(value: "document") Part? document,
  }) async {
    final merged = updatedStore.copyWith(id: id, logo: logo, document: document);
    return ResponseBody.of(HttpStatus.OK, merged);
  }

  /// DELETE `/stores/{id}`
  @DeleteMapping(path: "/{id}")
  Future<ResponseBody> deleteStore(@PathVariable() String id) async {
    return ResponseBody.of(HttpStatus.OK, {
      "deleted": true,
      "id": id,
      "timestamp": DateTime.now().toIso8601String(),
    });
  }
}
