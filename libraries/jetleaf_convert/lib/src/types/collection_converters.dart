import 'dart:collection' as col;

import 'package:jetleaf_lang/lang.dart';

import '../core/conversion_service.dart';
import '../helpers/_commons.dart';
import '../helpers/conversion_adapter_utils.dart';
import '../helpers/conversion_utils.dart';
import '../helpers/convertible_pair.dart';

/// {@template collection_to_collection_converter}
/// An abstract base class for converting between different types of Dart collections,
/// with optional element type conversion.
///
/// This converter works by:
/// 1. Checking if the source type matches the expected `this`.
/// 2. Verifying that the target type is a supported collection type.
/// 3. Converting each element if type information is available.
///
/// ### Supported target types include:
/// - `List`, `Set`, `Iterable`, `Queue`
/// - `ArrayList`, `HashSet`, `LinkedQueue`, `LinkedList`, `LinkedStack`, `Stack`
/// - `col.LinkedHashSet`, `col.ListBase`, `col.SetBase`, `col.Queue`
///
/// ### Example:
/// ```dart
/// final service = ConversionService(); // Your implementation
/// final converter = ListToCollectionConverter(service);
///
/// final source = [1, 2, 3];
/// final result = converter.convert(
///   source,
///   Class.forType(List),
///   Class.forType(Set),
/// );
///
/// print(result.runtimeType); // Set<int>
/// ```
///
/// Subclasses specify the exact source type (e.g., `List`, `Set`) via `_sourceDartType`.
/// {@endtemplate}
abstract class CollectionToCollectionConverter extends CommonPairedConditionalConverter {
  final ConversionService _conversionService;
  final Class _source;

  /// {@macro collection_to_collection_converter}
  CollectionToCollectionConverter(this._conversionService, this._source);

  @override
  Set<ConvertiblePair>? getConvertibleTypes() => {
    ConvertiblePair(_source, Class<List>(null, PackageNames.DART)),
    ConvertiblePair(_source, Class<Set>(null, PackageNames.DART)),
    ConvertiblePair(_source, Class<Queue>(null, PackageNames.LANG)),
    ConvertiblePair(_source, Class<Iterable>(null, PackageNames.DART)),
    ConvertiblePair(_source, Class<ArrayList>(null, PackageNames.LANG)),
    ConvertiblePair(_source, Class<HashSet>(null, PackageNames.LANG)),
    ConvertiblePair(_source, Class<LinkedQueue>(null, PackageNames.LANG)),
    ConvertiblePair(_source, Class<LinkedList>(null, PackageNames.LANG)),
    ConvertiblePair(_source, Class<LinkedStack>(null, PackageNames.LANG)),
    ConvertiblePair(_source, Class<Stack>(null, PackageNames.LANG)),
    ConvertiblePair(_source, Class<col.LinkedHashSet>(null, PackageNames.DART)),
    ConvertiblePair(_source, Class<col.ListBase>(null, PackageNames.DART)),
    ConvertiblePair(_source, Class<col.SetBase>(null, PackageNames.DART)),
    ConvertiblePair(_source, Class<col.Queue>(null, PackageNames.DART)),
  };

  @override
  bool matches(Class sourceType, Class targetType) {
    if (sourceType.getType() != _source.getType() || !_isSupportedTarget(targetType.getType())) {
      return false;
    }

    final sourceElementType = sourceType.componentType();
    final targetElementType = targetType.componentType();

    if (sourceElementType == null || targetElementType == null) {
      // Allow if we can't determine element types — rely on runtime conversion
      return true;
    }

    return ConversionUtils.canConvert(sourceElementType, targetElementType, _conversionService);
  }

