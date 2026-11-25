import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:material_ui/material_ui.dart';
import 'package:skill_swap/core/error/failure.dart';
import 'package:skill_swap/core/widgets/app_widgets.dart';
import 'package:skill_swap/features/profile/profile.dart';
import 'package:skill_swap/features/profile/profile_photo.dart';

/// A real JPEG of [width]×[height].
Uint8List jpeg(int width, int height) =>
    img.encodeJpg(img.Image(width: width, height: height), quality: 80);

/// Minimal JPEG header declaring [width]×[height] (no image data).
Uint8List jpegHeader(int width, int height) => Uint8List.fromList([
  0xFF, 0xD8, // SOI
  0xFF, 0xE0, 0x00, 0x04, 0x00, 0x00, // APP0, empty payload
  0xFF, 0xC0, 0x00, 0x0B, 0x08, // SOF0, length 11, precision 8
  height >> 8, height & 0xFF, width >> 8, width & 0xFF,
  0x01, 0x01, 0x11, 0x00,
]);

/// Whether [bytes] contains an EXIF (APP1 "Exif") segment.
bool hasExif(Uint8List bytes) {
  for (var i = 0; i + 9 < bytes.length; i++) {
    if (bytes[i] == 0xFF &&
        bytes[i + 1] == 0xE1 &&
        String.fromCharCodes(bytes.sublist(i + 4, i + 8)) == 'Exif') {
      return true;
    }
  }
  return false;
}

