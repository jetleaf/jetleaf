import 'dart:io';
import 'dart:convert';

import '../base.dart';
import 'reader.dart';
import '../../exceptions.dart';

/// {@template file_reader}
/// Convenience class for reading character files.
/// 
/// The constructors of this class assume that the default character encoding
/// and the default byte-buffer size are appropriate. To specify these values
/// yourself, construct an [InputStreamReader] on a [FileInputStream].
/// 
/// [FileReader] is meant for reading streams of characters. For reading streams
/// of raw bytes, consider using [FileInputStream].
/// 
/// ## Example Usage
/// ```dart
/// // Reading a text file
/// final reader = FileReader('document.txt');
/// try {
///   final content = await reader.readAll();
///   print('Document content: $content');
/// } finally {
///   await reader.close();
/// }
/// 
/// // Reading line by line
/// final reader = FileReader('data.txt');
/// try {
///   String? line;
///   int lineNumber = 1;
///   while ((line = await reader.readLine()) != null) {
///     print('Line $lineNumber: $line');
///     lineNumber++;
///   }
/// } finally {
///   await reader.close();
/// }
/// ```
/// 
/// {@endtemplate}
class FileReader extends Reader {
  final File _file;
  final Encoding _encoding;
  RandomAccessFile? _randomAccessFile;
  String? _buffer;
  int _bufferPosition = 0;
  bool _bufferLoaded = false;
  
  /// Creates a new [FileReader], given the name of the file to read from.
  /// 
  /// ## Parameters
  /// - [fileName]: The name of the file to read from
  /// - [encoding]: The character encoding to use (default: Closeable.DEFAULT_ENCODING)
  /// 
  /// ## Example
  /// ```dart
  /// final reader = FileReader('document.txt');
  /// final utf16Reader = FileReader('unicode.txt', cause: encoding: utf16);
  /// ```
  /// 
  /// Throws [IOException] if the named file does not exist, is a directory
  /// rather than a regular file, or for some other reason cannot be opened
  /// for reading.
  /// 
  /// {@macro file_reader}
  FileReader(String fileName, {Encoding encoding = Closeable.DEFAULT_ENCODING}) 
      : _file = File(fileName), _encoding = encoding;
  
  /// Creates a new [FileReader], given the [File] to read from.
  /// 
  /// ## Parameters
  /// - [file]: The [File] to read from
  /// - [encoding]: The character encoding to use (default: Closeable.DEFAULT_ENCODING)
  /// 
  /// ## Example
  /// ```dart
  /// final file = File('document.txt');
  /// final reader = FileReader.fromFile(file);
  /// ```
  /// 
  /// Throws [IOException] if the file does not exist, is a directory rather
  /// than a regular file, or for some other reason cannot be opened for reading.
  /// 
  /// {@macro file_reader}
  FileReader.fromFile(File file, {Encoding encoding = Closeable.DEFAULT_ENCODING}) 
      : _file = file, _encoding = encoding;
  
  /// Ensures the file is open and the buffer is loaded.
  Future<void> _ensureOpen() async {
    checkClosed();
    
    if (_randomAccessFile == null) {
      try {
        _randomAccessFile = await _file.open(mode: FileMode.read);
      } catch (e) {
        throw IOException('Cannot open file: ${_file.path}', cause: e);
      }
    }
    
    if (!_bufferLoaded) {
      await _loadBuffer();
    }
  }
  
  /// Loads the entire file content into the buffer.
  Future<void> _loadBuffer() async {
    try {
      final length = await _randomAccessFile!.length();
      final bytes = await _randomAccessFile!.read(length);
      _buffer = _encoding.decode(bytes);
      _bufferLoaded = true;
      _bufferPosition = 0;
    } catch (e) {
      throw IOException('Error reading file: ${_file.path}', cause: e);
    }
  }
  
  @override
  Future<int> readChar() async {
    await _ensureOpen();
    
    if (_buffer == null || _bufferPosition >= _buffer!.length) {
      return -1; // End of file
    }
    
    final char = _buffer!.codeUnitAt(_bufferPosition);
    _bufferPosition++;
    return char;
  }
  
