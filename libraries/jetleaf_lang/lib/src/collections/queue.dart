import 'dart:collection';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';

/// {@template queue}
/// A first-in-first-out (FIFO) queue interface implementation, mimicking Java's Queue.
/// 
/// This implementation provides queue operations using a List as the underlying
/// storage. Elements are added to the rear and removed from the front.
/// 
/// ## Key Features:
/// 
/// * **FIFO ordering**: First element added is first to be removed
/// * **Dynamic sizing**: Grows and shrinks as needed
/// * **List-based**: Built on top of a resizable array
/// * **Efficient operations**: Optimized for queue use cases
/// 
/// ## Usage Examples:
/// 
/// ```dart
/// final queue = Queue<String>();
/// 
/// // Add elements to the queue
/// queue.offer('first');
/// queue.offer('second');
/// queue.offer('third');
/// 
/// // Peek at the front element
/// print(queue.peek()); // 'first'
/// 
/// // Remove elements from the queue
/// print(queue.poll()); // 'first'
/// print(queue.poll()); // 'second'
/// 
/// // Check size
/// print(queue.size()); // 1
/// 
/// // Check if empty
/// print(queue.isEmpty); // false
/// ```
/// 
/// {@endtemplate}
@Generic(Queue)
class Queue<E> extends ListBase<E> {
  final List<E> _elements;

  /// Creates an empty Queue.
  /// 
  /// {@macro queue}
  Queue() : _elements = <E>[];

  /// Creates a Queue from an iterable.
  /// 
  /// {@macro queue}
  Queue.from(Iterable<E> iterable) : _elements = List<E>.from(iterable);

  /// Creates a Queue with the specified initial capacity.
  /// 
  /// {@macro queue}
  Queue.withCapacity(int capacity) : _elements = <E>[];

  @override
  int get length => _elements.length;

  @override
  set length(int newLength) {
    _elements.length = newLength;
  }

  @override
  E operator [](int index) => _elements[index];

  @override
  void operator []=(int index, E value) {
    _elements[index] = value;
  }

  @override
  void add(E element) {
    offer(element);
  }

  @override
  void insert(int index, E element) {
    _elements.insert(index, element);
  }

  @override
  void addAll(Iterable<E> iterable) {
    for (final element in iterable) {
      offer(element);
    }
  }

  @override
  bool remove(Object? element) {
    return _elements.remove(element);
  }

  @override
  E removeAt(int index) {
    return _elements.removeAt(index);
  }

  @override
  void clear() {
    _elements.clear();
  }

  // Queue-specific methods

  /// Inserts the specified element into this queue if it is possible to do so immediately.
  /// 
  /// Returns true if the element was added successfully, false otherwise.
  /// In this implementation, it always returns true since the queue is unbounded.
  /// 
  /// Example:
  /// ```dart
  /// final queue = Queue<int>();
  /// final success = queue.offer(42);
  /// print(success); // true
  /// ```
  bool offer(E element) {
    _elements.add(element);
    return true;
  }

  /// Retrieves and removes the head of this queue.
  /// 
  /// Returns null if this queue is empty.
  /// 
  /// Example:
  /// ```dart
  /// final queue = Queue<String>();
  /// queue.offer('hello');
  /// final polled = queue.poll(); // 'hello'
  /// final empty = queue.poll(); // null
  /// ```
  E? poll() {
    if (_elements.isEmpty) {
      return null;
    }
    return _elements.removeAt(0);
  }

  /// Retrieves, but does not remove, the head of this queue.
  /// 
  /// Returns null if this queue is empty.
  /// 
  /// Example:
  /// ```dart
  /// final queue = Queue<int>();
  /// queue.offer(100);
  /// print(queue.peek()); // 100
  /// print(queue.length); // 1 (element still in queue)
  /// ```
  E? peek() {
    if (_elements.isEmpty) {
      return null;
    }
    return _elements.first;
  }