void main() {
  group('ProfilePhoto.jpegSize', () {
    test('reads the frame dimensions', () {
      expect(ProfilePhoto.jpegSize(jpeg(30, 20)), (width: 30, height: 20));
      expect(ProfilePhoto.jpegSize(jpegHeader(640, 480)), (
        width: 640,
        height: 480,
      ));
    });

    test('returns null for anything that is not a JPEG', () {
      final png = img.encodePng(img.Image(width: 4, height: 4));
      expect(ProfilePhoto.jpegSize(png), isNull);
      expect(ProfilePhoto.jpegSize(Uint8List(0)), isNull);
      expect(ProfilePhoto.jpegSize(Uint8List.fromList([0xFF, 0xD8])), isNull);
      // Truncated before the frame header.
      expect(ProfilePhoto.jpegSize(jpegHeader(10, 10).sublist(0, 12)), isNull);
    });
  });

  group('ProfilePhoto.isAcceptable', () {
    test('accepts a small JPEG', () {
      expect(ProfilePhoto.isAcceptable(jpeg(384, 384)), isTrue);
    });

    test('accepts the demo avatars drawn for the test accounts', () {
      for (var i = 1; i <= 10; i++) {
        final bytes = File('tool/demo_avatars/teste$i.jpg').readAsBytesSync();
        expect(ProfilePhoto.isAcceptable(bytes), isTrue, reason: 'teste$i');
      }
    });

    test('refuses non-baseline JPEGs (progressive, lossless, 12-bit)', () {
      Uint8List withFrame(int marker, {int precision = 8, int comps = 1}) {
        final header = jpegHeader(64, 64);
        header[9] = marker;
        header[12] = precision;
        header[17] = comps;
        return header;
      }

      expect(ProfilePhoto.jpegSize(withFrame(0xC0)), (width: 64, height: 64));
      expect(ProfilePhoto.jpegSize(withFrame(0xC0, comps: 3)), isNotNull);
      expect(ProfilePhoto.jpegSize(withFrame(0xC2)), isNull);
      expect(ProfilePhoto.jpegSize(withFrame(0xC3)), isNull);
      expect(ProfilePhoto.jpegSize(withFrame(0xC9)), isNull);
      expect(ProfilePhoto.jpegSize(withFrame(0xC0, precision: 12)), isNull);
      expect(ProfilePhoto.jpegSize(withFrame(0xC0, comps: 4)), isNull);
    });

    test('skips fill bytes and standalone markers before the frame', () {
      final header = jpegHeader(20, 30);
      final padded = Uint8List.fromList([
        ...header.sublist(0, 2),
        0xFF, 0xD0, // standalone RST marker
        0xFF, // fill byte
        ...header.sublist(2),
      ]);
      expect(ProfilePhoto.jpegSize(padded), (width: 20, height: 30));
    });

    test('rejects oversized dimensions (decoding bomb)', () {
      expect(ProfilePhoto.isAcceptable(jpegHeader(1025, 10)), isFalse);
      expect(ProfilePhoto.isAcceptable(jpegHeader(60000, 60000)), isFalse);
      expect(ProfilePhoto.isAcceptable(jpegHeader(0, 10)), isFalse);
    });

    test('rejects files over the byte limit, PNGs and empty data', () {
      final big = Uint8List(ProfilePhoto.maxBytes + 1)
        ..setAll(0, jpegHeader(10, 10));
      expect(ProfilePhoto.isAcceptable(big), isFalse);
      expect(
        ProfilePhoto.isAcceptable(
          img.encodePng(img.Image(width: 4, height: 4)),
        ),
        isFalse,
      );
      expect(ProfilePhoto.isAcceptable(Uint8List(0)), isFalse);
      expect(ProfilePhoto.isAcceptable(null), isFalse);
    });
  });

  group('ProfilePhoto.prepare', () {
    test('crops to a square JPEG without metadata, within the limit', () async {
      final source = img.Image(width: 900, height: 600)
        ..exif.imageIfd.orientation = 6
        ..exif.gpsIfd['GPSLatitude'] = img.IfdValueRational(23, 1);
      final withExif = img.encodeJpg(source);
      expect(hasExif(withExif), isTrue);

      final photo = await ProfilePhoto.prepare(withExif);

      expect(ProfilePhoto.jpegSize(photo), (
        width: ProfilePhoto.side,
        height: ProfilePhoto.side,
      ));
      expect(photo.length, lessThanOrEqualTo(ProfilePhoto.maxBytes));
      expect(hasExif(photo), isFalse);
      expect(ProfilePhoto.isAcceptable(photo), isTrue);
    });

    test('converts a transparent PNG to JPEG on white', () async {
      final png = img.encodePng(
        img.Image(width: 50, height: 50, numChannels: 4),
      );
      final photo = await ProfilePhoto.prepare(png);
      final decoded = img.decodeJpg(photo)!;
      expect(decoded.getPixel(10, 10).r, greaterThan(240));
    });

    test('rejects truncated files and huge source images', () async {
      final truncated = img.encodePng(img.Image(width: 64, height: 64));
      await expectLater(
        ProfilePhoto.prepare(truncated.sublist(0, 60)),
        throwsA(isA<InvalidImageFailure>()),
      );
      // 5000 px wide: refused from the header, before allocating pixels.
      final huge = img.encodePng(img.Image(width: 5000, height: 2));
      await expectLater(
        ProfilePhoto.prepare(huge),
        throwsA(isA<InvalidImageFailure>()),
      );
    });

    test('rejects files that are not images', () async {
      await expectLater(
        ProfilePhoto.prepare(Uint8List.fromList(List.filled(64, 7))),
        throwsA(isA<InvalidImageFailure>()),
      );
      await expectLater(
        ProfilePhoto.prepare(Uint8List(0)),
        throwsA(isA<InvalidImageFailure>()),
      );
    });
  });

  group('UserProfile photo', () {
    test('round-trips through Firestore as a Blob', () async {
      final db = FakeFirebaseFirestore();
      final repository = ProfileRepository(db);
      final photo = jpeg(64, 64);
      await repository.createWithConsent(
        UserProfile(
          id: 'ana',
          name: 'Ana',
          bio: '',
          teach: const ['excel'],
          learn: const ['english'],
          photo: photo,
        ),
      );

      final stored = await db.doc('users/ana').get();
      expect(stored.data()!['photo'], isA<Blob>());
      expect((await repository.watch('ana').first)!.photo, photo);
    });

    test('saving keeps or replaces the photo unless it was removed', () async {
      final db = FakeFirebaseFirestore();
      final repository = ProfileRepository(db);
      const base = UserProfile(
        id: 'ana',
        name: 'Ana',
        bio: '',
        teach: ['excel'],
        learn: ['english'],
      );
      final first = jpeg(64, 64);
      await db.doc('users/ana').set({...base.toMap(), 'photo': Blob(first)});

      // Not loaded / not touched: the stored photo stays.
      await repository.save(base);
      expect((await repository.watch('ana').first)!.photo, first);

      final second = jpeg(32, 32);
      await repository.save(
        UserProfile(
          id: 'ana',
          name: 'Ana',
          bio: '',
          teach: const ['excel'],
          learn: const ['english'],
          photo: second,
        ),
      );
      expect((await repository.watch('ana').first)!.photo, second);
    });

    test('saving after removing the photo deletes it', () async {
      final db = FakeFirebaseFirestore();
      final repository = ProfileRepository(db);
      const base = UserProfile(
        id: 'ana',
        name: 'Ana',
        bio: '',
        teach: ['excel'],
        learn: ['english'],
      );
      await db.doc('users/ana').set({
        ...base.toMap(),
        'photo': Blob(jpeg(64, 64)),
      });

      await repository.save(base, removePhoto: true);

      final stored = await db.doc('users/ana').get();
      expect(stored.data()!.containsKey('photo'), isFalse);
      expect(stored.data()!['name'], 'Ana');
    });

    test('ignores photos that are not acceptable JPEGs', () {
      UserProfile parse(Object? photo) =>
          UserProfile.fromMap('x', {'name': 'X', 'photo': photo});
      expect(parse(Blob(jpegHeader(5000, 5000))).photo, isNull);
      expect(parse('https://example.com/a.jpg').photo, isNull);
      expect(parse(null).photo, isNull);
      expect(parse(Blob(jpeg(32, 32))).photo, isNotNull);
    });
  });

  group('ProfileAvatar', () {
    testWidgets('shows the photo when there is one', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileAvatar(name: 'Ana Lima', photo: jpeg(32, 32)),
        ),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('AL'), findsNothing);
    });

    testWidgets('shows initials without a photo', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProfileAvatar(name: 'Ana Lima')),
      );
      expect(find.byType(Image), findsNothing);
      expect(find.text('AL'), findsOneWidget);
    });
  });
}
