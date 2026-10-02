import 'dart:collection';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';

/// {@template linked_stack}
/// A stack implementation using a linked list structure, mimicking Java's LinkedList as Stack.
/// 
/// This implementation provides efficient stack operations with constant-time
/// push and pop operations. It uses a singly-linked list internally for
/// optimal memory usage and performance.
/// 
/// ## Key Features:
/// 
/// * **Constant-time operations**: O(1) for push, pop, peek
/// * **Memory efficient**: Only allocates nodes as needed
/// * **Unbounded**: Can grow to any size (limited by available memory)
/// * **LIFO ordering**: Last element added is first to be removed
/// 
/// ## Usage Examples:
/// 
/// ```dart
/// final stack = LinkedStack<String>();
/// 
/// // Push elements onto the stack
/// stack.push('bottom');
/// stack.push('middle');
/// stack.push('top');
/// 
/// // Process elements in LIFO order
/// while (!stack.isEmpty) {
///   print(stack.pop()); // top, middle, bottom
/// }
/// 
/// // Peek without removing
/// stack.push('peek-me');
/// print(stack.peek()); // 'peek-me'
/// print(stack.size()); // 1
/// ```
/// 
/// {@endtemplate}
@Generic(LinkedStack)
class LinkedStack<E> extends ListBase<E> {
  _StackNode<E>? _top;
  int _size = 0;
  final E? _defaultValue;

  /// Creates an empty LinkedStack.
  /// 
  /// {@macro linked_stack}
  LinkedStack([E? defaultValue]) : _defaultValue = defaultValue;

  /// Creates a LinkedStack from an iterable.
  /// Elements are pushed in the order they appear in the iterable.
  /// 
  /// {@macro linked_stack}
  LinkedStack.from(Iterable<E> iterable, [E? defaultValue]) : _defaultValue = defaultValue {
    for (final element in iterable) {
      push(element);
    }
  }

  @override
  int get length => _size;

  @override
  set length(int newLength) {
    if (newLength < 0) {
      throw InvalidArgumentException('Length cannot be negative');
    }
    
    if (newLength == _size) return;
    
    if (newLength == 0) {
      clear();
      return;
    }
    
    if (newLength < _size) {
      // Remove elements from the top
      while (_size > newLength) {
        pop();
      }
    } else {
      // Add null elements to the top
      while (_size < newLength) {
        _addPlaceholder();
      }
    }
  }

  void _addPlaceholder() {
    if (null is E || _defaultValue != null) {
      // E is nullable, so this is safe
      push(_defaultValue ?? null as E);
    } else {
      throw InvalidArgumentException(
        'Cannot add null to a non-nullable LinkedList<$E>. '
        'Use a nullable type or manually add default values.'
      );
    }
  }

  @override
  E operator [](int index) {
    _checkIndex(index);
    return _getNode(index).data;
  }

  @override
  void operator []=(int index, E value) {
    _checkIndex(index);
    _getNode(index).data = value;
  }

  @override
  void add(E element) {
    push(element);
  }

  @override
  void insert(int index, E element) {
    if (index < 0 || index > _size) {
      throw RangeError.index(index, this, 'index');
    }
    
    if (index == 0) {
      push(element);
    } else {
      // Convert to list, insert, and rebuild stack
      final list = toList();
      list.insert(_size - index, element);
      clear();
      for (final item in list.reversed) {
        push(item);
      }
    }
  }

  @override
  void addAll(Iterable<E> iterable) {
    for (final element in iterable) {
      push(element);
    }
  }

  @override
  bool remove(Object? element) {
    // Convert to list, remove, and rebuild stack
    final list = toList();
    final removed = list.remove(element);
    if (removed) {
      clear();
      for (final item in list.reversed) {
        push(item);
      }
    }
    return removed;
  }

  @override
  E removeAt(int index) {
    _checkIndex(index);
    
    if (index == 0) {
      return pop();
    }
    
    // Convert to list, remove, and rebuild stack
    final list = toList();
    final removed = list.removeAt(_size - 1 - index);
    clear();
    for (final item in list.reversed) {
      push(item);
    }
    return removed;
  }

  @override
  void clear() {
    _top = null;
    _size = 0;
  }

  // Stack-specific methods

  /// Pushes an element onto the top of the stack.
  /// 
  /// Returns the element that was pushed.
  /// 
  /// Example:
  /// ```dart
  /// final stack = LinkedStack<int>();
  /// final pushed = stack.push(42);
  /// print(pushed); // 42
  /// ```
  E push(E element) {
    final newNode = _StackNode<E>(element);
    newNode.next = _top;
    _top = newNode;
    _size++;
    return element;
  }

  /// Removes and returns the top element of the stack.
  /// 
  /// Throws [NoGuaranteeException] if the stack is empty.
  /// 
  /// Example:
  /// ```dart
  /// final stack = LinkedStack<String>();
  /// stack.push('hello');
  /// final popped = stack.pop(); // 'hello'
  /// ```
  E pop() {
    if (_top == null) {
      throw NoGuaranteeException('Stack is empty');
    }
    
    final data = _top!.data;
    _top = _top!.next;
    _size--;
    return data;
  }

