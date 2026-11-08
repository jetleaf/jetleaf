import '../../commons/typedefs.dart';

extension TypeExtension on Type {
  /// Generalized equality check to simplify type checking.
  ///
  /// This method allows for a cleaner way of comparing types
  bool equals(Type type) => this == Type || this == type || runtimeType == type;

  /// Checks if the given [this] is of type [Type].
  bool isEqualTo(Type type) => equals(type);

  /// Checks if the given [this] is of type [Type].
  bool isNotEqualTo(Type type) => !equals(type);

  /// Checks if the given [this] is of type [JsonMap].
  bool get isJsonMap => equals(JsonMap);

  /// Checks if the given [this] is of type [JsonMapCollection].
  bool get isJsonMapCollection => equals(JsonMapCollection);

  /// Checks if the given [this] is of type [JsonString].
  bool get isJsonString => equals(JsonString);

  /// Checks if the given [this] is a [StringCollection].
  bool get isStringCollection => equals(StringCollection);

  /// Checks if the given [this] is a [StringSet].
  bool get isStringSet => equals(StringSet);

  /// Checks if the given [this] is an [IntCollection].
  bool get isIntCollection => equals(IntCollection);

  /// Checks if the given [this] is an [IntSet].
  bool get isIntSet => equals(IntSet);

  /// Checks if the given [this] is a [BoolCollection].
  bool get isBoolCollection => equals(BoolCollection);

  /// Checks if the given [this] is a [BoolSet].
  bool get isBoolSet => equals(BoolSet);

  /// Checks if the given [this] is a [DateTimeCollection].
  bool get isDateTimeCollection => equals(DateTimeCollection);

  /// Checks if the given [this] is a [DateTimeSet].
  bool get isDateTimeSet => equals(DateTimeSet);

  /// Checks if the given [this] is a [Int].
  bool get isInt => equals(Int);

  /// Checks if the given [this] is a [DurationCollection].
  bool get isDurationCollection => equals(DurationCollection);

  /// Checks if the given [this] is a [DurationSet].
  bool get isDurationSet => equals(DurationSet);

  /// Checks if the given [this] is a [Bool].
  bool get isBool => equals(Bool);
}