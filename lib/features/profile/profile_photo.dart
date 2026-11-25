import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

import '../../core/error/failure.dart';

abstract final class ProfilePhoto {
  static const int maxBytes = 48 * 1024;

  static const int side = 384;

  static const int maxDisplaySide = 1024;

  static const int maxSourceBytes = 20 * 1024 * 1024;

  static const int maxSourceSide = 4096;

  static bool isAcceptable(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty || bytes.length > maxBytes) {
      return false;
    }
    final size = jpegSize(bytes);
    return size != null &&
        size.width > 0 &&
        size.height > 0 &&
        size.width <= maxDisplaySide &&
        size.height <= maxDisplaySide;
  }

  static ({int width, int height})? jpegSize(Uint8List bytes) {
    if (bytes.length < 4 ||
        bytes[0] != 0xFF ||
        bytes[1] != 0xD8 ||
        bytes[2] != 0xFF) {
      return null;
    }
    var offset = 2;
    while (offset + 4 <= bytes.length) {
      if (bytes[offset] != 0xFF) return null;
      final marker = bytes[offset + 1];
      if (marker == 0xFF) {
        offset++;
        continue;
      }
      if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD8)) {
        offset += 2;
        continue;
      }
      if (marker == 0xD9 || marker == 0xDA) return null;
      final length = (bytes[offset + 2] << 8) | bytes[offset + 3];
      if (length < 2) return null;
      final isFrame =
          marker >= 0xC0 &&
          marker <= 0xCF &&
          marker != 0xC4 &&
          marker != 0xC8 &&
          marker != 0xCC;
      if (isFrame) {
        if (marker != 0xC0 || length < 8 || offset + 10 > bytes.length) {
          return null;
        }
        final precision = bytes[offset + 4];
        final components = bytes[offset + 9];
        if (precision != 8 || (components != 1 && components != 3)) {
          return null;
        }
        final height = (bytes[offset + 5] << 8) | bytes[offset + 6];
        final width = (bytes[offset + 7] << 8) | bytes[offset + 8];
        return (width: width, height: height);
      }
      offset += 2 + length;
    }
    return null;
  }

  static Future<Uint8List> prepare(Uint8List source) async {
    if (source.isEmpty || source.length > maxSourceBytes) {
      throw const InvalidImageFailure();
    }
    final Uint8List? result;
    try {
      result = await compute(_prepare, source);
    } on Object {
      throw const InvalidImageFailure();
    }
    if (result == null) throw const InvalidImageFailure();
    return result;
  }

  static Uint8List? _prepare(Uint8List source) {
    final decoder = img.findDecoderForData(source);
    final info = decoder?.startDecode(source);
    if (decoder == null ||
        info == null ||
        info.width > maxSourceSide ||
        info.height > maxSourceSide) {
      return null;
    }
    final decoded = decoder.decode(source);
    if (decoded == null || decoded.width == 0 || decoded.height == 0) {
      return null;
    }
    final cropped = img.copyResizeCropSquare(
      img.bakeOrientation(decoded),
      size: side,
      interpolation: img.Interpolation.average,
    );
    final square = img.fill(
      img.Image(width: side, height: side),
      color: img.ColorRgb8(255, 255, 255),
    );
    img.compositeImage(square, cropped);
    for (final quality in const [85, 75, 65, 50]) {
      final jpeg = img.encodeJpg(square, quality: quality);
      if (jpeg.length <= maxBytes) return jpeg;
    }
    return null;
  }
}
