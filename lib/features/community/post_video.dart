import 'dart:typed_data';

import 'post_media.dart';

class PostVideoInfo {
  const PostVideoInfo({
    required this.chunks,
    required this.bytes,
    required this.durationMs,
    required this.width,
    required this.height,
  });

  static PostVideoInfo? tryParse(Object? value) {
    if (value is! Map) return null;
    final chunks = value['chunks'];
    final bytes = value['bytes'];
    final durationMs = value['durationMs'];
    final width = value['width'];
    final height = value['height'];
    if (chunks is! int ||
        bytes is! int ||
        durationMs is! int ||
        width is! int ||
        height is! int) {
      return null;
    }
    final info = PostVideoInfo(
      chunks: chunks,
      bytes: bytes,
      durationMs: durationMs,
      width: width,
      height: height,
    );
    return info.isValid ? info : null;
  }

  final int chunks;
  final int bytes;
  final int durationMs;
  final int width;
  final int height;

  Duration get duration => Duration(milliseconds: durationMs);

  double get aspectRatio => width / height;

  bool get isValid =>
      chunks == PostVideo.chunkCount(bytes) &&
      bytes >= 1 &&
      bytes <= PostVideo.maxBytes &&
      durationMs >= 1 &&
      durationMs <= PostVideo.maxDuration.inMilliseconds &&
      width >= 1 &&
      width <= PostVideo.maxSide &&
      height >= 1 &&
      height <= PostVideo.maxSide;

  @override
  bool operator ==(Object other) =>
      other is PostVideoInfo &&
      other.chunks == chunks &&
      other.bytes == bytes &&
      other.durationMs == durationMs &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(chunks, bytes, durationMs, width, height);

  Map<String, Object> toMap() => {
    'chunks': chunks,
    'bytes': bytes,
    'durationMs': durationMs,
    'width': width,
    'height': height,
  };
}

class PreparedVideo {
  const PreparedVideo({
    required this.bytes,
    required this.durationMs,
    required this.width,
    required this.height,
    required this.poster,
  });

  final Uint8List bytes;
  final int durationMs;
  final int width;
  final int height;

  final PreparedImage poster;

  PostVideoInfo get info => PostVideoInfo(
    chunks: PostVideo.chunkCount(bytes.length),
    bytes: bytes.length,
    durationMs: durationMs,
    width: width,
    height: height,
  );
}

abstract final class PostVideo {
  static const int chunkBytes = 800 * 1024;

  static const int maxChunks = 3;
  static const int maxBytes = chunkBytes * maxChunks;

  static const Duration maxDuration = Duration(seconds: 60);

  static const int maxSide = 4096;

  static int chunkCount(int bytes) =>
      bytes <= 0 ? 0 : (bytes + chunkBytes - 1) ~/ chunkBytes;

  static List<Uint8List> split(Uint8List bytes) => [
    for (var start = 0; start < bytes.length; start += chunkBytes)
      Uint8List.sublistView(
        bytes,
        start,
        start + chunkBytes < bytes.length ? start + chunkBytes : bytes.length,
      ),
  ];

  static bool isMp4(Uint8List bytes) =>
      bytes.length >= 12 &&
      bytes[4] == 0x66 &&
      bytes[5] == 0x74 &&
      bytes[6] == 0x79 &&
      bytes[7] == 0x70;

  static const List<int> _free = [0x66, 0x72, 0x65, 0x65];

  static const Set<String> _metadataBoxes = {'udta', 'meta', 'uuid'};

  static const Map<String, String> _children = {
    '': 'moov',
    'moov': 'trak',
    'trak': 'mdia',
    'mdia': 'minf',
  };

  static const Set<String> _allowedHandlers = {'vide', 'soun'};

  static final List<List<int>> _leftoverMarkers = [
    'ISO6709'.codeUnits,
    '<x:xmpmeta'.codeUnits,
    'GPSLatitude'.codeUnits,
    [0xa9, 0x78, 0x79, 0x7a],
  ];

  static Uint8List? stripMetadata(Uint8List source) {
    final out = Uint8List.fromList(source);
    final state = _WalkState();
    if (!_walk(out, 0, out.length, '', state) || !state.sawMoov) return null;
    for (final marker in _leftoverMarkers) {
      if (_indexOf(out, marker) >= 0) return null;
    }
    return out;
  }

  static bool _walk(
    Uint8List data,
    int start,
    int end,
    String parent,
    _WalkState state,
  ) {
    var offset = start;
    while (offset < end) {
      if (offset + 8 > end) return false;
      var size = _readUint32(data, offset);
      var header = 8;
      if (size == 1) {
        if (offset + 16 > end) return false;
        if (_readUint32(data, offset + 8) != 0) return false;
        size = _readUint32(data, offset + 12);
        header = 16;
      } else if (size == 0) {
        size = end - offset;
      }
      if (size < header || offset + size > end) return false;
      final type = String.fromCharCodes(data, offset + 4, offset + 8);
      if (_metadataBoxes.contains(type)) {
        data.setRange(offset + 4, offset + 8, _free);
        data.fillRange(offset + header, offset + size, 0);
      } else if (type == _children[parent]) {
        if (type == 'moov') state.sawMoov = true;
        if (!_walk(data, offset + header, offset + size, type, state)) {
          return false;
        }
      } else if (parent == 'mdia' && type == 'hdlr') {
        final at = offset + header + 8;
        if (at + 4 > offset + size) return false;
        final handler = String.fromCharCodes(data, at, at + 4);
        if (!_allowedHandlers.contains(handler)) return false;
      }
      offset += size;
    }
    return true;
  }

  static int _indexOf(Uint8List data, List<int> pattern) {
    final first = pattern.first;
    for (var i = 0; i <= data.length - pattern.length; i++) {
      if (data[i] != first) continue;
      var j = 1;
      while (j < pattern.length && data[i + j] == pattern[j]) {
        j++;
      }
      if (j == pattern.length) return i;
    }
    return -1;
  }

  static int _readUint32(Uint8List data, int offset) =>
      (data[offset] << 24) |
      (data[offset + 1] << 16) |
      (data[offset + 2] << 8) |
      data[offset + 3];
}

class _WalkState {
  bool sawMoov = false;
}