  /// {@template collection_to_collection_is_supported_target}
  /// Checks if the given Dart type is a supported collection type.
  ///
  /// ### Example:
  /// ```dart
  /// final isSupported = _isSupportedTarget(List);
  /// print(isSupported); // true
  /// ```
  /// {@endtemplate}
  bool _isSupportedTarget(Type dartType) {
    return dartType == List ||
        dartType == Set ||
        dartType == Iterable ||
        dartType == Queue ||
        dartType == ArrayList ||
        dartType == HashSet ||
        dartType == LinkedQueue ||
        dartType == LinkedList ||
        dartType == LinkedStack ||
        dartType == Stack ||
        dartType == col.LinkedHashSet ||
        dartType == col.ListBase ||
        dartType == col.SetBase ||
        dartType == col.Queue;
  }

  @override
  Object? convert<T>(Object? source, Class sourceType, Class targetType) {
    if (source == null) return null;

    final Iterable sourceCollection = source as Iterable;

    // Shortcut if possible...
    bool copyRequired = !targetType.isInstance(source);
    if (!copyRequired && sourceCollection.isEmpty) {
			return source;
		}

    final targetElementType = _getElementType(targetType);
    if (targetElementType == null && !copyRequired) {
			return source;
		}

    final sourceElementType = _getElementType(sourceType);

    final target = <Object>[];

    if (targetElementType == null) {
			sourceCollection.process((s) => target.add(s));
		} else {
      for (final element in sourceCollection) {
        Object? result = _conversionService.convertTo(element, targetElementType, sourceElementType);
        if(result != null) {
          target.add(result);
        }
        
        if (element != result) {
					copyRequired = true;
				}
      }
    }
    return _createTargetCollection(targetType, target);
  }

  /// {@template collection_to_collection_get_element_type}
  /// Retrieves the element type of the given collection type.
  ///
  /// If the collection type is a [Class], returns its component type.
  /// Otherwise, returns `null`.
  ///
  /// ### Example:
  /// ```dart
  /// final elementType = _getElementType(Class.forType(List));
  /// print(elementType); // int
  /// ```
  /// {@endtemplate}
  Class? _getElementType(Class collectionType) => collectionType.componentType();

  /// {@template collection_to_collection_create_target_collection}
  /// Creates a new instance of the desired target collection type and populates it
  /// with the given `elements`.
  ///
  /// The mapping from type to collection is as follows:
  /// - `List`, `col.ListBase` → `List.from(elements)`
  /// - `Set`, `HashSet`, `col.SetBase` → `Set.from(elements)`
  /// - `col.LinkedHashSet` → `col.LinkedHashSet.from(elements)`
  /// - `Queue`, `col.Queue` → `Queue.from(elements)`
  /// - `LinkedQueue` → `LinkedQueue.from(elements)`
  /// - `LinkedList` → new `LinkedList()` with elements added
  /// - `LinkedStack`, `Stack` → new stack with elements pushed
  /// - `ArrayList` → `ArrayList.from(elements)`
  ///
  /// ### Example:
  /// ```dart
  /// final created = _createTargetCollection(Class.forType(Set), [1, 2, 3]);
  /// print(created.runtimeType); // Set<int>
  /// ```
  /// {@endtemplate}
  Object _createTargetCollection(Class targetType, List elements) {
    final dartType = targetType.getType();

    if (dartType == List || dartType == col.ListBase) {
      return ConversionAdapterUtils.getListResult(targetType, List<Object>.from(elements));
    } else if (dartType == Set || dartType == HashSet || dartType == col.SetBase) {
      return ConversionAdapterUtils.getSetResult(targetType, Set<Object>.from(elements));
    } else if (dartType == col.LinkedHashSet) {
      return col.LinkedHashSet<Object>.from(elements);
    } else if (dartType == Queue || dartType == col.Queue) {
      return Queue<Object>.from(List<Object>.from(elements));
    } else if (dartType == LinkedQueue) {
      return LinkedQueue<Object>.from(List<Object>.from(elements));
    } else if (dartType == LinkedList) {
      final list = LinkedList<Object>();
      for (var e in elements) {
        list.add(e);
      }
      return list;
    } else if (dartType == LinkedStack) {
      final stack = LinkedStack<Object>();
      for (var e in elements) {
        stack.push(e);
      }
      return stack;
    } else if (dartType == Stack) {
      final stack = Stack<Object>();
      for (var e in elements) {
        stack.push(e);
      }
      return stack;
    } else if (dartType == ArrayList) {
      return ConversionAdapterUtils.getListResult(targetType, List<Object>.from(elements));
    }

    return ConversionAdapterUtils.getListResult(targetType, List<Object>.from(elements));
  }
}

