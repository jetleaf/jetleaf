/// {@template predicate}
/// A function that takes a value of type [T] and returns a boolean.
///
/// Used for testing or filtering values in collections or streams.
///
/// {@tool snippet}
/// ```dart
/// final Predicate<int> isOdd = (value) => value.isOdd;
/// print(isOdd(3)); // true
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef Predicate<T> = Bool Function(T value);

/// {@template accumulator}
/// A function used to accumulate values in reduction operations.
///
/// Takes an accumulator of type [U] and a current value of type [T],
/// returning a new accumulator.
///
/// {@tool snippet}
/// ```dart
/// final Accumulator<int, int> sum = (acc, value) => acc + value;
/// final total = [1, 2, 3, 4].reduce((a, b) => sum(a, b));
/// print(total); // 10
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef Accumulator<T, U> = U Function(U, T);

/// {@template data_mapper}
/// A function that transforms a value from type [T] to type [U].
///
/// Commonly used for mapping values in functional programming.
///
/// {@tool snippet}
/// ```dart
/// final DataMapper<String, int> lengthMapper = (s) => s.length;
/// print(lengthMapper('hello')); // 5
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef DataMapper<T, U> = U Function(T value);

/// {@template consumer}
/// A function that consumes a value of type [T] without returning anything.
///
/// Useful for triggering side effects like logging or UI updates.
///
/// {@tool snippet}
/// ```dart
/// final Consumer<String> printUpper = (value) => print(value.toUpperCase());
/// printUpper('hello'); // HELLO
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef Consumer<T> = void Function(T value);

/// {@template supplier}
/// A function that supplies a value of type [T], typically lazily or on-demand.
///
/// Useful for factories or deferred value generation.
///
/// {@tool snippet}
/// ```dart
/// final Supplier<DateTime> now = () => DateTime.now();
/// print(now());
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef Supplier<T> = T Function();

/// {@template exception_supplier}
/// A function that returns an exception object to be thrown when needed.
///
/// Useful for lazy error throwing or assertion mechanisms.
///
/// {@tool snippet}
/// ```dart
/// final ExceptionSupplier notFound = () => Exception('Item not found');
/// throw notFound();
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef ExceptionSupplier = Object Function();

/// {@template json_map}
/// A JSON-like structure represented as a `Map<String, dynamic>`.
///
/// Common in APIs and data storage layers.
///
/// {@tool snippet}
/// ```dart
/// JsonMap user = {'name': 'Alice', 'age': 30};
/// print(user['name']); // Alice
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef JsonMap = Map<String, dynamic>;

/// {@template json_map_collection}
/// A list of JSON-like maps, useful for handling multiple entities.
///
/// {@tool snippet}
/// ```dart
/// JsonMapCollection users = [
///   {'name': 'Alice'},
///   {'name': 'Bob'}
/// ];
/// print(users.length); // 2
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef JsonMapCollection = List<JsonMap>;

/// {@template string_collection}
/// A list of strings.
///
/// {@tool snippet}
/// ```dart
/// StringCollection tags = ['dart', 'flutter', 'backend'];
/// print(tags.contains('flutter')); // true
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef StringCollection = List<String>;

/// {@template string_set}
/// A set of unique strings.
///
/// {@tool snippet}
/// ```dart
/// StringSet uniqueTags = {'dart', 'flutter', 'dart'};
/// print(uniqueTags.length); // 2
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef StringSet = Set<String>;

/// {@template json_string}
/// A map of string keys and string values representing simple string-based JSON data.
///
/// {@tool snippet}
/// ```dart
/// JsonString config = {'host': 'localhost', 'port': '8080'};
/// print(config['port']); // 8080
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef JsonString = Map<String, String>;

/// {@template int_alias}
/// A shorthand alias for an integer value.
/// {@endtemplate}
typedef Int = int;

/// {@template int_collection}
/// A list of integers using the `Int` alias.
///
/// {@tool snippet}
/// ```dart
/// IntCollection numbers = [1, 2, 3, 4];
/// print(numbers.reduce((a, b) => a + b)); // 10
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef IntCollection = List<Int>;

/// {@template int_set}
/// A set of unique integers using the `Int` alias.
///
/// {@tool snippet}
/// ```dart
/// IntSet scores = {100, 200, 300};
/// print(scores.contains(200)); // true
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef IntSet = Set<Int>;

/// {@template bool_alias}
/// An alias for the built-in `bool` type.
/// {@endtemplate}
typedef Bool = bool;

/// {@template bool_collection}
/// A list of boolean values using the `Bool` alias.
///
/// {@tool snippet}
/// ```dart
/// BoolCollection flags = [true, false, true];
/// print(flags.where((f) => f).length); // 2
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef BoolCollection = List<Bool>;

/// {@template bool_set}
/// A set of unique boolean values using the `Bool` alias.
///
/// {@tool snippet}
/// ```dart
/// BoolSet truthValues = {true, false};
/// print(truthValues.length); // 2
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef BoolSet = Set<Bool>;

/// {@template date_time_collection}
/// A list of `DateTime` values.
///
/// {@tool snippet}
/// ```dart
/// DateTimeCollection timestamps = [DateTime.now(), DateTime.utc(2024)];
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef DateTimeCollection = List<DateTime>;

/// {@template date_time_set}
/// A set of unique `DateTime` values.
///
/// {@tool snippet}
/// ```dart
/// DateTimeSet moments = {DateTime.utc(2024), DateTime.utc(2025)};
/// print(moments.length); // 2
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef DateTimeSet = Set<DateTime>;

/// {@template duration_collection}
/// A list of `Duration` values.
///
/// {@tool snippet}
/// ```dart
/// DurationCollection delays = [Duration(seconds: 1), Duration(minutes: 1)];
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef DurationCollection = List<Duration>;

/// {@template duration_set}
/// A set of unique `Duration` values.
///
/// {@tool snippet}
/// ```dart
/// DurationSet timeouts = {Duration(seconds: 5), Duration(seconds: 10)};
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef DurationSet = Set<Duration>;

/// {@template condition_tester}
/// A typedef for a predicate function that tests a condition on a value of type [T].
///
/// {@tool snippet}
/// ```dart
/// typedef IsEven = ConditionTester<int>;
///
/// IsEven isEven = (int number) => number % 2 == 0;
/// final evenNumbers = [1, 2, 3, 4].where(isEven).toList();
/// print(evenNumbers); // [2, 4]
/// ```
/// {@end-tool}
/// {@endtemplate}
typedef ConditionTester<T> = bool Function(T value);