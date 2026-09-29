import 'dart:collection';

import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';

/// {@template linked_queue}
/// A queue implementation using a linked list structure, mimicking Java's LinkedList as Queue.
/// 
/// This implementation provides efficient queue operations with constant-time
/// insertion and removal at both ends. It uses a doubly-linked list internally
/// for optimal performance.
/// 
/// ## Key Features:
/// 
/// * **Constant-time operations**: O(1) for offer, poll, peek
/// * **Memory efficient**: Only allocates nodes as needed
/// * **Unbounded**: Can grow to any size (limited by available memory)
/// * **FIFO ordering**: First element added is first to be removed
/// 
/// ## Usage Examples:
/// 
/// ```dart
/// final queue = LinkedQueue<String>();
/// 
/// // Add elements to the queue
/// queue.offer('first');
/// queue.offer('second');
/// queue.offer('third');
/// 
/// // Process elements in FIFO order
/// while (!queue.isEmpty) {
///   print(queue.poll()); // first, second, third
/// }
/// 
/// // Peek without removing
/// queue.offer('peek-me');
/// print(queue.peek()); // 'peek-me'
/// print(queue.size()); // 1
/// ```
/// 
/// {@endtemplate}
@Generic(LinkedQueue)
class LinkedQueue<E> extends ListBase<E> {
  _QueueNode<E>? _head;
  _QueueNode<E>? _tail;
  int _size = 0;
  final E? _defaultValue;

  /// Creates an empty LinkedQueue.
  /// 
  /// {@macro linked_queue}
  LinkedQueue([E? defaultValue]) : _defaultValue = defaultValue;