/// {@template list_to_collection_converter}
/// A converter that transforms a [List] to a specific collection subtype.
///
/// Supported conversions:
/// - `List` → `List`
/// - `List` → `Set`
/// - `List` → `Queue`
/// - `List` → `Iterable`
/// - `List` → `ArrayList`
/// - `List` → `HashSet`
/// - `List` → `LinkedQueue`
/// - `List` → `LinkedList`
/// - `List` → `LinkedStack`
/// - `List` → `Stack`
/// - `List` → `col.LinkedHashSet`
/// - `List` → `col.ListBase`
/// - `List` → `col.SetBase`
/// - `List` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = ListToCollectionConverter();
/// print(converter.convert([1, 2, 3], Class<List>(null, PackageNames.DART), Class.forType(Set))); // prints: {1, 2, 3}
/// ```
/// {@endtemplate}
class ListToCollectionConverter extends CollectionToCollectionConverter {
  /// {@macro list_to_collection_converter}
  ListToCollectionConverter(ConversionService cs) : super(cs, Class<List>(null, PackageNames.DART));
}

/// {@template set_to_collection_converter}
/// A converter that transforms a [Set] to a specific collection subtype.
///
/// Supported conversions:
/// - `Set` → `Set`
/// - `Set` → `List`
/// - `Set` → `Queue`
/// - `Set` → `Iterable`
/// - `Set` → `ArrayList`
/// - `Set` → `HashSet`
/// - `Set` → `LinkedQueue`
/// - `Set` → `LinkedList`
/// - `Set` → `LinkedStack`
/// - `Set` → `Stack`
/// - `Set` → `col.LinkedHashSet`
/// - `Set` → `col.ListBase`
/// - `Set` → `col.SetBase`
/// - `Set` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = SetToCollectionConverter();
/// print(converter.convert({1, 2, 3}, Class.forType(Set), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class SetToCollectionGenericConverter extends CollectionToCollectionConverter {
  /// {@macro set_to_collection_converter}
  SetToCollectionGenericConverter(ConversionService cs) : super(cs, Class<Set>(null, PackageNames.DART));
}

/// {@template queue_to_collection_converter}
/// A converter that transforms a [Queue] to a specific collection subtype.
///
/// Supported conversions:
/// - `Queue` → `Queue`
/// - `Queue` → `List`
/// - `Queue` → `Set`
/// - `Queue` → `Iterable`
/// - `Queue` → `ArrayList`
/// - `Queue` → `HashSet`
/// - `Queue` → `LinkedQueue`
/// - `Queue` → `LinkedList`
/// - `Queue` → `LinkedStack`
/// - `Queue` → `Stack`
/// - `Queue` → `col.LinkedHashSet`
/// - `Queue` → `col.ListBase`
/// - `Queue` → `col.SetBase`
/// - `Queue` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = QueueToCollectionConverter();
/// print(converter.convert(Queue.from([1, 2, 3]), Class.forType(Queue), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class QueueToCollectionGenericConverter extends CollectionToCollectionConverter {
  /// {@macro queue_to_collection_converter}
  QueueToCollectionGenericConverter(ConversionService cs) : super(cs, Class<Queue>(null, PackageNames.LANG));
}

