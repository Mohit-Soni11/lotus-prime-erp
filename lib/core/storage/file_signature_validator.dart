import 'dart:io';
import 'dart:typed_data';

/// Lightweight, content-based validation for Shop Profile uploads.
/// File extensions are user-controlled and are therefore never trusted alone.
class FileSignatureValidator {
  FileSignatureValidator._();

  static Future<bool> matchesDeclaredExtension(File file) async {
    final extension = _extension(file.path);
    final header = await _readHeader(file);
    return switch (extension) {
      '.jpg' || '.jpeg' => _startsWith(header, const [0xFF, 0xD8, 0xFF]),
      '.png' => _startsWith(header, const [0x89, 0x50, 0x4E, 0x47]),
      '.webp' => _startsWith(header, const [0x52, 0x49, 0x46, 0x46]) &&
          _bytesAt(header, 8, const [0x57, 0x45, 0x42, 0x50]),
      '.pdf' => _startsWith(header, const [0x25, 0x50, 0x44, 0x46, 0x2D]),
      _ => false,
    };
  }

  static Future<Uint8List> _readHeader(File file) async {
    final handle = await file.open(mode: FileMode.read);
    try {
      return Uint8List.fromList(await handle.read(12));
    } finally {
      await handle.close();
    }
  }

  static String _extension(String path) {
    final index = path.lastIndexOf('.');
    return index < 0 ? '' : path.substring(index).toLowerCase();
  }

  static bool _startsWith(Uint8List bytes, List<int> marker) =>
      _bytesAt(bytes, 0, marker);

  static bool _bytesAt(Uint8List bytes, int offset, List<int> marker) {
    if (bytes.length < offset + marker.length) return false;
    for (var index = 0; index < marker.length; index++) {
      if (bytes[offset + index] != marker[index]) return false;
    }
    return true;
  }
}