  @override
  Future<int> read(List<int> cbuf, [int offset = 0, int? length]) async {
    length ??= cbuf.length - offset;
    
    if (offset < 0 || length < 0 || offset + length > cbuf.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    if (length == 0) {
      return 0;
    }

    await _ensureOpen();
    
    if (_buffer == null || _bufferPosition >= _buffer!.length) {
      return -1; // End of file
    }
    
    final availableChars = _buffer!.length - _bufferPosition;
    final charsToRead = length.clamp(0, availableChars);
    
    for (int i = 0; i < charsToRead; i++) {
      cbuf[offset + i] = _buffer!.codeUnitAt(_bufferPosition + i);
    }
    
    _bufferPosition += charsToRead;
    return charsToRead;
  }
  
  @override
  Future<String?> readLine() async {
    await _ensureOpen();
    
    if (_buffer == null || _bufferPosition >= _buffer!.length) {
      return null; // End of file
    }
    
    final startPosition = _bufferPosition;
    int endPosition = startPosition;
    
    // Find the end of the line
    while (endPosition < _buffer!.length) {
      final char = _buffer!.codeUnitAt(endPosition);
      if (char == 10) { // '\n'
        break;
      } else if (char == 13) { // '\r'
        // Check for '\r\n'
        if (endPosition + 1 < _buffer!.length && 
            _buffer!.codeUnitAt(endPosition + 1) == 10) {
          endPosition++; // Skip the '\n' as well
        }
        break;
      }
      endPosition++;
    }
    
    final line = _buffer!.substring(startPosition, endPosition);
    
    // Move past the line terminator
    if (endPosition < _buffer!.length) {
      _bufferPosition = endPosition + 1;
    } else {
      _bufferPosition = endPosition;
    }
    
    return line;
  }
  
  @override
  Future<String> readAll() async {
    await _ensureOpen();
    
    if (_buffer == null) {
      return '';
    }
    
    final result = _buffer!.substring(_bufferPosition);
    _bufferPosition = _buffer!.length;
    return result;
  }
  
  @override
  Future<int> skip(int n) async {
    await _ensureOpen();
    
    if (n <= 0 || _buffer == null) {
      return 0;
    }
    
    final availableChars = _buffer!.length - _bufferPosition;
    final charsToSkip = n.clamp(0, availableChars);
    _bufferPosition += charsToSkip;
    return charsToSkip;
  }
  
  @override
  Future<bool> ready() async {
    await _ensureOpen();
    return _buffer != null && _bufferPosition < _buffer!.length;
  }
  
  @override
  Future<void> close() async {
    if (!isClosed) {
      try {
        await _randomAccessFile?.close();
      } catch (e) {
        throw IOException('Error closing file: ${_file.path}', cause: e);
      } finally {
        _randomAccessFile = null;
        _buffer = null;
        _bufferLoaded = false;
        _bufferPosition = 0;
        await super.close();
      }
    }
  }
  
  /// Returns the [File] object associated with this reader.
  /// 
  /// ## Returns
  /// The [File] object for this reader.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = FileReader('document.txt');
  /// final file = reader.file;
  /// print('Reading from: ${file.path}');
  /// print('File size: ${await file.length()} bytes');
  /// ```
  File get file => _file;
  
  /// Returns the encoding used by this reader.
  /// 
  /// ## Returns
  /// The [Encoding] used to decode the file.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = FileReader('document.txt', cause: encoding: utf16);
  /// print('Using encoding: ${reader.encoding.name}');
  /// ```
  Encoding get encoding => _encoding;
  
  /// Returns the current character position in the file.
  /// 
  /// ## Returns
  /// The current character position.
  /// 
  /// ## Example
  /// ```dart
  /// final reader = FileReader('document.txt');
  /// try {
  ///   await reader.readLine();
  ///   print('Current position: ${reader.position}');
  /// } finally {
  ///   await reader.close();
  /// }
  /// ```
  int get position => _bufferPosition;
}