  /// Returns the top element of the stack without removing it.
  /// 
  /// Throws [NoGuaranteeException] if the stack is empty.
  /// 
  /// Example:
  /// ```dart
  /// final stack = LinkedStack<int>();
  /// stack.push(100);
  /// print(stack.peek()); // 100
  /// print(stack.length); // 1 (element still in stack)
  /// ```
  E peek() {
    if (_top == null) {
      throw NoGuaranteeException('Stack is empty');
    }
    return _top!.data;
  }

  /// Returns the top element of the stack without removing it.
  /// 
  /// Returns null if the stack is empty.
  /// 
  /// Example:
  /// ```dart
  /// final stack = LinkedStack<String>();
  /// print(stack.peekOrNull()); // null
  /// stack.push('item');
  /// print(stack.peekOrNull()); // 'item'
  /// ```
  E? peekOrNull() {
    return _top?.data;
  }

  /// Removes and returns the top element of the stack.
  /// 
  /// Returns null if the stack is empty.
  /// 
  /// Example:
  /// ```dart
  /// final stack = LinkedStack<int>();
  /// print(stack.popOrNull()); // null
  /// stack.push(42);
  /// print(stack.popOrNull()); // 42
  /// ```
  E? popOrNull() {
    if (_top == null) {
      return null;
    }
    return pop();
  }

  /// Returns true if the stack contains no elements.
  /// 
  /// Example:
  /// ```dart
  /// final stack = LinkedStack<String>();
  /// print(stack.empty()); // true
  /// stack.push('item');
  /// print(stack.empty()); // false
  /// ```
  bool empty() {
    return _top == null;
  }

  /// Searches for an element in the stack and returns its 1-based position from the top.
  /// 
  /// Returns -1 if the element is not found. The top element is at position 1,
  /// the second element is at position 2, and so on.
  /// 
  /// Example:
  /// ```dart
  /// final stack = LinkedStack<String>();
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
    var current = _top;
    var position = 1;
    
    while (current != null) {
      if (current.data == element) {
        return position;
      }
      current = current.next;
      position++;
    }
    
    return -1;
  }

  /// Returns the number of elements in this stack.
  /// 
  /// Example:
  /// ```dart
  /// final stack = LinkedStack<String>();
  /// print(stack.size()); // 0
  /// stack.push('a');
  /// stack.push('b');
  /// print(stack.size()); // 2
  /// ```
  int size() {
    return _size;
  }

  /// Returns true if this stack contains no elements.
  @override
  bool get isEmpty => _top == null;

  /// Returns true if this stack contains elements.
  @override
  bool get isNotEmpty => _top != null;

  /// Returns true if this stack contains the specified element.
  @override
  bool contains(Object? element) {
    var current = _top;
    while (current != null) {
      if (current.data == element) {
        return true;
      }
      current = current.next;
    }
    return false;
  }

  /// Returns an iterator over the elements in this stack from top to bottom.
  @override
  Iterator<E> get iterator => _LinkedStackIterator<E>(_top);

  /// Returns a reverse iterator over the elements from bottom to top.
  Iterator<E> get reverseIterator {
    final list = toList();
    return list.reversed.iterator;
  }

  /// Creates a copy of this LinkedStack.
  LinkedStack<E> clone() {
    final copy = LinkedStack<E>();
    final list = toList();
    for (final item in list.reversed) {
      copy.push(item);
    }
    return copy;
  }

  /// Converts to a regular Dart List (top to bottom order).
  @override
  List<E> toList({bool growable = true}) {
    final result = <E>[];
    var current = _top;
    while (current != null) {
      result.add(current.data);
      current = current.next;
    }
    return growable ? result : List.unmodifiable(result);
  }

  /// Returns an array containing all elements in this stack (top to bottom order).
  List<E> toArray() {
    return toList(growable: false);
  }

  // Private helper methods

  void _checkIndex(int index) {
    if (index < 0 || index >= _size) {
      throw RangeError.index(index, this, 'index');
    }
  }

  _StackNode<E> _getNode(int index) {
    var current = _top!;
    for (int i = 0; i < index; i++) {
      current = current.next!;
    }
    return current;
  }

  @override
  String toString() {
    return 'LinkedStack[${join(', ')}]';
  }
}

/// Internal node class for the linked stack.
@Generic(_StackNode)
class _StackNode<E> {
  E data;
  _StackNode<E>? next;

  _StackNode(this.data);
}

/// Iterator for LinkedStack (top to bottom).
@Generic(_LinkedStackIterator)
class _LinkedStackIterator<E> implements Iterator<E> {
  _StackNode<E>? _current;
  _StackNode<E>? _next;

  _LinkedStackIterator(_StackNode<E>? top) : _next = top;

  @override
  E get current {
    final current = _current;
    if (current == null) {
      throw NoGuaranteeException('No current element');
    }
    return current.data;
  }

  @override
  bool moveNext() {
    _current = _next;
    if (_next != null) {
      _next = _next!.next;
      return true;
    }
    return false;
  }
}