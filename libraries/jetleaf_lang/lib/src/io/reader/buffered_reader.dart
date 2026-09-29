import 'reader.dart';
import '../../exceptions.dart';

/// {@template buffered_reader}
/// Reads text from a character-input stream, buffering characters so as to
/// provide for the efficient reading of characters, arrays, and lines.
/// 
/// The buffer size may be specified, or the default size may be used. The
/// default is large enough for most purposes.
/// 
/// ## Example Usage
/// ```dart
/// // Basic buffered reading
/// final buffered = BufferedReader(FileReader('document.txt'));
/// try {
///   String? line;
///   while ((line = await buffered.readLine()) != null) {
///     print('Line: $line');
///   }
/// } finally {
///   await buffered.close();
/// }
/// 
/// // Using mark and reset for lookahead
/// final buffered = BufferedReader(FileReader('config.txt'));
/// try {
///   buffered.mark(1024);
///   
///   final firstLine = await buffered.readLine();
///   if (firstLine?.startsWith('<?xml') == true) {
///     await buffered.reset(); // Go back to beginning
///     processAsXml(buffered);
///   } else {
///     await buffered.reset(); // Go back to beginning
///     processAsText(buffered);
///   }
/// } finally {
///   await buffered.close();
/// }
/// ```
/// 
/// {@endtemplate}
class BufferedReader extends Reader {
  static const int _defaultBufferSize = 8192;
  
  final Reader _reader;
  final List<int> _buffer;
  int _count = 0;      // Number of valid characters in buffer
  int _position = 0;   // Current position in buffer
  int _markPosition = -1; // Mark position in buffer
  final int _markLimit = 0;  // Read limit for mark
  
  /// Creates a buffering character-input stream that uses a default-sized input buffer.
  /// 
  /// ## Parameters
  /// - [reader]: The underlying character reader
  /// - [bufferSize]: The buffer size (default: 8192 characters)
  /// 
  /// ## Example
  /// ```dart
  /// final buffered = BufferedReader(FileReader('document.txt'));
  /// final largeBuffered = BufferedReader(
  ///   FileReader('huge_document.txt'), 
  ///   bufferSize: 65536
  /// );
  /// ```
  /// 
  /// {@macro buffered_reader}
  BufferedReader(Reader reader, {int bufferSize = _defaultBufferSize})
      : _reader = reader,
        _buffer = List<int>.filled(bufferSize, 0);
  
  /// Fills the buffer with data from the underlying reader.
  Future<void> _fillBuffer() async {
    if (_markPosition < 0) {
      // No mark set, can use entire buffer
      _position = 0;
      _count = await _reader.read(_buffer);
      if (_count == -1) {
        _count = 0;
      }
    } else {
      // Mark is set, need to preserve marked data
      if (_position >= _markLimit) {
        // Mark is no longer valid
        _markPosition = -1;
        _position = 0;
        _count = await _reader.read(_buffer);
        if (_count == -1) {
          _count = 0;
        }
      } else {
        // Shift buffer to preserve marked data
        final preserveCount = _count - _markPosition;
        _buffer.setRange(0, preserveCount, _buffer, _markPosition);
        _position -= _markPosition;
        _count = preserveCount;
        _markPosition = 0;
        
        // Fill rest of buffer
        final charsRead = await _reader.read(_buffer, _count, _buffer.length - _count);
        if (charsRead > 0) {
          _count += charsRead;
        }
      }
    }
  }
  
  @override
  Future<int> readChar() async {
    checkClosed();
    
    if (_position >= _count) {
      await _fillBuffer();
      if (_count == 0) {
        return -1; // End of stream
      }
    }
    
    return _buffer[_position++];
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
    
    int totalRead = 0;
    
    // First, read from buffer if available
    if (_position < _count) {
      final availableInBuffer = _count - _position;
      final toReadFromBuffer = length.clamp(0, availableInBuffer);
      
      cbuf.setRange(offset, offset + toReadFromBuffer, _buffer, _position);
      _position += toReadFromBuffer;
      totalRead += toReadFromBuffer;
      offset += toReadFromBuffer;
      length -= toReadFromBuffer;
    }
    
    // If we need more data and the request is large, read directly
    if (length > 0 && length >= _buffer.length) {
      final directRead = await _reader.read(cbuf, offset, length);
      if (directRead > 0) {
        totalRead += directRead;
      } else if (totalRead == 0) {
        return -1; // End of stream
      }
    } else if (length > 0) {
      // Fill buffer and read from it
      await _fillBuffer();
      if (_count > 0) {
        final toRead = length.clamp(0, _count);
        cbuf.setRange(offset, offset + toRead, _buffer, 0);
        _position = toRead;
        totalRead += toRead;
      } else if (totalRead == 0) {
        return -1; // End of stream
      }
    }
    
    return totalRead;
  }
  
  @override
  Future<String?> readLine() async {
    checkClosed();
    
    final line = StringBuffer();
    bool foundLine = false;
    
    while (true) {
      // Ensure we have data in buffer
      if (_position >= _count) {
        await _fillBuffer();
        if (_count == 0) {
          // End of stream
          break;
        }
      }
      
      // Look for line terminator in current buffer
      int lineEnd = -1;
      bool foundCR = false;
      
      for (int i = _position; i < _count; i++) {
        final char = _buffer[i];
        if (char == 10) { // '\n'
          lineEnd = i;
          foundLine = true;
          break;
        } else if (char == 13) { // '\r'
          lineEnd = i;
          foundCR = true;
          foundLine = true;
          break;
        }
      }
      
      if (foundLine) {
        // Add characters up to line terminator
        for (int i = _position; i < lineEnd; i++) {
          line.writeCharCode(_buffer[i]);
        }
        
        _position = lineEnd + 1;
        
        // Handle '\r\n' sequence
        if (foundCR && _position < _count && _buffer[_position] == 10) {
          _position++; // Skip the '\n'
        } else if (foundCR && _position >= _count) {
          // Need to check next buffer for '\n'
          await _fillBuffer();
          if (_count > 0 && _buffer[0] == 10) {
            _position = 1;
          } else {
            _position = 0;
          }
        }
        
        return line.toString();
      } else {
        // No line terminator found, add all remaining characters in buffer
        for (int i = _position; i < _count; i++) {
          line.writeCharCode(_buffer[i]);
        }
        _position = _count;
      }
    }
    
    // Return what we have, or null if nothing was read
    return line.isEmpty ? null : line.toString();
  }
  
  @override
  Future<int> skip(int n) async {
    checkClosed();
    
    if (n <= 0) {
      return 0;
    }
    
    int totalSkipped = 0;
    
    // First, skip from buffer if available
    if (_position < _count) {
      final availableInBuffer = _count - _position;
      final toSkipFromBuffer = n.clamp(0, availableInBuffer);
      _position += toSkipFromBuffer;
      totalSkipped += toSkipFromBuffer;
      n -= toSkipFromBuffer;
    }
    
    // If we need to skip more, delegate to underlying reader
    if (n > 0) {
      final skippedFromReader = await _reader.skip(n);
      totalSkipped += skippedFromReader;
    }
    
    return totalSkipped;
  }
  
  @override
  Future<bool> ready() async {
    checkClosed();
    
    return _position < _count || await _reader.ready();
  }
}