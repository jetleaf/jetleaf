import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import '../base.dart';
import 'writer.dart';
import '../../exceptions.dart';

/// {@template file_writer}
/// Convenience class for writing character files.
/// 
/// The constructors of this class assume that the default character encoding
/// and the default byte-buffer size are appropriate. To specify these values
/// yourself, construct an [OutputStreamWriter] on a [FileOutputStream].
/// 
/// [FileWriter] is meant for writing streams of characters. For writing streams
/// of raw bytes, consider using [FileOutputStream].
/// 
/// ## Example Usage
/// ```dart
/// // Writing to a text file
/// final writer = FileWriter('output.txt');
/// try {
///   await writer.write('Hello, World!');
///   await writer.writeLine();
///   await writer.writeLine('This is a new line.');
///   await writer.flush();
/// } finally {
///   await writer.close();
/// }
/// 
/// // Appending to existing file
/// final writer = FileWriter('log.txt', append: true);
/// try {
///   await writer.writeLine('${DateTime.now()}: New log entry');
///   await writer.flush();
/// } finally {
///   await writer.close();
/// }
/// ```
/// 
/// {@endtemplate}
class FileWriter extends Writer {
  final File _file;
  final bool _append;
  final Encoding _encoding;
  RandomAccessFile? _randomAccessFile;
  final List<int> _buffer = <int>[];
  int _position = 0;
  
  /// Creates a new [FileWriter], given the name of the file to write to.
  /// 
  /// ## Parameters
  /// - [fileName]: The name of the file to write to
  /// - [append]: If true, characters will be written to the end of the file
  ///   rather than the beginning (default: false)
  /// - [encoding]: The character encoding to use (default: Closeable.DEFAULT_ENCODING)
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// final appendWriter = FileWriter('log.txt', append: true);
  /// final utf16Writer = FileWriter('unicode.txt', encoding: utf16);
  /// ```
  /// 
  /// Throws [IOException] if the file exists but is a directory rather than
  /// a regular file, does not exist but cannot be created, or cannot be
  /// opened for any other reason.
  /// 
  /// {@macro file_writer}
  FileWriter(String fileName, {bool append = false, Encoding encoding = Closeable.DEFAULT_ENCODING}) 
      : _file = File(fileName), _append = append, _encoding = encoding;
  
  /// Creates a new [FileWriter], given the [File] to write to.
  /// 
  /// ## Parameters
  /// - [file]: The [File] to write to
  /// - [append]: If true, characters will be written to the end of the file
  ///   rather than the beginning (default: false)
  /// - [encoding]: The character encoding to use (default: Closeable.DEFAULT_ENCODING)
  /// 
  /// ## Example
  /// ```dart
  /// final file = File('output.txt');
  /// final writer = FileWriter.fromFile(file);
  /// final appendWriter = FileWriter.fromFile(file, append: true);
  /// ```
  /// 
  /// Throws [IOException] if the file exists but is a directory rather than
  /// a regular file, does not exist but cannot be created, or cannot be
  /// opened for any other reason.
  /// 
  /// {@macro file_writer}
  FileWriter.fromFile(File file, {bool append = false, Encoding encoding = Closeable.DEFAULT_ENCODING}) 
      : _file = file, _append = append, _encoding = encoding;
  
  /// Ensures the file is open for writing.
  Future<void> _ensureOpen() async {
    checkClosed();
    
    if (_randomAccessFile == null) {
      try {
        final mode = _append ? FileMode.append : FileMode.write;
        _randomAccessFile = await _file.open(mode: mode);
        
        if (_append) {
          _position = await _randomAccessFile!.length();
        }
      } catch (e) {
        throw IOException('Cannot open file: ${_file.path}', cause: e);
      }
    }
  }
  
  @override
  Future<void> writeChar(int c) async {
    await _ensureOpen();
    _buffer.add(c & 0xFFFF); // Keep only the low 16 bits
  }
  
  @override
  Future<void> writeChars(List<int> cbuf, [int offset = 0, int? length]) async {
    await _ensureOpen();
    
    length ??= cbuf.length - offset;
    
    if (offset < 0 || length < 0 || offset + length > cbuf.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    for (int i = 0; i < length; i++) {
      _buffer.add(cbuf[offset + i] & 0xFFFF);
    }
  }
  
  @override
  Future<void> write(String str, [int offset = 0, int? length]) async {
    await _ensureOpen();
    
    length ??= str.length - offset;
    
    if (offset < 0 || length < 0 || offset + length > str.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    final substring = str.substring(offset, offset + length);
    _buffer.addAll(substring.codeUnits);
  }
  
  @override
  Future<void> flush() async {
    await _ensureOpen();
    
    if (_buffer.isNotEmpty) {
      try {
        final text = String.fromCharCodes(_buffer);
        final bytes = _encoding.encode(text);
        await _randomAccessFile!.writeFrom(Uint8List.fromList(bytes));
        await _randomAccessFile!.flush();
        _position += bytes.length;
        _buffer.clear();
      } catch (e) {
        throw IOException('Error writing to file: ${_file.path}', cause: e);
      }
    }
  }
  
  @override
  Future<void> close() async {
    if (!isClosed) {
      try {
        await flush();
        await _randomAccessFile?.close();
      } catch (e) {
        throw IOException('Error closing file: ${_file.path}', cause: e);
      } finally {
        _randomAccessFile = null;
        _buffer.clear();
        await super.close();
      }
    }
  }
  
  /// Returns the [File] object associated with this writer.
  /// 
  /// ## Returns
  /// The [File] object for this writer.
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// final file = writer.file;
  /// print('Writing to: ${file.path}');
  /// ```
  File get file => _file;
  
  /// Returns whether this writer is in append mode.
  /// 
  /// ## Returns
  /// true if the writer appends to the end of the file, false if it overwrites.
  /// 
  /// ## Example
  /// ```dart
  /// final writer1 = FileWriter('file.txt');
  /// print(writer1.isAppendMode); // false
  /// 
  /// final writer2 = FileWriter('file.txt', append: true);
  /// print(writer2.isAppendMode); // true
  /// ```
  bool get isAppendMode => _append;
  
  /// Returns the encoding used by this writer.
  /// 
  /// ## Returns
  /// The [Encoding] used to encode characters to bytes.
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt', encoding: utf16);
  /// print('Using encoding: ${writer.encoding.name}');
  /// ```
  Encoding get encoding => _encoding;
  
  /// Returns the current byte position in the file.
  /// 
  /// ## Returns
  /// The current byte position.
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// try {
  ///   await writer.write('Hello');
  ///   await writer.flush();
  ///   print('Current position: ${writer.position}');
  /// } finally {
  ///   await writer.close();
  /// }
  /// ```
  int get position => _position;
  
  /// Returns the number of characters currently in the buffer.
  /// 
  /// ## Returns
  /// The number of characters waiting to be flushed.
  /// 
  /// ## Example
  /// ```dart
  /// final writer = FileWriter('output.txt');
  /// try {
  ///   await writer.write('Hello');
  ///   print('Buffered characters: ${writer.bufferedCount}'); // 5
  ///   
  ///   await writer.flush();
  ///   print('Buffered characters: ${writer.bufferedCount}'); // 0
  /// } finally {
  ///   await writer.close();
  /// }
  /// ```
  int get bufferedCount => _buffer.length;
}