/// {@template iterable_to_collection_converter}
/// A converter that transforms an [Iterable] to a specific collection subtype.
///
/// Supported conversions:
/// - `Iterable` → `Iterable`
/// - `Iterable` → `List`
/// - `Iterable` → `Set`
/// - `Iterable` → `Queue`
/// - `Iterable` → `ArrayList`
/// - `Iterable` → `HashSet`
/// - `Iterable` → `LinkedQueue`
/// - `Iterable` → `LinkedList`
/// - `Iterable` → `LinkedStack`
/// - `Iterable` → `Stack`
/// - `Iterable` → `col.LinkedHashSet`
/// - `Iterable` → `col.ListBase`
/// - `Iterable` → `col.SetBase`
/// - `Iterable` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = IterableToCollectionConverter();
/// print(converter.convert([1, 2, 3], Class<Iterable>(null, PackageNames.DART), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class IterableToCollectionGenericConverter extends CollectionToCollectionConverter {
  /// {@macro iterable_to_collection_converter}
  IterableToCollectionGenericConverter(ConversionService cs) : super(cs, Class<Iterable>(null, PackageNames.DART));
}

/// {@template array_list_to_collection_converter}
/// A converter that transforms an [ArrayList] to a specific collection subtype.
///
/// Supported conversions:
/// - `ArrayList` → `ArrayList`
/// - `ArrayList` → `List`
/// - `ArrayList` → `Set`
/// - `ArrayList` → `Queue`
/// - `ArrayList` → `Iterable`
/// - `ArrayList` → `HashSet`
/// - `ArrayList` → `LinkedQueue`
/// - `ArrayList` → `LinkedList`
/// - `ArrayList` → `LinkedStack`
/// - `ArrayList` → `Stack`
/// - `ArrayList` → `col.LinkedHashSet`
/// - `ArrayList` → `col.ListBase`
/// - `ArrayList` → `col.SetBase`
/// - `ArrayList` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = ArrayListToCollectionConverter();
/// print(converter.convert(ArrayList.from([1, 2, 3]), Class.forType(ArrayList), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class ArrayListToCollectionGenericConverter extends CollectionToCollectionConverter {
  /// {@macro array_list_to_collection_converter}
  ArrayListToCollectionGenericConverter(ConversionService cs) : super(cs, Class<ArrayList>(null, PackageNames.LANG));
}

/// {@template set_base_to_collection_converter}
/// A converter that transforms a [col.SetBase] to a specific collection subtype.
///
/// Supported conversions:
/// - `col.SetBase` → `col.SetBase`
/// - `col.SetBase` → `Set`
/// - `col.SetBase` → `List`
/// - `col.SetBase` → `Queue`
/// - `col.SetBase` → `Iterable`
/// - `col.SetBase` → `HashSet`
/// - `col.SetBase` → `LinkedQueue`
/// - `col.SetBase` → `LinkedList`
/// - `col.SetBase` → `LinkedStack`
/// - `col.SetBase` → `Stack`
/// - `col.SetBase` → `col.LinkedHashSet`
/// - `col.SetBase` → `col.ListBase`
/// - `col.SetBase` → `col.SetBase`
/// - `col.SetBase` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = SetBaseToCollectionConverter();
/// print(converter.convert(SetBase.from([1, 2, 3]), Class.forType(SetBase), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class SetBaseToCollectionGenericConverter extends CollectionToCollectionConverter {
  /// {@macro set_base_to_collection_converter}
  SetBaseToCollectionGenericConverter(ConversionService cs) : super(cs, Class<col.SetBase>(null, PackageNames.DART));
}

/// {@template list_base_to_collection_converter}
/// A converter that transforms a [col.ListBase] to a specific collection subtype.
///
/// Supported conversions:
/// - `col.ListBase` → `col.ListBase`
/// - `col.ListBase` → `List`
/// - `col.ListBase` → `Set`
/// - `col.ListBase` → `Queue`
/// - `col.ListBase` → `Iterable`
/// - `col.ListBase` → `HashSet`
/// - `col.ListBase` → `LinkedQueue`
/// - `col.ListBase` → `LinkedList`
/// - `col.ListBase` → `LinkedStack`
/// - `col.ListBase` → `Stack`
/// - `col.ListBase` → `col.LinkedHashSet`
/// - `col.ListBase` → `col.ListBase`
/// - `col.ListBase` → `col.SetBase`
/// - `col.ListBase` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = ListBaseToCollectionConverter();
/// print(converter.convert(ListBase.from([1, 2, 3]), Class.forType(ListBase), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class ListBaseToCollectionConverter extends CollectionToCollectionConverter {
  /// {@macro list_base_to_collection_converter}
  ListBaseToCollectionConverter(ConversionService cs) : super(cs, Class<col.ListBase>(null, PackageNames.DART));
}

