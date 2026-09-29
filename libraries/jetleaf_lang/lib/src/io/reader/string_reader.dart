import '../../exceptions.dart';
import 'reader.dart';

/// {@template string_reader}
/// A [Reader] implementation that reads characters from a [String] buffer.
///
/// This reader allows sequential, asynchronous reading of characters or
/// character blocks from an in-memory string.
///
/// Common use case:
/// ```dart
/// final reader = StringReader('hello');
/// final buffer = List<int>.filled(5, 0);
/// final read = await reader.read(buffer); // buffer now contains [104, 101, 108, 108, 111]
/// await reader.close();
/// ```
///
/// The reader supports mark/reset operations for backtracking.
/// {@endtemplate}
class StringReader extends Reader {
  final String _buffer;
  int _position = 0;
  int _markedPosition = 0;

  /// {@macro string_reader}
  StringReader(this._buffer);

  @override
  Future<int> readChar() async {
    checkClosed();
    if (_position >= _buffer.length) {
      return -1; // End of stream
    }
    return _buffer.codeUnitAt(_position++);
  }

  @override
  Future<int> read(List<int> cbuf, [int offset = 0, int? length]) async {
    checkClosed();
    length ??= cbuf.length - offset;

    if (offset < 0 || length < 0 || offset + length > cbuf.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }

    if (length == 0) {
      return 0;
    }

    if (_position >= _buffer.length) {
      return -1; // End of stream
    }

    final charsAvailable = _buffer.length - _position;
    final charsToRead = length.clamp(0, charsAvailable);

    if (charsToRead == 0) {
      return 0;
    }

    for (int i = 0; i < charsToRead; i++) {
      cbuf[offset + i] = _buffer.codeUnitAt(_position + i);
    }
    _position += charsToRead;
    return charsToRead;
  }

  @override
  Future<bool> ready() async {
    checkClosed();
    return _position < _buffer.length;
  }

  @override
  bool markSupported() => true;

  @override
  void mark(int readAheadLimit) {
    checkClosed();
    _markedPosition = _position;
  }

  @override
  Future<void> reset() async {
    checkClosed();
    _position = _markedPosition;
  }

  @override
  Future<void> close() async {
    // No external resources to close for an in-memory stream
    super.close();
  }
}