  /// Retrieves and removes the head of this queue.
  /// 
  /// Throws [InvalidArgumentException] if this queue is empty.
  /// 
  /// Example:
  /// ```dart
  /// final queue = Queue<String>();
  /// queue.offer('item');
  /// final removed = queue.remove(); // 'item'
  /// ```
  E removeElement() {
    if (_elements.isEmpty) {
      throw InvalidArgumentException('Queue is empty');
    }
    return _elements.removeAt(0);
  }

  /// Retrieves, but does not remove, the head of this queue.
  /// 
  /// Throws [InvalidArgumentException] if this queue is empty.
  /// 
  /// Example:
  /// ```dart
  /// final queue = Queue<int>();
  /// queue.offer(42);
  /// final head = queue.element(); // 42
  /// ```
  E element() {
    if (_elements.isEmpty) {
      throw InvalidArgumentException('Queue is empty');
    }
    return _elements.first;
  }

  /// Returns the number of elements in this queue.
  /// 
  /// Example:
  /// ```dart
  /// final queue = Queue<String>();
  /// print(queue.size()); // 0
  /// queue.offer('a');
  /// queue.offer('b');
  /// print(queue.size()); // 2
  /// ```
  int size() {
    return _elements.length;
  }

  @override
  bool get isEmpty => _elements.isEmpty;

  @override
  bool get isNotEmpty => _elements.isNotEmpty;

  @override
  bool contains(Object? element) {
    return _elements.contains(element);
  }

  @override
  Iterator<E> get iterator => _elements.iterator;

  /// Returns an array containing all of the elements in this queue.
  List<E> toArray() {
    return List<E>.from(_elements);
  }

  /// Removes all elements from this queue.
  void removeAll() {
    clear();
  }

  /// Retains only the elements in this queue that are contained in the specified collection.
  void retainAll(Iterable<Object?> elements) {
    _elements.retainWhere((element) => elements.contains(element));
  }

  /// Removes the last element from this queue.
  /// 
  /// Throws [NoGuaranteeException] if this queue is empty.
  @override
  E removeLast() {
    if (_elements.isEmpty) {
      throw NoGuaranteeException('Queue is empty');
    }
    return _elements.removeLast();
  }

  /// Removes the first element from this queue.
  /// 
  /// Throws [NoGuaranteeException] if this queue is empty.
  E removeFirst() {
    if (_elements.isEmpty) {
      throw NoGuaranteeException('Queue is empty');
    }
    return _elements.removeAt(0);
  }

  /// Removes all elements that satisfy the given predicate.
  @override
  void removeWhere(bool Function(E element) test) {
    _elements.removeWhere(test);
  }

  /// Creates a copy of this Queue.
  Queue<E> clone() {
    return Queue<E>.from(_elements);
  }

  @override
  List<E> toList({bool growable = true}) {
    return growable ? List<E>.from(_elements) : List.unmodifiable(_elements);
  }

  @override
  E get first {
    try {
      return _elements.first;
    } on StateError catch (e) {
      throw NoGuaranteeException('Queue is empty', cause: e);
    }
  }

  @override
  E get last {
    try {
      return _elements.last;
    } on StateError catch (e) {
      throw NoGuaranteeException('Queue is empty', cause: e);
    }
  }

  @override
  E get single {
    try {
      return _elements.single;
    } on StateError catch (e) {
      throw NoGuaranteeException('Queue is empty', cause: e);
    }
  }

  @override
  int indexOf(Object? element, [int start = 0]) {
    if (element is! E) return -1;
    return _elements.indexOf(element, start);
  }

  @override
  int lastIndexOf(Object? element, [int? start]) {
    if (element is! E) return -1;
    return _elements.lastIndexOf(element, start);
  }

  @override
  List<E> sublist(int start, [int? end]) {
    return _elements.sublist(start, end);
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    _elements.sort(compare);
  }

  @override
  String toString() {
    return 'Queue[${_elements.join(', ')}]';
  }
}