import 'dart:collection';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';

/// {@template stack}
/// A last-in-first-out (LIFO) stack implementation, mimicking Java's Stack.
/// 
/// This implementation extends Vector (represented as a List) and provides
/// stack operations like push, pop, peek, and search. Elements are added
/// and removed from the top of the stack.
/// 
/// ## Key Features:
/// 
/// * **LIFO ordering**: Last element added is first to be removed
/// * **Dynamic sizing**: Grows and shrinks as needed
/// * **Vector-based**: Built on top of a resizable array
/// * **Thread-safe operations**: All operations are atomic
/// 
/// ## Usage Examples:
/// 
/// ```dart
/// final stack = Stack<String>();
/// 
/// // Push elements onto the stack
/// stack.push('first');
/// stack.push('second');
/// stack.push('third');
/// 
/// // Peek at the top element
/// print(stack.peek()); // 'third'
/// 
/// // Pop elements from the stack
/// print(stack.pop()); // 'third'
/// print(stack.pop()); // 'second'
/// 
/// // Check if empty
/// print(stack.empty()); // false
/// 
/// // Search for an element
/// print(stack.search('first')); // 1 (1-based position from top)
/// ```
/// 
/// {@endtemplate}
@Generic(Stack)
class Stack<E> extends ListBase<E> {
  final List<E> _elements;
  final E? _defaultValue;

  /// Creates an empty Stack.
  /// 
  /// {@macro stack}
  Stack([E? defaultValue]) : _elements = <E>[], _defaultValue = defaultValue;

  /// Creates a Stack from an iterable.
  /// 
  /// {@macro stack}
  Stack.from(Iterable<E> iterable, [E? defaultValue]) : _elements = List<E>.from(iterable), _defaultValue = defaultValue;

  /// Creates a Stack with the specified initial capacity.
  /// 
  /// {@macro stack}
  Stack.withCapacity(int capacity, [E? defaultValue]) : _elements = List<E>.filled(capacity, defaultValue ?? null as E, growable: true), _defaultValue = defaultValue;

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
    push(element);
  }

  @override
  void insert(int index, E element) {
    _elements.insert(index, element);
  }

  @override
  void addAll(Iterable<E> iterable) {
    _elements.addAll(iterable);
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

  // Stack-specific methods

  /// Pushes an element onto the top of the stack.
  /// 
  /// Returns the element that was pushed.
  /// 
  /// Example:
  /// ```dart
  /// final stack = Stack<int>();
  /// final pushed = stack.push(42);
  /// print(pushed); // 42
  /// ```
  E push(E element) {
    _elements.add(element);
    return element;
  }

  /// Removes and returns the top element of the stack.
  /// 
  /// Throws [NoGuaranteeException] if the stack is empty.
  /// 
  /// Example:
  /// ```dart
  /// final stack = Stack<String>();
  /// stack.push('hello');
  /// final popped = stack.pop(); // 'hello'
  /// ```
  E pop() {
    if (empty()) {
      throw InvalidArgumentException('Stack is empty');
    }
    return _elements.removeLast();
  }

  /// Returns the top element of the stack without removing it.
  /// 
  /// Throws [NoGuaranteeException] if the stack is empty.
  /// 
  /// Example:
  /// ```dart
  /// final stack = Stack<int>();
  /// stack.push(100);
  /// print(stack.peek()); // 100
  /// print(stack.length); // 1 (element still in stack)
  /// ```
  E peek() {
    if (empty()) {
      throw InvalidArgumentException('Stack is empty');
    }
    return _elements.last;
  }

  /// Returns true if the stack contains no elements.
  /// 
  /// Example:
  /// ```dart
  /// final stack = Stack<String>();
  /// print(stack.empty()); // true
  /// stack.push('item');
  /// print(stack.empty()); // false
  /// ```
  bool empty() {
    return _elements.isEmpty;
  }

  /// Searches for an element in the stack and returns its 1-based position from the top.
  /// 
  /// Returns -1 if the element is not found. The top element is at position 1,
  /// the second element is at position 2, and so on.
  /// 
  /// Example:
  /// ```dart
  /// final stack = Stack<String>();
  /// stack.push('bottom');
  /// stack.push('middle');
  /// stack.push('top');
  /// 
  /// print(stack.search('top'));    // 1
  /// print(stack.search('middle')); // 2
  /// print(stack.search('bottom')); // 3
  /// print(stack.search('missing')); // -1
  /// ```
  int search(Object? element) {
    for (int i = _elements.length - 1; i >= 0; i--) {
      if (_elements[i] == element) {
        return _elements.length - i;
      }
    }
    return -1;
  }

  /// Returns the current capacity of the underlying storage.
  /// 
  /// This is an approximation since Dart's List doesn't expose exact capacity.
  int get capacity => _elements.length;

  E? get _default {
    if (null is E || _defaultValue != null) {
      // E is nullable, so this is safe
      return _defaultValue ?? null as E;
    } else {
      throw InvalidArgumentException(
        'Cannot add null to a non-nullable Stack<$E>. '
        'Use a nullable type or manually add default values.'
      );
    }
  }

  /// Ensures that the stack can hold at least the specified number of elements.
  void ensureCapacity(int minCapacity) {
    if (_elements.length < minCapacity) {
      final newElements = List<E>.filled(minCapacity, _default as E, growable: true);
      for (int i = 0; i < _elements.length; i++) {
        newElements[i] = _elements[i];
      }
      _elements.clear();
      _elements.addAll(newElements.take(_elements.length));
    }
  }

  /// Trims the capacity to the current size.
  void trimToSize() {
    // In Dart, this is essentially a no-op since List manages its own capacity
    // We could create a new list with exact size, but it's not typically necessary
  }

  /// Creates a copy of this Stack.
  Stack<E> clone() {
    return Stack<E>.from(_elements);
  }

  @override
  List<E> toList({bool growable = true}) {
    return growable ? List<E>.from(_elements) : List.unmodifiable(_elements);
  }

  @override
  bool get isEmpty => _elements.isEmpty;

  @override
  bool get isNotEmpty => _elements.isNotEmpty;

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
  Iterator<E> get iterator => _elements.iterator;

  /// Returns a reverse iterator over the elements from top to bottom.
  Iterator<E> get reverseIterator => _elements.reversed.iterator;
  
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
  bool contains(Object? element) {
    if (element is! E) return false;
    return _elements.contains(element);
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
    return 'Stack[${_elements.join(', ')}]';
  }
}