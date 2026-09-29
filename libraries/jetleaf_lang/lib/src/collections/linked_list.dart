import 'dart:math';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';

/// {@template linked_list}
/// A custom implementation of a **doubly linked list** that implements the standard `List<E>` interface.
///
/// This `LinkedList` provides all list operations such as insertion, removal, iteration,
/// indexing, and length tracking, but operates using linked nodes rather than a backing array.
///
/// ⚠️ **Note:** While all `List<E>` methods are implemented, operations like random access,
/// `sort()`, or `shuffle()` are inherently less efficient due to the sequential nature
/// of linked lists compared to array-based lists.
///
/// ---
///
/// ### 📦 Example Usage:
/// ```dart
/// final list = LinkedList<String>();
/// list.add('A');
/// list.add('B');
/// list.insert(1, 'X');
///
/// print(list); // [A, X, B]
/// print(list.length); // 3
/// print(list[2]); // B
/// ```
///
/// ---
///
/// Internally, this list is backed by `_Node<E>` instances that link to their previous and next nodes.
/// This allows efficient insertion and deletion at both ends and in the middle.
///
/// {@endtemplate}
@Generic(LinkedList)
class LinkedList<E> implements List<E> {
  _Node<E>? _head;
  _Node<E>? _tail;
  int _length = 0;

  /// Creates an empty linked list.
  ///
  /// {@macro linked_list}
  LinkedList();

  @override
  void add(E element) {
    final newNode = _Node(element);
    if (_head == null) {
      _head = newNode;
      _tail = newNode;
    } else {
      _tail!.next = newNode;
      newNode.prev = _tail;
      _tail = newNode;
    }
    _length++;
  }

  @override
  void addAll(Iterable<E> iterable) {
    for (final element in iterable) {
      add(element);
    }
  }

  @override
  E removeAt(int index) {
    if (index < 0 || index >= _length) {
      throw RangeError.index(index, this, 'index', null, _length);
    }

    _Node<E>? current;
    if (index == 0) {
      current = _head;
      _head = _head!.next;
      _head?.prev = null;
      if (_head == null) {
        _tail = null; // List became empty
      }
    } else if (index == _length - 1) {
      current = _tail;
      _tail = _tail!.prev;
      _tail?.next = null;
    } else {
      current = _getNodeAt(index);
      current!.prev!.next = current.next;
      current.next!.prev = current.prev;
    }
    _length--;
    return current!.value;
  }

  @override
  bool remove(Object? value) {
    _Node<E>? current = _head;
    while (current != null) {
      if (current.value == value) {
        if (current.prev != null) {
          current.prev!.next = current.next;
        } else {
          _head = current.next; // Removing head
        }

        if (current.next != null) {
          current.next!.prev = current.prev;
        } else {
          _tail = current.prev; // Removing tail
        }
        _length--;
        return true;
      }
      current = current.next;
    }
    return false;
  }

  @override
  void clear() {
    _head = null;
    _tail = null;
    _length = 0;
  }

  @override
  E operator [](int index) {
    if (index < 0 || index >= _length) {
      throw RangeError.index(index, this, 'index', null, _length);
    }
    return _getNodeAt(index)!.value;
  }

  @override
  void operator []=(int index, E value) {
    if (index < 0 || index >= _length) {
      throw RangeError.index(index, this, 'index', null, _length);
    }
    _getNodeAt(index)!.value = value;
  }

  _Node<E>? _getNodeAt(int index) {
    if (index < 0 || index >= _length) return null;

    _Node<E>? current;
    if (index < _length ~/ 2) {
      // Start from head
      current = _head;
      for (int i = 0; i < index; i++) {
        current = current!.next;
      }
    } else {
      // Start from tail
      current = _tail;
      for (int i = _length - 1; i > index; i--) {
        current = current!.prev;
      }
    }
    return current;
  }

  @override
  int get length => _length;

  @override
  set length(int newLength) {
    if (newLength < 0) {
      throw RangeError.range(newLength, 0, _length, 'newLength');
    }
    if (newLength == _length) return;

    if (newLength < _length) {
      // Truncate the list
      while (_length > newLength) {
        removeLast();
      }
    } else {
      // Extend the list with nulls (if E is nullable) or default values
      if (null is! E) {
        throw UnsupportedError(
            'Cannot extend a LinkedList with non-nullable elements without a default value.');
      }
      while (_length < newLength) {
        add(null as E); // Add nulls for nullable types
      }
    }
  }

  @override
  bool get isEmpty => _length == 0;

  @override
  bool get isNotEmpty => _length > 0;

  @override
  Iterator<E> get iterator => _LinkedListIterator(_head);

  @override
  bool contains(Object? element) {
    _Node<E>? current = _head;
    while (current != null) {
      if (current.value == element) {
        return true;
      }
      current = current.next;
    }
    return false;
  }

