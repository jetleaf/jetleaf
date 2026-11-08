/// {@template list_change_type}
/// Represents the type of change that occurs in a `List`.
///
/// This enum is typically used when listening for changes in a `List`
/// to determine what kind of operation was performed.
///
/// ### Example
/// ```dart
/// void main() {
///   // Suppose you have a reactive list
///   List<String> items = ['apple', 'banana'];
///
///   // Simulate a change in the list
///   var changeType = ListChangeType.add;
///
///   switch (changeType) {
///     case ListChangeType.add:
///       print('An item was added to the list.');
///       break;
///     case ListChangeType.remove:
///       print('An item was removed from the list.');
///       break;
///     default:
///       print('Another type of change occurred.');
///   }
/// }
/// ```
/// {@endtemplate}
enum ListChangeType {
  /// {@macro list_change_type}
  add,

  /// {@macro list_change_type}
  insert,

  /// {@macro list_change_type}
  remove,

  /// {@macro list_change_type}
  update,

  /// {@macro list_change_type}
  clear,
}

/// {@template map_change_type}
/// Represents the type of change that occurs in a `Map`.
///
/// This enum is commonly used in state management or data observation
/// scenarios to determine what kind of update was performed on a `Map`.
///
/// ### Example
/// ```dart
/// void main() {
///   // Suppose you have a reactive map
///   Map<String, int> scores = {'Alice': 10, 'Bob': 20};
///
///   // Simulate a change in the map
///   var changeType = MapChangeType.put;
///
///   switch (changeType) {
///     case MapChangeType.put:
///       print('A key-value pair was added or updated.');
///       break;
///     case MapChangeType.remove:
///       print('A key-value pair was removed.');
///       break;
///     case MapChangeType.clear:
///       print('The map was cleared.');
///       break;
///   }
/// }
/// ```
/// {@endtemplate}
enum MapChangeType {
  /// {@macro map_change_type}
  put,

  /// {@macro map_change_type}
  remove,

  /// {@macro map_change_type}
  clear,
}