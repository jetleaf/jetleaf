import 'package:jetleaf/core.dart';
import 'package:jetleaf/lang.dart';
import 'package:jetleaf_web/jetleaf_web.dart';
import 'package:supabase/supabase.dart';

/// {@template metric}
/// Represents the metrics of generated items within the Jetleaf framework.
///
/// Contains the **total count** of generated items and a detailed list
/// of each generated item. Useful for reporting, analytics, and tracking
/// generation operations.
///
/// Example:
/// ```dart
/// final generatedItems = [
///   Generated(
///     id: 1,
///     name: "Item1",
///     description: "First item",
///     jetleaf: "core",
///   ),
///   Generated(
///     id: 2,
///     name: "Item2",
///     description: "Second item",
///     jetleaf: "extension",
///   ),
/// ];
/// final metric = Metric(generatedItems.length, generatedItems);
/// ```
/// {@endtemplate}
final class Metric {
  /// {@macro metric}
  ///
  /// The total number of generated items.
  ///
  /// Automatically calculated when generating metrics for reporting purposes.
  @JsonField(name: "total_count")
  final int totalCount;

  /// {@macro metric}
  ///
  /// List of generated items with detailed metadata.
  final List<Generated> generated;

  /// Creates a [Metric] instance with a total count and a list of generated items.
  ///
  /// [totalCount] should ideally match `generated.length` for consistency.
  /// 
  /// {@macro metric}
  const Metric(this.totalCount, this.generated);
}

/// {@template generated}
/// Represents a single generated item and its associated metadata.
///
/// Provides identifiers, descriptive information, related Jetleaf module,
/// and optional associated packages.
///
/// Example:
/// ```dart
/// final item = Generated(
///   id: 1,
///   name: "UserController",
///   description: "Generated controller for user management",
///   jetleaf: "core",
///   packages: ["auth", "database"],
/// );
/// ```
/// {@endtemplate}
// @FromJson(Generated.fromJson)
final class Generated {
  /// {@macro generated}
  ///
  /// Unique numeric identifier for the generated item.
  @JsonIgnore()
  final int id;

  /// {@macro generated}
  ///
  /// Human-readable name of the generated item.
  final String name;

  /// {@macro generated}
  ///
  /// Detailed description explaining the purpose of the generated item.
  final String description;

  /// {@macro generated}
  ///
  /// Indicates which Jetleaf module or subpackage this item belongs to.
  final String jetleaf;

  /// Time of creation
  final DateTime? createdAt;

  /// {@macro generated}
  ///
  /// Optional list of associated package names.
  ///
  /// Defaults to an empty list if no packages are specified.
  final List<String> packages;

  /// Creates a [Generated] instance with required metadata.
  ///
  /// [id], [name], [description], and [jetleaf] are required.
  /// [packages] is optional and defaults to an empty list.
  /// 
  /// {@macro generated}
  const Generated({
    this.id = 0,
    required this.name,
    required this.description,
    required this.jetleaf,
    this.packages = const [],
    this.createdAt
  });

  /// {@macro generated}
  @JsonCreator()
  factory Generated.fromJson(Map<String, dynamic> data) {
    return Generated(
      id: int.parse(data["id"]?.toString() ?? "0"),
      name: data["name"] ?? "",
      description: data["description"] ?? "",
      jetleaf: data["jetleaf"] ?? "",
      packages: AdaptableList.create(List<Object>.from(data["packages"] ?? [])).adapt<String>(),
      createdAt: DateTime.tryParse(data["created_at"] ?? DateTime.now().toIso8601String())
    );
  }

  /// Copy model to a table design for supabase.
  @JsonOutput()
  Map<String, Object> tabled() => {
    "name": name,
    "description": description,
    "jetleaf": jetleaf,
    "packages": packages,
    "created_at": (createdAt ?? DateTime.now()).toIso8601String()
  };
}

/// {@template metric_service}
/// An abstract interface that defines the operations for working with
/// [Metric] objects in the Jetleaf framework.
///
/// Implementations of this interface provide a way to **fetch** metrics
/// and **update** them based on generated items. This abstraction allows
/// different storage mechanisms or API backends to be used without
/// changing client code.
///
/// Example usage:
/// ```dart
/// class MyMetricService implements MetricService {
///   @override
///   Future<ResponseBody<Metric>> fetch() async {
///     // Fetch metric from backend or database
///   }
///
///   @override
///   Future<ResponseBody<Metric>> update(Generated generated) async {
///     // Update metric with new generated item
///   }
/// }
/// ```
/// {@endtemplate}
abstract interface class MetricService {
  /// {@macro metric_service}
  const MetricService();

  /// {@macro metric_service}
  ///
  /// Updates the current metrics with a new [Generated] item.
  ///
  /// Returns a [ResponseBody] containing the updated [Metric].
  ///
  /// Typical use case:
  /// ```dart
  /// final newItem = Generated(
  ///   id: 1,
  ///   name: "UserController",
  ///   description: "Generated controller",
  ///   jetleaf: "core",
  /// );
  /// final response = await metricService.update(newItem);
  /// print(response.data.totalCount);
  /// ```
  Future<ResponseBody<Metric>> update(Generated generated);

  /// {@macro metric_service}
  ///
  /// Fetches the current [Metric] object containing the total count
  /// and list of generated items.
  ///
  /// Returns a [ResponseBody] containing the current [Metric].
  ///
  /// Typical use case:
  /// ```dart
  /// final response = await metricService.fetch();
  /// print(response.data.generated.length);
  /// ```
  Future<ResponseBody<Metric>> fetch();
}

const String GENERATED_TABLE = "generated";

@Service()
@Primary()
final class MetricImplementation implements MetricService {
  final SupabaseClient _client;

  const MetricImplementation(this._client);

  @override
  Future<ResponseBody<Metric>> fetch() async {
    final result = await _client.from(GENERATED_TABLE).select();
    return ResponseBody.ok(_get(result));
  }

  Metric _get(List<Map<String, dynamic>> result) => Metric(result.length, result.map((data) => Generated.fromJson(data)).toList());

  @override
  Future<ResponseBody<Metric>> update(Generated generated) async {
    await _client.from(GENERATED_TABLE).insert(generated.tabled());
    return fetch();
  }
}

@Component()
@RestController("/metric")
final class MetricController implements MetricService {
  final MetricService _metricService;

  const MetricController(this._metricService);

  @override
  @GetMapping()
  Future<ResponseBody<Metric>> fetch() async => _metricService.fetch();

  @PostMapping(path: "/up")
  Future<ResponseBody<Object>> updateC(@RequestBody() Object generated) async => ResponseBody.ok(generated);

  @override
  @PostMapping(path: "/update")
  Future<ResponseBody<Metric>> update(@RequestBody() Generated generated) async => _metricService.update(generated);
}