import 'dart:math';

import 'package:jetleaf_build/jetleaf_build.dart';

/// {@template array_list}
/// A resizable array implementation similar to Java's ArrayList.
/// 
/// This class provides a dynamic array that can grow and shrink as needed,
/// with methods similar to Java's ArrayList.
/// 
/// Example usage:
/// ```dart
/// ArrayList<String> list = ArrayList<String>();
/// list.add("Hello");
/// list.add("World");
/// list.insert(1, "Beautiful");
/// 
/// print(list.get(0)); // "Hello"
/// print(list.size()); // 3
/// ```
/// 
/// {@endtemplate}
@Generic(ArrayList)
class ArrayList<E> implements List<E> {
  /// Internal list storage
  List<E> _list;

  /// Creates an empty ArrayList.
  /// 
  /// {@macro array_list}
  ArrayList() : _list = <E>[];

  /// Creates an ArrayList with the specified initial capacity.
  /// 
  /// [initialCapacity] the initial capacity of the list
  /// 
  /// {@macro array_list}
  ArrayList.withCapacity(int initialCapacity) 
      : _list = List<E>.empty(growable: true);

  /// Creates an ArrayList from an existing collection.
  /// 
  /// [collection] the collection to copy from
  /// 
  /// {@macro array_list}
  ArrayList.from(Iterable<E> collection) : _list = List<E>.from(collection);

  @override
  bool add(E element) {
    _list.add(element);
    return true;
  }

  @override
  void insert(int index, E element) {
    _list.insert(index, element);
  }

  @override
  bool addAll(Iterable<E> iterable) {
    if (iterable.isEmpty) return false;
    _list.addAll(iterable);
    return true;
  }

  @override
  bool insertAll(int index, Iterable<E> iterable) {
    if (iterable.isEmpty) return false;
    _list.insertAll(index, iterable);
    return true;
  }

  /// Returns the element at the specified index.
  /// 
  /// [index] the index of the element to return
  E get(int index) {
    return _list[index];
  }

  /// Replaces the element at the specified index.
  /// 
  /// [index] the index of the element to replace
  /// [element] the new element
  /// Returns the previous element at the index
  E set(int index, E element) {
    E oldElement = _list[index];
    _list[index] = element;
    return oldElement;
  }

  @override
  E removeAt(int index) {
    return _list.removeAt(index);
  }

  @override
  bool remove(Object? element) {
    return _list.remove(element);
  }

  /// Removes all elements from this list.
  @override
  void clear() {
    _list.clear();
  }

  @override
  bool contains(Object? element) {
    return _list.contains(element);
  }

  @override
  int indexOf(Object? element, [int start = 0]) {
    if (element is! E) return -1;
    return _list.indexOf(element, start);
  }

  @override
  int lastIndexOf(Object? element, [int? start]) {
    if (element is! E) return -1;
    return _list.lastIndexOf(element, start);
  }

  /// Returns the number of elements in this list.
  int size() => _list.length;

  /// Returns a view of the portion of this list between the specified indices.
  /// 
  /// [fromIndex] the starting index (inclusive)
  /// [toIndex] the ending index (exclusive)
  ArrayList<E> subList(int fromIndex, int toIndex) {
    return ArrayList<E>.from(_list.sublist(fromIndex, toIndex));
  }

  @override
  List<E> toList({bool growable = true}) => List<E>.from(_list, growable: growable);

  /// Converts this list to an array (same as toList in Dart).
  List<E> toArray() => toList();

  @override
  void sort([int Function(E a, E b)? compare]) {
    _list.sort(compare);
  }

  /// Reverses the order of elements in this list.
  void reverse() {
    _list = _list.reversed.toList();
  }

  /// Iterator implementation
  @override
  Iterator<E> get iterator => _list.iterator;

  @override
  E operator [](int index) => get(index);
  @override
  void operator []=(int index, E element) => set(index, element);

