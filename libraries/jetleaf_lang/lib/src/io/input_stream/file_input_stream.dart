import 'dart:io';

import 'input_stream.dart';
import '../../exceptions.dart';

/// {@template file_input_stream}
/// A [FileInputStream] obtains input bytes from a file in a file system.
/// 
/// [FileInputStream] is meant for reading streams of raw bytes such as image data.
/// For reading streams of characters, consider using [FileReader].
/// 
/// ## Example Usage
/// ```dart
/// // Reading a binary file
/// final input = FileInputStream('image.png');
/// try {
///   final header = await input.readFully(8); // Read PNG header
///   if (isPngHeader(header)) {
///     final imageData = await input.readAll();
///     processImage(imageData);
///   }
/// } finally {
///   await input.close();
/// }
/// 
/// // Reading with buffer
/// final input = FileInputStream('data.bin');
/// try {
///   final buffer = Uint8List(1024);
///   int bytesRead;
///   while ((bytesRead = await input.read(buffer)) != -1) {
///     processChunk(buffer.sublist(0, bytesRead));
///   }
/// } finally {
///   await input.close();
/// }
/// ```
/// 
/// {@endtemplate}
class FileInputStream extends InputStream {
  final File _file;
  RandomAccessFile? _randomAccessFile;
  int _position = 0;
  
  /// Creates a [FileInputStream] by opening a connection to an actual file,
  /// the file named by the path name [name] in the file system.
  /// 
  /// ## Parameters
  /// - [name]: The system-dependent filename
  /// 
  /// ## Example
  /// ```dart
  /// final input = FileInputStream('data.bin');
  /// try {
  ///   final data = await input.readAll();
  ///   processData(data);
  /// } finally {
  ///   await input.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if the named file does not exist, is a directory
  /// rather than a regular file, or for some other reason cannot be opened
  /// for reading.
  /// 
  /// {@macro file_input_stream}
  FileInputStream(String name) : _file = File(name);
  
  /// Creates a [FileInputStream] by opening a connection to an actual file,
  /// the file named by the [File] object [file] in the file system.
  /// 
  /// ## Parameters
  /// - [file]: The file to be opened for reading
  /// 
  /// ## Example
  /// ```dart
  /// final file = File('data.bin');
  /// final input = FileInputStream.fromFile(file);
  /// try {
  ///   final data = await input.readAll();
  ///   processData(data);
  /// } finally {
  ///   await input.close();
  /// }
  /// ```
  /// 
  /// Throws [IOException] if the file does not exist, is a directory rather
  /// than a regular file, or for some other reason cannot be opened for reading.
  /// 
  /// {@macro file_input_stream}
  FileInputStream.fromFile(File file) : _file = file;
  
  /// Ensures the file is open for reading.
  Future<void> _ensureOpen() async {
    checkClosed();
    
    if (_randomAccessFile == null) {
      try {
        _randomAccessFile = await _file.open(mode: FileMode.read);
      } catch (e) {
        throw IOException('Cannot open file: ${_file.path}', cause: e);
      }
    }
  }
  
  @override
  Future<int> readByte() async {
    await _ensureOpen();
    
    try {
      final bytes = await _randomAccessFile!.read(1);
      if (bytes.isEmpty) {
        return -1; // End of file
      }
      _position++;
      return bytes[0];
    } catch (e) {
      throw IOException('Error reading from file: ${_file.path}', cause: e);
    }
  }
  
  @override
  Future<int> read(List<int> b, [int offset = 0, int? length]) async {
    await _ensureOpen();
    
    length ??= b.length - offset;
    
    if (offset < 0 || length < 0 || offset + length > b.length) {
      throw InvalidArgumentException('Invalid offset or length');
    }
    
    if (length == 0) {
      return 0;
    }
    
    try {
      final bytes = await _randomAccessFile!.read(length);
      if (bytes.isEmpty) {
        return -1; // End of file
      }
      
      final bytesRead = bytes.length;
      for (int i = 0; i < bytesRead; i++) {
        b[offset + i] = bytes[i];
      }
      
      _position += bytesRead;
      return bytesRead;
    } catch (e) {
      throw IOException('Error reading from file: ${_file.path}', cause: e);
    }
  }
  
  @override
  Future<int> skip(int n) async {
    await _ensureOpen();
    
    if (n <= 0) {
      return 0;
    }
    
    try {
      final currentPosition = await _randomAccessFile!.position();
      final fileLength = await _randomAccessFile!.length();
      final maxSkip = fileLength - currentPosition;
      final actualSkip = n.clamp(0, maxSkip.toInt());
      
      if (actualSkip > 0) {
        await _randomAccessFile!.setPosition(currentPosition + actualSkip);
        _position += actualSkip;
      }
      
      return actualSkip;
    } catch (e) {
      throw IOException('Error skipping in file: ${_file.path}', cause: e);
    }
  }
  
  @override
  Future<int> available() async {
    await _ensureOpen();
    
    try {
      final currentPosition = await _randomAccessFile!.position();
      final fileLength = await _randomAccessFile!.length();
      return (fileLength - currentPosition).clamp(0, double.infinity).toInt();
    } catch (e) {
      throw IOException('Error getting available bytes: ${_file.path}', cause: e);
    }
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
  /// final input = FileInputStream('data.bin');
  /// final file = input.file;
  /// print('Reading from: ${file.path}');
  /// print('File size: ${await file.length()} bytes');
  /// ```
  File get file => _file;
  
  /// Returns the current position in the file.
  /// 
  /// ## Returns
  /// The current byte position in the file.
  /// 
  /// ## Example
  /// ```dart
  /// final input = FileInputStream('data.bin');
  /// try {
  ///   await input.readFully(100);
  ///   print('Current position: ${input.position}'); // 100
  ///   
  ///   await input.skip(50);
  ///   print('Current position: ${input.position}'); // 150
  /// } finally {
  ///   await input.close();
  /// }
  /// ```
  int get position => _position;
}