  @override
  int indexOf(Object? element, [int start = 0]) {
    if (start < 0 || start >= _length && _length > 0) {
      return -1;
    }
    _Node<E>? current = _getNodeAt(start);
    for (int i = start; i < _length; i++) {
      if (current!.value == element) {
        return i;
      }
      current = current.next;
    }
    return -1;
  }

  @override
  int lastIndexOf(Object? element, [int? start]) {
    if (isEmpty) return -1;
    start ??= _length - 1;
    if (start < 0 || start >= _length) {
      return -1;
    }

    _Node<E>? current = _getNodeAt(start);
    for (int i = start; i >= 0; i--) {
      if (current!.value == element) {
        return i;
      }
      current = current.prev;
    }
    return -1;
  }

  @override
  E get first {
    if (_head == null) {
      throw InvalidArgumentException('No element');
    }
    return _head!.value;
  }

  @override
  set first(E value) {
    if (_head == null) {
      throw InvalidArgumentException('No element');
    }
    _head!.value = value;
  }

  @override
  E get last {
    if (_tail == null) {
      throw InvalidArgumentException('No element');
    }
    return _tail!.value;
  }

  @override
  set last(E value) {
    if (_tail == null) {
      throw InvalidArgumentException('No element');
    }
    _tail!.value = value;
  }

  @override
  E get single {
    if (_length != 1) {
      throw InvalidArgumentException('Expected single element, but got $_length');
    }
    return _head!.value;
  }

  @override
  E elementAt(int index) => this[index];

  @override
  void forEach(void Function(E element) action) {
    _Node<E>? current = _head;
    while (current != null) {
      action(current.value);
      current = current.next;
    }
  }

  @override
  List<E> toList({bool growable = true}) {
    final List<E> list = [];
    forEach((element) => list.add(element));
    return list;
  }

  @override
  Set<E> toSet() {
    final Set<E> set = {}; // Using built-in Set for simplicity here
    forEach((element) => set.add(element));
    return set;
  }

  @override
  Iterable<E> get reversed {
    final reversedList = LinkedList<E>();
    _Node<E>? current = _tail;
    while (current != null) {
      reversedList.add(current.value);
      current = current.prev;
    }
    return reversedList;
  }

  @override
  E removeLast() {
    if (_tail == null) {
      throw InvalidArgumentException('No element');
    }
    return removeAt(_length - 1);
  }

  @override
  void insert(int index, E element) {
    if (index < 0 || index > _length) {
      throw RangeError.index(index, this, 'index', null, _length);
    }
    if (index == _length) {
      add(element);
      return;
    }
    if (index == 0) {
      final newNode = _Node(element);
      newNode.next = _head;
      _head!.prev = newNode;
      _head = newNode;
      _length++;
      return;
    }

    final current = _getNodeAt(index)!;
    final newNode = _Node(element);
    newNode.prev = current.prev;
    newNode.next = current;
    current.prev!.next = newNode;
    current.prev = newNode;
    _length++;
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    if (index < 0 || index > _length) {
      throw RangeError.index(index, this, 'index', null, _length);
    }
    if (iterable.isEmpty) return;

    final temp = iterable.toList();

    if (index == _length) {
      addAll(temp);
      return;
    }
    if (index == 0) {
      final firstNewNode = _Node(temp.first);
      _Node<E>? currentNewNode = firstNewNode;
      for (int i = 1; i < temp.length; i++) {
        final newNode = _Node(temp[i]);
        currentNewNode!.next = newNode;
        newNode.prev = currentNewNode;
        currentNewNode = newNode;
      }
      currentNewNode!.next = _head;
      _head!.prev = currentNewNode;
      _head = firstNewNode;
      _length += temp.length;
      return;
    }

    final nodeAtIndex = _getNodeAt(index)!;
    final prevNode = nodeAtIndex.prev!;

    _Node<E>? firstNewNode;
    _Node<E>? lastNewNode;

    for (final element in temp) {
      final newNode = _Node(element);
      firstNewNode ??= newNode;

      if (lastNewNode != null) {
        lastNewNode.next = newNode;
        newNode.prev = lastNewNode;
      }
      lastNewNode = newNode;
    }

    prevNode.next = firstNewNode;
    firstNewNode!.prev = prevNode;
    lastNewNode!.next = nodeAtIndex;
    nodeAtIndex.prev = lastNewNode;
    _length += temp.length;
  }

  @override
  List<E> operator +(List<E> other) {
    final newList = LinkedList<E>();
    newList.addAll(this);
    newList.addAll(other);
    return newList;
  }

