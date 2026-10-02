import 'package:jetleaf_build/jetleaf_build.dart';

import '../exceptions.dart';
import 'base_stream/generic/generic_stream.dart';

/// {@template stream_builder}
/// A mutable builder for a [GenericStream].
/// 
/// This allows the creation of a [GenericStream] by generating elements individually
/// and adding them to the builder (without the copying overhead that comes from
/// using a [List] as a temporary buffer.)
/// 
/// A stream builder has a lifecycle, which starts in a building phase, during which
/// elements can be added, and then transitions to a built phase, after which no more
/// elements can be added. The built phase begins begins when the [build] method is called,
/// which creates an ordered [GenericStream] whose elements are the elements that were added
/// to the stream builder, in the order they were added.
/// 
/// ## Example Usage
/// ```dart
/// final builder = StreamBuilder<String>();
/// builder.add('Hello');
/// builder.add('World');
/// final stream = builder.build();
/// print(stream.toList()); // ['Hello', 'World']
/// ```
/// 
/// {@endtemplate}
@Generic(StreamBuilder)
class StreamBuilder<T> {
  /// {@macro stream_builder}
  StreamBuilder();

  final List<T> _elements = <T>[];
  bool _built = false;

  /// Adds an element to the stream being built.
  /// 
  /// Throws [NoGuaranteeException] if the builder has already been built.
  /// 
  /// ## Example
  /// ```dart
  /// builder.add('Hello');
  /// builder.add('World');
  /// ```
  StreamBuilder<T> add(T element) {
    if (_built) {
      throw NoGuaranteeException('StreamBuilder has already been built');
    }
    _elements.add(element);
    return this;
  }

  /// Adds all elements from the given iterable to the stream being built.
  /// 
  /// Throws [NoGuaranteeException] if the builder has already been built.
  /// 
  /// ## Example
  /// ```dart
  /// builder.addAll(['Hello', 'World', '!']);
  /// ```
  StreamBuilder<T> addAll(Iterable<T> elements) {
    if (_built) {
      throw NoGuaranteeException('StreamBuilder has already been built');
    }
    _elements.addAll(elements);
    return this;
  }

  /// Builds the stream, transitioning this builder to the built state.
  /// If there are further attempts to operate on the builder after it has
  /// entered the built state, [NoGuaranteeException] is thrown.
  /// 
  /// ## Example
  /// ```dart
  /// final stream = builder.build();
  /// ```
  /// 
  /// {@macro generic_stream}
  GenericStream<T> build() {
    if (_built) {
      throw NoGuaranteeException('StreamBuilder has already been built');
    }
    _built = true;
    return GenericStream.of(List<T>.from(_elements));
  }
}