  /// Creates a LinkedQueue from an iterable.
  /// 
  /// {@macro linked_queue}
  LinkedQueue.from(Iterable<E> iterable, [E? defaultValue]) : _defaultValue = defaultValue {
    addAll(iterable);
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
      // Remove elements from the end
      while (_size > newLength) {
        _removeLast();
      }
    } else {
      // Add null elements to the end
      while (_size < newLength) {
        _addPlaceholder();
      }
    }
  }

  void _addPlaceholder() {
    if (null is E || _defaultValue != null) {
      // E is nullable, so this is safe
      offer(_defaultValue ?? null as E);
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
    offer(element);
  }

  @override
  void insert(int index, E element) {
    if (index < 0 || index > _size) {
      throw RangeError.index(index, this, 'index');
    }
    
    if (index == 0) {
      _addFirst(element);
    } else if (index == _size) {
      offer(element);
    } else {
      final node = _getNode(index);
      _insertBefore(element, node);
    }
  }

  @override
  void addAll(Iterable<E> iterable) {
    for (final element in iterable) {
      offer(element);
    }
  }

  @override
  bool remove(Object? element) {
    var current = _head;
    while (current != null) {
      if (current.data == element) {
        _removeNode(current);
        return true;
      }
      current = current.next;
    }
    return false;
  }

  @override
  E removeAt(int index) {
    _checkIndex(index);
    final node = _getNode(index);
    _removeNode(node);
    return node.data;
  }

  @override
  void clear() {
    _head = null;
    _tail = null;
    _size = 0;
  }

  // Queue-specific methods

  /// Inserts the specified element into this queue.
  /// 
  /// Returns true if the element was added successfully.
  /// This implementation always returns true since the queue is unbounded.
  /// 
  /// Example:
  /// ```dart
  /// final queue = LinkedQueue<int>();
  /// final success = queue.offer(42);
  /// print(success); // true
  /// ```
  bool offer(E element) {
    final newNode = _QueueNode<E>(element);
    
    if (_tail == null) {
      _head = _tail = newNode;
    } else {
      _tail!.next = newNode;
      newNode.prev = _tail;
      _tail = newNode;
    }
    
    _size++;
    return true;
  }

  /// Retrieves and removes the head of this queue.
  /// 
  /// Returns null if this queue is empty.
  /// 
  /// Example:
  /// ```dart
  /// final queue = LinkedQueue<String>();
  /// queue.offer('hello');
  /// final polled = queue.poll(); // 'hello'
  /// final empty = queue.poll(); // null
  /// ```
  E? poll() {
    if (_head == null) {
      return null;
    }
    
    final data = _head!.data;
    _removeNode(_head!);
    return data;
  }

  /// Retrieves, but does not remove, the head of this queue.
  /// 
  /// Returns null if this queue is empty.
  /// 
  /// Example:
  /// ```dart
  /// final queue = LinkedQueue<int>();
  /// queue.offer(100);
  /// print(queue.peek()); // 100
  /// print(queue.size()); // 1 (element still in queue)
  /// ```
  E? peek() {
    return _head?.data;
  }

  /// Retrieves and removes the head of this queue.
  /// 
  /// Throws [NoGuaranteeException] if this queue is empty.
  /// 
  /// Example:
  /// ```dart
  /// final queue = LinkedQueue<String>();
  /// queue.offer('item');
  /// final removed = queue.removeElement(); // 'item'
  /// ```
  E removeElement() {
    if (_head == null) {
      throw NoGuaranteeException('Queue is empty');
    }
    
    final data = _head!.data;
    _removeNode(_head!);
    return data;
  }

  /// Retrieves, but does not remove, the head of this queue.
  /// 
  /// Throws [NoGuaranteeException] if this queue is empty.
  /// 
  /// Example:
  /// ```dart
  /// final queue = LinkedQueue<int>();
  /// queue.offer(42);
  /// final head = queue.element(); // 42
  /// ```
  E element() {
    if (_head == null) {
      throw NoGuaranteeException('Queue is empty');
    }
    return _head!.data;
  }

  /// Returns the number of elements in this queue.
  /// 
  /// Example:
  /// ```dart
  /// final queue = LinkedQueue<String>();
  /// print(queue.size()); // 0
  /// queue.offer('a');
  /// queue.offer('b');
  /// print(queue.size()); // 2
  /// ```
  int size() {
    return _size;
  }

  // Additional LinkedQueue methods

  /// Adds an element to the front of the queue.
  void addFirst(E element) {
    _addFirst(element);
  }

  /// Adds an element to the rear of the queue.
  void addLast(E element) {
    offer(element);
  }

  /// Removes and returns the first element.
  E? pollFirst() {
    return poll();
  }

  /// Removes and returns the last element.
  E? pollLast() {
    if (_tail == null) {
      return null;
    }
    
    final data = _tail!.data;
    _removeNode(_tail!);
    return data;
  }

  /// Returns the first element without removing it.
  E? peekFirst() {
    return peek();
  }

  /// Returns the last element without removing it.
  E? peekLast() {
    return _tail?.data;
  }

  /// Returns true if this queue contains no elements.
  @override
  bool get isEmpty => _size == 0;

  /// Returns true if this queue contains elements.
  @override
  bool get isNotEmpty => _size > 0;

  /// Returns true if this queue contains the specified element.
  @override
  bool contains(Object? element) {
    var current = _head;
    while (current != null) {
      if (current.data == element) {
        return true;
      }
      current = current.next;
    }
    return false;
  }

  /// Returns an iterator over the elements in this queue.
  @override
  Iterator<E> get iterator => _LinkedQueueIterator<E>(_head);

  /// Returns a reverse iterator over the elements in this queue.
  Iterator<E> get reverseIterator => _LinkedQueueReverseIterator<E>(_tail);

  /// Creates a copy of this LinkedQueue.
  LinkedQueue<E> clone() {
    return LinkedQueue<E>.from(this);
  }

  /// Converts to a regular Dart List.
  @override
  List<E> toList({bool growable = true}) {
    final result = <E>[];
    var current = _head;
    while (current != null) {
      result.add(current.data);
      current = current.next;
    }
    return growable ? result : List.unmodifiable(result);
  }

  /// Returns an array containing all elements in this queue.
  List<E> toArray() {
    return toList(growable: false);
  }

  // Private helper methods

  void _checkIndex(int index) {
    if (index < 0 || index >= _size) {
      throw RangeError.index(index, this, 'index');
    }
  }

  _QueueNode<E> _getNode(int index) {
    if (index < _size ~/ 2) {
      // Search from head
      var current = _head!;
      for (int i = 0; i < index; i++) {
        current = current.next!;
      }
      return current;
    } else {
      // Search from tail
      var current = _tail!;
      for (int i = _size - 1; i > index; i--) {
        current = current.prev!;
      }
      return current;
    }
  }

  void _addFirst(E element) {
    final newNode = _QueueNode<E>(element);
    
    if (_head == null) {
      _head = _tail = newNode;
    } else {
      newNode.next = _head;
      _head!.prev = newNode;
      _head = newNode;
    }
    
    _size++;
  }

  void _insertBefore(E element, _QueueNode<E> node) {
    final newNode = _QueueNode<E>(element);
    newNode.next = node;
    newNode.prev = node.prev;
    
    if (node.prev != null) {
      node.prev!.next = newNode;
    } else {
      _head = newNode;
    }
    
    node.prev = newNode;
    _size++;
  }

  void _removeNode(_QueueNode<E> node) {
    if (node.prev != null) {
      node.prev!.next = node.next;
    } else {
      _head = node.next;
    }
    
    if (node.next != null) {
      node.next!.prev = node.prev;
    } else {
      _tail = node.prev;
    }
    
    _size--;
  }

  E _removeLast() {
    if (_tail == null) {
      throw NoGuaranteeException('Queue is empty');
    }
    
    final data = _tail!.data;
    _removeNode(_tail!);
    return data;
  }

  @override
  String toString() {
    return 'LinkedQueue[${join(', ')}]';
  }
}

/// Internal node class for the linked queue.
@Generic(_QueueNode)
class _QueueNode<E> {
  E data;
  _QueueNode<E>? next;
  _QueueNode<E>? prev;

  _QueueNode(this.data);
}

/// Iterator for LinkedQueue.
@Generic(_LinkedQueueIterator)
class _LinkedQueueIterator<E> implements Iterator<E> {
  _QueueNode<E>? _current;
  _QueueNode<E>? _next;

  _LinkedQueueIterator(_QueueNode<E>? head) : _next = head;

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

/// Reverse iterator for LinkedQueue.
@Generic(_LinkedQueueReverseIterator)
class _LinkedQueueReverseIterator<E> implements Iterator<E> {
  _QueueNode<E>? _current;
  _QueueNode<E>? _prev;

  _LinkedQueueReverseIterator(_QueueNode<E>? tail) : _prev = tail;

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
    _current = _prev;
    if (_prev != null) {
      _prev = _prev!.prev;
      return true;
    }
    return false;
  }
}