  @override
  Iterable<E> getRange(int start, int end) {
    if (start < 0 || start > _length || end < 0 || end > _length || start > end) {
      throw RangeError.range(start, 0, _length, 'start');
    }
    final result = LinkedList<E>();
    _Node<E>? current = _getNodeAt(start);
    for (int i = start; i < end; i++) {
      result.add(current!.value);
      current = current.next;
    }
    return result;
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    if (index < 0 || index >= _length) {
      throw RangeError.index(index, this, 'index', null, _length);
    }
    _Node<E>? current = _getNodeAt(index);
    for (final element in iterable) {
      if (current == null) {
        throw RangeError.range(index, 0, _length, 'index', 'Iterable too long for list');
      }
      current.value = element;
      current = current.next;
      index++;
    }
  }

  @override
  void fillRange(int start, int end, [E? fillValue]) {
    if (start < 0 || start > _length || end < 0 || end > _length || start > end) {
      throw RangeError.range(start, 0, _length, 'start');
    }
    if (fillValue == null && null is! E) {
      throw InvalidArgumentException('fillValue must not be null for non-nullable type E');
    }
    _Node<E>? current = _getNodeAt(start);
    for (int i = start; i < end; i++) {
      current!.value = fillValue as E;
      current = current.next;
    }
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    if (start < 0 || start > _length || end < 0 || end > _length || start > end) {
      throw RangeError.range(start, 0, _length, 'start');
    }

    // Remove existing range
    for (int i = 0; i < (end - start); i++) {
      removeAt(start);
    }
    // Insert new contents
    insertAll(start, newContents);
  }

  @override
  void removeWhere(bool Function(E element) test) {
    _Node<E>? current = _head;
    while (current != null) {
      final next = current.next; // Store next before potential removal
      if (test(current.value)) {
        remove(current.value); // Use existing remove method
      }
      current = next;
    }
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _Node<E>? current = _head;
    while (current != null) {
      final next = current.next; // Store next before potential removal
      if (!test(current.value)) {
        remove(current.value); // Use existing remove method
      }
      current = next;
    }
  }

  @override
  List<E> sublist(int start, [int? end]) {
    end ??= _length;
    if (start < 0 || start > _length || end < 0 || end > _length || start > end) {
      throw RangeError.range(start, 0, _length, 'start');
    }
    final newList = LinkedList<E>();
    _Node<E>? current = _getNodeAt(start);
    for (int i = start; i < end; i++) {
      newList.add(current!.value);
      current = current.next;
    }
    return newList;
  }

  @override
  Map<int, E> asMap() {
    final map = <int, E>{};
    _Node<E>? current = _head;
    int index = 0;
    while (current != null) {
      map[index++] = current.value;
      current = current.next;
    }
    return map;
  }

  @override
  void shuffle([Random? random]) {
    // This is highly inefficient for a linked list.
    // Convert to list, shuffle, then rebuild.
    final List<E> temp = toList();
    temp.shuffle(random);
    clear();
    addAll(temp);
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    // This is highly inefficient for a linked list.
    // Convert to list, sort, then rebuild.
    final List<E> temp = toList();
    temp.sort(compare);
    clear();
    addAll(temp);
  }

  @override
  String toString() {
    if (isEmpty) return '[]';
    final buffer = StringBuffer('[');
    _Node<E>? current = _head;
    while (current != null) {
      buffer.write(current.value);
      if (current.next != null) {
        buffer.write(', ');
      }
      current = current.next;
    }
    buffer.write(']');
    return buffer.toString();
  }

