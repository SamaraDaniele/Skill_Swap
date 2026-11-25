// Generates the Android launcher icons from the bundled brand logo.
//
// Run from the app folder:  dart run tool/generate_launcher_icons.dart
//
// Output (overwritten):
// - mipmap-*/ic_launcher.png: legacy icons (black rounded square + logo);
// - mipmap-*/ic_launcher_foreground.png: adaptive icon foreground (API 26+),
//   logo kept inside the 66 dp safe zone so no launcher mask clips it;
// - the adaptive icon XML and its black background colour are static files
//   in res/mipmap-anydpi-v26 and res/values/colors.xml.
//
// The logo is only cropped and scaled, never redrawn or recoloured.
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _logoPath = 'assets/branding/logo.png';
const _resPath = 'android/app/src/main/res';

/// Density buckets and their scale relative to mdpi.
const _densities = {
  'mdpi': 1.0,
  'hdpi': 1.5,
  'xhdpi': 2.0,
  'xxhdpi': 3.0,
  'xxxhdpi': 4.0,
};

/// Pixels that count as "visible" when measuring the symbol: opaque and not
/// part of the dark glow halo (which disappears on the black background).
bool _isVisible(img.Pixel p) =>
    p.a > 128 && (p.r * 0.3 + p.g * 0.59 + p.b * 0.11) > 40;

void main() {
  final logo = img.decodePng(File(_logoPath).readAsBytesSync());
  if (logo == null) {
    stderr.writeln('Could not decode $_logoPath');
    exit(1);
  }

  // Bounds and centre of the visible symbol.
  var minX = logo.width, minY = logo.height, maxX = 0, maxY = 0;
  for (final p in logo) {
    if (!_isVisible(p)) continue;
    minX = math.min(minX, p.x);
    minY = math.min(minY, p.y);
    maxX = math.max(maxX, p.x);
    maxY = math.max(maxY, p.y);
  }
  final cx = (minX + maxX) / 2;
  final cy = (minY + maxY) / 2;
  // Farthest visible pixel from the centre: what a round mask would clip.
  var radius = 0.0;
  for (final p in logo) {
    if (!_isVisible(p)) continue;
    radius = math.max(
      radius,
      math.sqrt(math.pow(p.x - cx, 2) + math.pow(p.y - cy, 2)),
    );
  }
  stdout.writeln(
    'Symbol bounds: ($minX,$minY)-($maxX,$maxY), radius ${radius.round()} px',
  );

  for (final MapEntry(key: bucket, value: scale) in _densities.entries) {
    final dir = Directory('$_resPath/mipmap-$bucket')..createSync();

    // Adaptive foreground: 108 dp canvas, symbol within a 33 dp radius.
    final fgSize = (108 * scale).round();
    final foreground = _placeLogo(
      logo,
      cx: cx,
      cy: cy,
      sourceRadius: radius,
      canvasSize: fgSize,
      targetRadius: 33 * scale,
    );
    File('${dir.path}/ic_launcher_foreground.png')
        .writeAsBytesSync(img.encodePng(foreground));

    // Legacy icon: 48 dp black rounded square, symbol within a 21 dp radius.
    final legacySize = (48 * scale).round();
    final legacy = img.Image(
      width: legacySize,
      height: legacySize,
      numChannels: 4,
    );
    img.fillRect(
      legacy,
      x1: 0,
      y1: 0,
      x2: legacySize - 1,
      y2: legacySize - 1,
      color: img.ColorRgba8(0, 0, 0, 255),
      radius: legacySize * 0.2,
    );
    img.compositeImage(
      legacy,
      _placeLogo(
        logo,
        cx: cx,
        cy: cy,
        sourceRadius: radius,
        canvasSize: legacySize,
        targetRadius: 21 * scale,
      ),
    );
    File('${dir.path}/ic_launcher.png').writeAsBytesSync(img.encodePng(legacy));
    stdout.writeln('mipmap-$bucket: ${legacySize}px / ${fgSize}px');
  }
}

/// Returns a transparent [canvasSize] square with the logo scaled so its
/// visible radius equals [targetRadius] and its centre is the canvas centre.
img.Image _placeLogo(
  img.Image logo, {
  required double cx,
  required double cy,
  required double sourceRadius,
  required int canvasSize,
  required double targetRadius,
}) {
  final factor = targetRadius / sourceRadius;
  final resized = img.copyResize(
    logo,
    width: (logo.width * factor).round(),
    height: (logo.height * factor).round(),
    interpolation: img.Interpolation.average,
  );
  final canvas = img.Image(
    width: canvasSize,
    height: canvasSize,
    numChannels: 4,
  );
  img.compositeImage(
    canvas,
    resized,
    dstX: (canvasSize / 2 - cx * factor).round(),
    dstY: (canvasSize / 2 - cy * factor).round(),
    blend: img.BlendMode.direct,
  );
  return canvas;
}
