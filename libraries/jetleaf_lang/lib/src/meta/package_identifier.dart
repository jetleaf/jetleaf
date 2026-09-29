/// {@template package_identifier}
/// Represents an abstraction for identifying the package that an object,
/// resource, or service belongs to.
///
/// This interface provides a consistent way to query the "owning package"
/// in Jetleaf systems. It is particularly useful when working with modular
/// architectures, dependency resolution, or when generating qualified names
/// that depend on package information.
///
/// ## Example
/// Implementing a simple package identifier:
/// ```dart
/// class MyService implements PackageIdentifier {
///   @override
///   String getPackageName() => "example";
/// }
///
/// void main() {
///   final service = MyService();
///   print(service.getPackageName()); // example
/// }
/// ```
///
/// Using package identifiers to register components:
/// ```dart
/// void registerComponent(PackageIdentifier component) {
///   print("Registering component from package: ${component.getPackageName()}");
/// }
///
/// class DatabaseModule implements PackageIdentifier {
///   @override
///   String getPackageName() => "example";
/// }
///
/// void main() {
///   final db = DatabaseModule();
///   registerComponent(db); // Registering component from package: example
/// }
/// ```
/// {@endtemplate}
abstract interface class PackageIdentifier {
  /// {@macro package_identifier}
  String getPackageName();
}