  @override
  bool any(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) {
        return true;
      }
    }
    return false;
  }

  @override
  List<R> cast<R>() => List.castFrom<E, R>(this);

  @override
  bool every(bool Function(E element) test) {
    for (final element in this) {
      if (!test(element)) {
        return false;
      }
    }
    return true;
  }

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E element) toElements) sync* {
    for (final element in this) {
      yield* toElements(element);
    }
  }

  @override
  E firstWhere(bool Function(E element) test, {E Function()? orElse}) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    if (orElse != null) {
      return orElse();
    }
    throw InvalidArgumentException('No element satisfies the predicate.');
  }

  @override
  T fold<T>(T initialValue, T Function(T previousValue, E element) combine) {
    T value = initialValue;
    for (final element in this) {
      value = combine(value, element);
    }
    return value;
  }

  @override
  Iterable<E> followedBy(Iterable<E> other) sync* {
    yield* this;
    yield* other;
  }

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) {
    if (start < 0 || start >= _length && _length > 0) {
      return -1;
    }
    _Node<E>? current = _getNodeAt(start);
    for (int i = start; i < _length; i++) {
      if (test(current!.value)) {
        return i;
      }
      current = current.next;
    }
    return -1;
  }

  @override
  String join([String separator = ""]) {
    final buffer = StringBuffer();
    bool first = true;
    for (final element in this) {
      if (!first) {
        buffer.write(separator);
      }
      buffer.write(element.toString());
      first = false;
    }
    return buffer.toString();
  }

  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) {
    if (isEmpty) return -1;
    start ??= _length - 1;
    if (start < 0 || start >= _length) {
      return -1;
    }

    _Node<E>? current = _getNodeAt(start);
    for (int i = start; i >= 0; i--) {
      if (test(current!.value)) {
        return i;
      }
      current = current.prev;
    }
    return -1;
  }

  @override
  E lastWhere(bool Function(E element) test, {E Function()? orElse}) {
    if (isEmpty) {
      if (orElse != null) return orElse();
      throw InvalidArgumentException('No element satisfies the predicate.');
    }
    _Node<E>? current = _tail;
    while (current != null) {
      if (test(current.value)) {
        return current.value;
      }
      current = current.prev;
    }
    if (orElse != null) {
      return orElse();
    }
    throw InvalidArgumentException('No element satisfies the predicate.');
  }

  @override
  Iterable<T> map<T>(T Function(E e) toElement) sync* {
    for (final element in this) {
      yield toElement(element);
    }
  }

  @override
  E reduce(E Function(E value, E element) combine) {
    if (isEmpty) {
      throw InvalidArgumentException('No element');
    }
    Iterator<E> iterator = this.iterator;
    iterator.moveNext();
    E value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }

  @override
  void removeRange(int start, int end) {
    if (start < 0 || start > _length || end < 0 || end > _length || start > end) {
      throw RangeError.range(start, 0, _length, 'start');
    }
    for (int i = 0; i < (end - start); i++) {
      removeAt(start);
    }
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    if (start < 0 || start > _length || end < 0 || end > _length || start > end) {
      throw RangeError.range(start, 0, _length, 'start');
    }
    if (end - start < iterable.length - skipCount) {
      throw InvalidArgumentException('The iterable is too long to fit in the range.');
    }

    final iter = iterable.skip(skipCount).iterator;
    _Node<E>? current = _getNodeAt(start);
    for (int i = start; i < end; i++) {
      if (!iter.moveNext()) {
        break; // Ran out of elements in iterable
      }
      current!.value = iter.current;
      current = current.next;
    }
  }

  @override
  E singleWhere(bool Function(E element) test, {E Function()? orElse}) {
    E? result;
    bool found = false;
    for (final element in this) {
      if (test(element)) {
        if (found) {
          throw InvalidArgumentException('More than one element satisfies the predicate.');
        }
        result = element;
        found = true;
      }
    }
    if (found) {
      return result as E;
    }
    if (orElse != null) {
      return orElse();
    }
    throw InvalidArgumentException('No element satisfies the predicate.');
  }

  @override
  Iterable<E> skip(int count) sync* {
    if (count < 0) throw InvalidArgumentException('$count cannot be negative');
    int skipped = 0;
    for (final element in this) {
      if (skipped >= count) {
        yield element;
      }
      skipped++;
    }
  }

  @override
  Iterable<E> skipWhile(bool Function(E value) test) sync* {
    bool skipping = true;
    for (final element in this) {
      if (skipping && test(element)) {
        // Still skipping
      } else {
        skipping = false;
        yield element;
      }
    }
  }

  @override
  Iterable<E> take(int count) sync* {
    if (count < 0) throw InvalidArgumentException('$count cannot be negative');
    int taken = 0;
    for (final element in this) {
      if (taken < count) {
        yield element;
        taken++;
      } else {
        break;
      }
    }
  }

  @override
  Iterable<E> takeWhile(bool Function(E value) test) sync* {
    for (final element in this) {
      if (test(element)) {
        yield element;
      } else {
        break;
      }
    }
  }

  @override
  Iterable<E> where(bool Function(E element) test) sync* {
    for (final element in this) {
      if (test(element)) {
        yield element;
      }
    }
  }

  @override
  Iterable<T> whereType<T>() sync* {
    for (final element in this) {
      if (element is T) {
        yield element;
      }
    }
  }
}

/// Custom iterator for LinkedList.
@Generic(_LinkedListIterator)
class _LinkedListIterator<E> implements Iterator<E> {
  _Node<E>? _currentNode;
  E? _currentValue;

  _LinkedListIterator(_Node<E>? head) : _currentNode = head;

  @override
  E get current => _currentValue as E;

  @override
  bool moveNext() {
    if (_currentNode == null) {
      _currentValue = null;
      return false;
    }
    _currentValue = _currentNode!.value;
    _currentNode = _currentNode!.next;
    return true;
  }
}

/// Represents a node in the doubly linked list.
@Generic(_Node)
class _Node<E> {
  E value;
  _Node<E>? next;
  _Node<E>? prev;

  _Node(this.value);
}