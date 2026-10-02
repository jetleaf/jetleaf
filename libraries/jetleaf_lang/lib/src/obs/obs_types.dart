import 'package:jetleaf_build/jetleaf_build.dart';

import 'obs_enums.dart';
import 'obs_event.dart';

/// {@template value_changed}
/// Represents a change in a single observable value.
///
/// This event is typically dispatched when a reactive value updates
/// from an old value to a new value. It holds both values so that you
/// can compare or react accordingly.
///
/// ### Example
/// ```dart
/// void main() {
///   // Suppose you are observing a value
///   var oldValue = 10;
///   var newValue = 20;
///
///   var event = ValueChanged<int>(oldValue, newValue);
///
///   print(event.oldValue); // 10
///   print(event.newValue); // 20
/// }
/// ```
/// {@endtemplate}
@Generic(ValueChanged)
class ValueChanged<T> extends ObsEvent {
  /// The previous value before the change occurred.
  final T? oldValue;

  /// The new value after the change occurred.
  final T? newValue;

  /// {@macro value_changed}
  const ValueChanged(this.oldValue, this.newValue);
}

/// {@template list_change}
/// Represents a change in a `List`.
///
/// This event captures details about what kind of modification
/// occurred in the list (add, insert, remove, update, clear),
/// the index affected, and the values before and after the change.
///
/// ### Example
/// ```dart
/// void main() {
///   var addEvent = ListChange.add(0, 'apple');
///   print(addEvent.type); // ListChangeType.add
///
///   var removeEvent = ListChange.remove(1, 'banana');
///   print(removeEvent.oldValue); // banana
/// }
/// ```
/// {@endtemplate}
@Generic(ListChange)
class ListChange<T> extends ObsEvent {
  /// The type of change that occurred in the list.
  final ListChangeType type;

  /// The index affected by the change (if applicable).
  final int? index;

  /// The previous value before the change (if applicable).
  final T? oldValue;

  /// The new value after the change (if applicable).
  final T? newValue;

  /// {@macro list_change}
  const ListChange.add(this.index, this.newValue)
      : type = ListChangeType.add,
        oldValue = null;

  /// {@macro list_change}
  const ListChange.insert(this.index, this.newValue)
      : type = ListChangeType.insert,
        oldValue = null;

  /// {@macro list_change}
  const ListChange.remove(this.index, this.oldValue)
      : type = ListChangeType.remove,
        newValue = null;

  /// {@macro list_change}
  const ListChange.update(this.index, this.oldValue, this.newValue)
      : type = ListChangeType.update;

  /// {@macro list_change}
  const ListChange.clear()
      : type = ListChangeType.clear,
        index = null,
        oldValue = null,
        newValue = null;
}

/// {@template map_change}
/// Represents a change in a `Map`.
///
/// This event captures information about changes to key-value pairs,
/// including additions, updates, removals, and clear operations.
///
/// ### Example
/// ```dart
/// void main() {
///   var putEvent = MapChange.put('Alice', 10, 20);
///   print(putEvent.type); // MapChangeType.put
///
///   var removeEvent = MapChange.remove('Bob', 15);
///   print(removeEvent.oldValue); // 15
/// }
/// ```
/// {@endtemplate}
@Generic(MapChange)
class MapChange<K, V> extends ObsEvent {
  /// The type of change that occurred in the map.
  final MapChangeType type;

  /// The key affected by the change (if applicable).
  final K? key;

  /// The previous value associated with the key (if applicable).
  final V? oldValue;

  /// The new value associated with the key (if applicable).
  final V? newValue;

  /// {@macro map_change}
  const MapChange.put(this.key, this.oldValue, this.newValue)
      : type = MapChangeType.put;

  /// {@macro map_change}
  const MapChange.remove(this.key, this.oldValue)
      : type = MapChangeType.remove,
        newValue = null;

  /// {@macro map_change}
  const MapChange.clear([this.key])
      : type = MapChangeType.clear,
        oldValue = null,
        newValue = null;
}

/// {@template bulk_change}
/// Represents multiple observable events grouped together.
///
/// This event is useful for batching changes, so instead of emitting
/// multiple `ValueChanged`, `ListChange`, or `MapChange` events individually,
/// you can group them into a single `BulkChange`.
///
/// ### Example
/// ```dart
/// void main() {
///   var events = [
///     ValueChanged<int>(1, 2),
///     ListChange.add(0, 'apple'),
///     MapChange.put('key', null, 'value'),
///   ];
///
///   var bulk = BulkChange(events);
///
///   print(bulk.changes.length); // 3
/// }
/// ```
/// {@endtemplate}
class BulkChange extends ObsEvent {
  /// The list of observable events batched into this bulk change.
  final List<ObsEvent> changes;

  /// {@macro bulk_change}
  const BulkChange(this.changes);
}