/// {@template linked_queue_to_collection_converter}
/// A converter that transforms a [LinkedQueue] to a specific collection subtype.
///
/// Supported conversions:
/// - `LinkedQueue` → `LinkedQueue`
/// - `LinkedQueue` → `Queue`
/// - `LinkedQueue` → `List`
/// - `LinkedQueue` → `Set`
/// - `LinkedQueue` → `Iterable`
/// - `LinkedQueue` → `HashSet`
/// - `LinkedQueue` → `LinkedQueue`
/// - `LinkedQueue` → `LinkedList`
/// - `LinkedQueue` → `LinkedStack`
/// - `LinkedQueue` → `Stack`
/// - `LinkedQueue` → `col.LinkedHashSet`
/// - `LinkedQueue` → `col.ListBase`
/// - `LinkedQueue` → `col.SetBase`
/// - `LinkedQueue` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = LinkedQueueToCollectionConverter();
/// print(converter.convert(LinkedQueue.from([1, 2, 3]), Class.forType(LinkedQueue), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class LinkedQueueToCollectionGenericConverter extends CollectionToCollectionConverter {
  /// {@macro linked_queue_to_collection_converter}
  LinkedQueueToCollectionGenericConverter(ConversionService cs) : super(cs, Class<LinkedQueue>(null, PackageNames.LANG));
}

/// {@template linked_list_to_collection_converter}
/// A converter that transforms a [LinkedList] to a specific collection subtype.
///
/// Supported conversions:
/// - `LinkedList` → `LinkedList`
/// - `LinkedList` → `Queue`
/// - `LinkedList` → `List`
/// - `LinkedList` → `Set`
/// - `LinkedList` → `Iterable`
/// - `LinkedList` → `HashSet`
/// - `LinkedList` → `LinkedQueue`
/// - `LinkedList` → `LinkedStack`
/// - `LinkedList` → `Stack`
/// - `LinkedList` → `col.LinkedHashSet`
/// - `LinkedList` → `col.ListBase`
/// - `LinkedList` → `col.SetBase`
/// - `LinkedList` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = LinkedListToCollectionConverter();
/// print(converter.convert(LinkedList.from([1, 2, 3]), Class.forType(LinkedList), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class LinkedListToCollectionGenericConverter extends CollectionToCollectionConverter {
  /// {@macro linked_list_to_collection_converter}
  LinkedListToCollectionGenericConverter(ConversionService cs) : super(cs, Class<LinkedList>(null, PackageNames.LANG));
}

/// {@template linked_hash_set_to_collection_converter}
/// A converter that transforms a [col.LinkedHashSet] to a specific collection subtype.
///
/// Supported conversions:
/// - `col.LinkedHashSet` → `col.LinkedHashSet`
/// - `col.LinkedHashSet` → `Set`
/// - `col.LinkedHashSet` → `List`
/// - `col.LinkedHashSet` → `Queue`
/// - `col.LinkedHashSet` → `Iterable`
/// - `col.LinkedHashSet` → `HashSet`
/// - `col.LinkedHashSet` → `LinkedQueue`
/// - `col.LinkedHashSet` → `LinkedStack`
/// - `col.LinkedHashSet` → `Stack`
/// - `col.LinkedHashSet` → `col.LinkedHashSet`
/// - `col.LinkedHashSet` → `col.ListBase`
/// - `col.LinkedHashSet` → `col.SetBase`
/// - `col.LinkedHashSet` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = LinkedHashSetToCollectionConverter();
/// print(converter.convert(LinkedHashSet.from([1, 2, 3]), Class.forType(LinkedHashSet), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class LinkedHashSetToCollectionGenericConverter extends CollectionToCollectionConverter {
  /// {@macro linked_hash_set_to_collection_converter}
  LinkedHashSetToCollectionGenericConverter(ConversionService cs) : super(cs, Class<col.LinkedHashSet>(null, PackageNames.DART));
}

