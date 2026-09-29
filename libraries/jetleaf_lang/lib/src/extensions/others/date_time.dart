extension DateTimeExtensions on DateTime {
  /// Checks if two DateTime objects represent the same date (year, month, and day).
  bool equals(DateTime date) => year == date.year && month == date.month && day == date.day;

  /// Checks if two DateTime objects represent the same date (year, month, and day).
  bool isEqualTo(DateTime date) => equals(date);

  /// Checks if two DateTime objects represent the same date (year, month, and day).
  bool notEquals(DateTime date) => !equals(date);

  /// Checks if two DateTime objects represent the same date (year, month, and day).
  bool isNotEqualTo(DateTime date) => notEquals(date);
}