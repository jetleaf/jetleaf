import 'dart:io';
import 'dart:typed_data';

import 'output_stream.dart';
import '../../exceptions.dart';

/// {@template file_output_stream}
/// A file output stream is an output stream for writing data to a [File] or
/// to a file descriptor.
/// 
/// [FileOutputStream] is meant for writing streams of raw bytes such as image data.
/// For writing streams of characters, consider using [FileWriter].
/// 
/// ## Example Usage
/// ```dart
/// // Writing binary data
/// final output = FileOutputStream('output.bin');
/// try {
///   final data = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47]); // PNG header
///   await output.writeBytes(data);
///   await output.flush();
/// } finally {
///   await output.close();
/// }
/// 
/// // Appending to existing file
/// final output = FileOutputStream('log.txt', append: true);
/// try {
///   await output.writeString('New log entry\n');
///   await output.flush();
/// } finally {
///   await output.close();
/// }
/// ```
/// 
/// {@endtemplate}
class FileOutputStream extends OutputStream {
  final File _file;
  final bool _append;
  RandomAccessFile? _randomAccessFile;
  int _position = 0;
  
  /// Creates a file output stream to write to the file with the specified name.
  /// 
  /// ## Parameters
  /// - [name]: The system-dependent filename
  /// - [append]: If true, bytes will be written to the end of the file rather
  ///   than the beginning (default: false)
  /// 
  /// ## Example
  /// ```dart
  /// // Create new file or overwrite existing
  /// final output = FileOutputStream('output.txt');
  /// 
  /// // Append to existing file
  /// final appendOutput = FileOutputStream('log.txt', append: true);
  /// ```
  /// 
  /// Throws [IOException] if the file exists but is a directory rather than
  /// a regular file, does not exist but cannot be created, or cannot be
  /// opened for any other reason.
  /// 
  /// {@macro file_output_stream}
  FileOutputStream(String name, {bool append = false}) : _file = File(name), _append = append;
  
  /// Creates a file output stream to write to the specified [File] object.
  /// 
  /// ## Parameters
  /// - [file]: The file to be opened for writing
  /// - [append]: If true, bytes will be written to the end of the file rather
  ///   than the beginning (default: false)
  /// 
  /// ## Example
  /// ```dart
  /// final file = File('output.bin');
  /// final output = FileOutputStream.fromFile(file);
  /// 
  /// // Append mode
  /// final appendOutput = FileOutputStream.fromFile(file, append: true);
  /// ```
  /// 
  /// Throws [IOException] if the file exists but is a directory rather than
  /// a regular file, does not exist but cannot be created, or cannot be
  /// opened for any other reason.
  /// 
  /// {@macro file_output_stream}
  FileOutputStream.fromFile(File file, {bool append = false}) : _file = file, _append = append;
  
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
  Future<void> writeByte(int b) async {
    await _ensureOpen();
    
    try {
      await _randomAccessFile!.writeByte(b & 0xFF);
      _position++;
    } catch (e) {
      throw IOException('Error writing to file: ${_file.path}', cause: e);
    }
  }
  
  @override
  Future<void> write(List<int> b, [int offset = 0, int? length]) async {
    await _ensureOpen();
    
    length ??= b.length - offset;
    
    if (offset < 0 || length < 0 || offset + length > b.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    if (length == 0) {
      return;
    }
    
    try {
      final bytes = Uint8List.fromList(b.sublist(offset, offset + length));
      await _randomAccessFile!.writeFrom(bytes);
      _position += length;
    } catch (e) {
      throw IOException('Error writing to file: ${_file.path}', cause: e);
    }
  }

  @override
  Future<void> writeObject(Object? obj) async {
    await _ensureOpen();
    
    try {
      await _randomAccessFile!.writeString(obj.toString());
    } catch (e) {
      throw IOException('Error writing to file: ${_file.path}', cause: e);
    }
  }
  
  @override
  Future<void> flush() async {
    await _ensureOpen();
    
    try {
      await _randomAccessFile!.flush();
    } catch (e) {
      throw IOException('Error flushing file: ${_file.path}', cause: e);
    }
  }
  
  @override
  Future<void> close() async {
    if (!isClosed) {
      try {
        if (_randomAccessFile != null) {
          await _randomAccessFile!.flush();
          await _randomAccessFile!.close();
        }
      } catch (e) {
        throw IOException('Error closing file: ${_file.path}', cause: e);
      } finally {
        _randomAccessFile = null;
        await super.close();
      }
    }
  }
  
  /// Returns the [File] object associated with this stream.
  /// 
  /// ## Returns
  /// The [File] object for this stream.
  /// 
  /// ## Example
  /// ```dart
  /// final output = FileOutputStream('output.bin');
  /// final file = output.file;
  /// print('Writing to: ${file.path}');
  /// ```
  File get file => _file;
  
  /// Returns the current position in the file.
  /// 
  /// ## Returns
  /// The current byte position in the file.
  /// 
  /// ## Example
  /// ```dart
  /// final output = FileOutputStream('output.bin');
  /// try {
  ///   await output.writeString('Hello');
  ///   print('Current position: ${output.position}'); // 5
  ///   
  ///   await output.writeString(' World');
  ///   print('Current position: ${output.position}'); // 11
  /// } finally {
  ///   await output.close();
  /// }
  /// ```
  int get position => _position;
  
  /// Returns whether this stream is in append mode.
  /// 
  /// ## Returns
  /// true if the stream appends to the end of the file, false if it overwrites.
  /// 
  /// ## Example
  /// ```dart
  /// final output1 = FileOutputStream('file.txt');
  /// print(output1.isAppendMode); // false
  /// 
  /// final output2 = FileOutputStream('file.txt', append: true);
  /// print(output2.isAppendMode); // true
  /// ```
  bool get isAppendMode => _append;
}