/// {@template hash_set_to_collection_converter}
/// A converter that transforms a [HashSet] to a specific collection subtype.
///
/// Supported conversions:
/// - `HashSet` → `HashSet`
/// - `HashSet` → `Set`
/// - `HashSet` → `List`
/// - `HashSet` → `Queue`
/// - `HashSet` → `Iterable`
/// - `HashSet` → `LinkedHashSet`
/// - `HashSet` → `LinkedQueue`
/// - `HashSet` → `LinkedStack`
/// - `HashSet` → `Stack`
/// - `HashSet` → `col.LinkedHashSet`
/// - `HashSet` → `col.ListBase`
/// - `HashSet` → `col.SetBase`
/// - `HashSet` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = HashSetToCollectionConverter();
/// print(converter.convert(HashSet.from([1, 2, 3]), Class.forType(HashSet), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class HashSetToCollectionGenericConverter extends CollectionToCollectionConverter {
  /// {@macro hash_set_to_collection_converter}
  HashSetToCollectionGenericConverter(ConversionService cs) : super(cs, Class<HashSet>(null, PackageNames.LANG));
}

/// {@template stack_to_collection_converter}
/// A converter that transforms a [Stack] to a specific collection subtype.
///
/// Supported conversions:
/// - `Stack` → `Stack`
/// - `Stack` → `Queue`
/// - `Stack` → `List`
/// - `Stack` → `Set`
/// - `Stack` → `Iterable`
/// - `Stack` → `LinkedQueue`
/// - `Stack` → `LinkedStack`
/// - `Stack` → `col.LinkedHashSet`
/// - `Stack` → `col.ListBase`
/// - `Stack` → `col.SetBase`
/// - `Stack` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = StackToCollectionConverter();
/// print(converter.convert(Stack.from([1, 2, 3]), Class.forType(Stack), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class StackToCollectionGenericConverter extends CollectionToCollectionConverter {
  /// {@macro stack_to_collection_converter}
  StackToCollectionGenericConverter(ConversionService cs) : super(cs, Class<Stack>(null, PackageNames.LANG));
}

/// {@template linked_stack_to_collection_converter}
/// A converter that transforms a [LinkedStack] to a specific collection subtype.
///
/// Supported conversions:
/// - `LinkedStack` → `LinkedStack`
/// - `LinkedStack` → `Queue`
/// - `LinkedStack` → `List`
/// - `LinkedStack` → `Set`
/// - `LinkedStack` → `Iterable`
/// - `LinkedStack` → `LinkedQueue`
/// - `LinkedStack` → `LinkedStack`
/// - `LinkedStack` → `col.LinkedHashSet`
/// - `LinkedStack` → `col.ListBase`
/// - `LinkedStack` → `col.SetBase`
/// - `LinkedStack` → `col.Queue`
///
/// Example:
/// ```dart
/// final converter = LinkedStackToCollectionConverter();
/// print(converter.convert(LinkedStack.from([1, 2, 3]), Class.forType(LinkedStack), Class<List>(null, PackageNames.DART))); // prints: [1, 2, 3]
/// ```
/// {@endtemplate}
class LinkedStackToCollectionGenericConverter extends CollectionToCollectionConverter {
  /// {@macro linked_stack_to_collection_converter}
  LinkedStackToCollectionGenericConverter(ConversionService cs) : super(cs, Class<LinkedStack>(null, PackageNames.LANG));
}