  @override
  String toString() => _list.toString();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ArrayList<E>) return false;
    if (_list.length != other._list.length) return false;
    
    for (int i = 0; i < _list.length; i++) {
      if (_list[i] != other._list[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_list);

  @override
  bool any(bool Function(E) test) => _list.any(test);

  @override
  List<T> cast<T>() => _list.cast<T>();

  @override
  bool every(bool Function(E) test) => _list.every(test);

  @override
  Iterable<T> expand<T>(Iterable<T> Function(E) f) => _list.expand(f);

  @override
  E get first => _list.first;

  @override
  E firstWhere(bool Function(E) test, {E Function()? orElse}) => _list.firstWhere(test, orElse: orElse);

  @override
  T fold<T>(T initialValue, T Function(T, E) combine) => _list.fold(initialValue, combine);

  @override
  Iterable<E> followedBy(Iterable<E> other) => _list.followedBy(other);

  @override
  void forEach(void Function(E) action) => _list.forEach(action);

  @override
  bool get isEmpty => _list.isEmpty;

  @override
  bool get isNotEmpty => _list.isNotEmpty;

  @override
  String join([String separator = ""]) => _list.join(separator);

  @override
  E get last => _list.last;

  @override
  E lastWhere(bool Function(E) test, {E Function()? orElse}) => _list.lastWhere(test, orElse: orElse);

  @override
  int get length => _list.length;

  @override
  Iterable<T> map<T>(T Function(E) f) => _list.map(f);

  @override
  E reduce(E Function(E, E) combine) => _list.reduce(combine);

  @override
  E get single => _list.single;

  @override
  E singleWhere(bool Function(E) test, {E Function()? orElse}) => _list.singleWhere(test, orElse: orElse);

  @override
  Iterable<E> skip(int count) => _list.skip(count);

  @override
  Iterable<E> skipWhile(bool Function(E) test) => _list.skipWhile(test);

  @override
  Iterable<E> take(int count) => _list.take(count);

  @override
  Iterable<E> takeWhile(bool Function(E) test) => _list.takeWhile(test);

  @override
  Set<E> toSet() => _list.toSet();

  @override
  Iterable<E> where(bool Function(E) test) => _list.where(test);

  @override
  Iterable<T> whereType<T>() => _list.whereType<T>();

  @override
  E elementAt(int index) => _list.elementAt(index);

  @override
  List<E> operator +(List<E> other) {
    return ArrayList<E>.from(_list + other);
  }

  @override
  Map<int, E> asMap() {
    return _list.asMap();
  }

  @override
  void fillRange(int start, int end, [E? fill]) {
    _list.fillRange(start, end, fill);
  }

  @override
  set first(E value) {
    _list.first = value;
  }

  @override
  Iterable<E> getRange(int start, int end) {
    return _list.getRange(start, end);
  }

  @override
  int indexWhere(bool Function(E element) test, [int start = 0]) {
    return _list.indexWhere(test, start);
  }

  @override
  set last(E value) {
    _list.last = value;
  }

  @override
  int lastIndexWhere(bool Function(E element) test, [int? start]) {
    return _list.lastIndexWhere(test, start);
  }

  @override
  set length(int newLength) {
    _list.length = newLength;
  }

  @override
  E removeLast() {
    return _list.removeLast();
  }

  @override
  void removeRange(int start, int end) {
    _list.removeRange(start, end);
  }

  @override
  void removeWhere(bool Function(E element) test) {
    _list.removeWhere(test);
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    _list.replaceRange(start, end, newContents);
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _list.retainWhere(test);
  }

  @override
  Iterable<E> get reversed => _list.reversed;

  @override
  void setAll(int index, Iterable<E> iterable) {
    _list.setAll(index, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    _list.setRange(start, end, iterable, skipCount);
  }

  @override
  void shuffle([Random? random]) {
    _list.shuffle(random);
  }

  @override
  List<E> sublist(int start, [int? end]) {
    return _list.sublist(start, end);
  }
}