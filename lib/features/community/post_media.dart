import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

import '../../core/error/failure.dart';
import '../profile/profile_photo.dart';

class PreparedImage {
  const PreparedImage({
    required this.bytes,
    required this.width,
    required this.height,
    required this.thumb,
  });

  final Uint8List bytes;
  final int width;
  final int height;

  final Uint8List thumb;

  double get aspectRatio => PostImage.clampAspect(width / height);
}

abstract final class PostImage {
  static const int maxBytes = 300 * 1024;

  static const int maxSide = 1440;

  static const int thumbMaxBytes = 24 * 1024;
  static const int thumbSide = 320;

  static const int thumbMaxDisplaySide = 640;

  static const int maxSourceBytes = 25 * 1024 * 1024;

  static const int maxSourceSide = 4096;

  static const double minAspect = 0.8;
  static const double maxAspect = 1.91;

  static double clampAspect(double ratio) =>
      ratio.isFinite && ratio > 0 ? ratio.clamp(minAspect, maxAspect) : 1;

  static bool _isJpegWithin(Uint8List? bytes, int maxBytes, int maxSide) {
    if (bytes == null || bytes.isEmpty || bytes.length > maxBytes) {
      return false;
    }
    final size = ProfilePhoto.jpegSize(bytes);
    return size != null &&
        size.width > 0 &&
        size.height > 0 &&
        size.width <= maxSide &&
        size.height <= maxSide;
  }

  static bool isAcceptable(Uint8List? bytes) =>
      _isJpegWithin(bytes, maxBytes, maxSide);

  static bool isAcceptableThumb(Uint8List? bytes) =>
      _isJpegWithin(bytes, thumbMaxBytes, thumbMaxDisplaySide);

  static Future<PreparedImage> prepare(Uint8List source) async {
    if (source.isEmpty || source.length > maxSourceBytes) {
      throw const InvalidImageFailure();
    }
    final PreparedImage? result;
    try {
      result = await compute(_prepare, source);
    } on Object {
      throw const InvalidImageFailure();
    }
    if (result == null) throw const InvalidImageFailure();
    return result;
  }

  static img.Image _fit(img.Image image, int side) {
    if (image.width <= side && image.height <= side) return image;
    return image.width >= image.height
        ? img.copyResize(
            image,
            width: side,
            interpolation: img.Interpolation.average,
          )
        : img.copyResize(
            image,
            height: side,
            interpolation: img.Interpolation.average,
          );
  }

  static Uint8List? _encode(img.Image image, int maxBytes, List<int> steps) {
    for (final quality in steps) {
      final jpeg = img.encodeJpg(image, quality: quality);
      if (jpeg.length <= maxBytes) return jpeg;
    }
    return null;
  }

  static PreparedImage? _prepare(Uint8List source) {
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
    final oriented = img.bakeOrientation(decoded);
    final flat = img.fill(
      img.Image(width: oriented.width, height: oriented.height),
      color: img.ColorRgb8(255, 255, 255),
    );
    img.compositeImage(flat, oriented);

    var side = maxSide;
    Uint8List? jpeg;
    img.Image sized = flat;
    for (var attempt = 0; attempt < 4 && jpeg == null; attempt++) {
      sized = _fit(flat, side);
      jpeg = _encode(sized, maxBytes, const [85, 75, 65, 55, 45]);
      side = (side * 0.8).round();
    }
    if (jpeg == null) return null;
    final thumb = _encode(_fit(flat, thumbSide), thumbMaxBytes, const [
      70,
      60,
      50,
      40,
      30,
    ]);
    if (thumb == null) return null;
    return PreparedImage(
      bytes: jpeg,
      width: sized.width,
      height: sized.height,
      thumb: thumb,
    );
  }
}
