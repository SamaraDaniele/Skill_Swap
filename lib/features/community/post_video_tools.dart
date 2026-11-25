import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fc_native_video_thumbnail/fc_native_video_thumbnail.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, compute, defaultTargetPlatform, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../../core/error/failure.dart';
import 'community_providers.dart';
import 'post_media.dart';
import 'post_video.dart';

typedef PostVideoPicker = Future<PreparedVideo?> Function();

final postVideoPickerProvider = Provider<PostVideoPicker>(
  (ref) => () async {
    final file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null) return null;
    return PostVideoTools.prepare(file);
  },
);

final videoCacheDirProvider = Provider<Future<Directory> Function()>(
  (ref) => getTemporaryDirectory,
);

typedef VideoKey = ({String postId, PostVideoInfo video});

final postVideoFileProvider = FutureProvider.autoDispose
    .family<String, VideoKey>((ref, key) async {
      cacheFor(ref, const Duration(minutes: 5));
      final dir = Directory(
        '${(await ref.read(videoCacheDirProvider)()).path}/post_videos',
      );
      final file = File(
        '${dir.path}/${PostVideoTools.fileName(key.postId)}.mp4',
      );
      if (await file.exists() && await file.length() == key.video.bytes) {
        return file.path;
      }
      final bytes = await ref
          .read(communityRepositoryProvider)
          .getVideo(key.postId, key.video);
      await dir.create(recursive: true);
      final part = File('${file.path}.part');
      await part.writeAsBytes(bytes, flush: true);
      await part.rename(file.path);
      await PostVideoTools.trimCache(dir, keep: file.path);
      return file.path;
    }, retry: communityRetry);

abstract final class PostVideoTools {
  static final RegExp _unsafe = RegExp('[^A-Za-z0-9_]');

  static const int maxCacheBytes = 50 * 1024 * 1024;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static String fileName(String postId) => postId.replaceAll(_unsafe, '_');

  static Future<PreparedVideo> prepare(XFile file) async {
    final dir = await getTemporaryDirectory();
    try {
      final length = await file.length();
      if (length <= 0 || length > PostVideo.maxBytes) {
        throw const InvalidVideoFailure();
      }
      final source = await file.readAsBytes();
      if (!PostVideo.isMp4(source)) throw const InvalidVideoFailure();
      final bytes = await compute(PostVideo.stripMetadata, source);
      if (bytes == null) throw const InvalidVideoFailure();
      return await _inspect(dir, bytes);
    } finally {
      if (file.path.startsWith(dir.path)) {
        await _deleteQuietly(File(file.path));
      }
    }
  }

  static Future<PreparedVideo> _inspect(Directory dir, Uint8List bytes) async {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final video = File('${dir.path}/compose_$stamp.mp4');
    final poster = File('${dir.path}/compose_$stamp.jpg');
    final controller = VideoPlayerController.file(video);
    try {
      await video.writeAsBytes(bytes, flush: true);
      await controller.initialize().timeout(const Duration(seconds: 20));
      final value = controller.value;
      final created = await FcNativeVideoThumbnail().saveThumbnailToFile(
        srcFile: video.path,
        destFile: poster.path,
        width: PostImage.maxSide,
        height: PostImage.maxSide,
        format: 'jpeg',
        quality: 90,
      );
      if (!created) throw const InvalidVideoFailure();
      final prepared = PreparedVideo(
        bytes: bytes,
        durationMs: value.duration.inMilliseconds,
        width: value.size.width.round(),
        height: value.size.height.round(),
        poster: await PostImage.prepare(await poster.readAsBytes()),
      );
      if (!prepared.info.isValid) throw const InvalidVideoFailure();
      return prepared;
    } on InvalidVideoFailure {
      rethrow;
    } on Object {
      throw const InvalidVideoFailure();
    } finally {
      await controller.dispose();
      await _deleteQuietly(video);
      await _deleteQuietly(poster);
    }
  }

  static Future<void> trimCache(Directory dir, {required String keep}) async {
    try {
      final files = [
        for (final entity in await dir.list().toList())
          if (entity is File) (file: entity, stat: await entity.stat()),
      ]..sort((a, b) => b.stat.modified.compareTo(a.stat.modified));
      var total = 0;
      for (final entry in files) {
        total += entry.stat.size;
        if (total > maxCacheBytes && entry.file.path != keep) {
          await _deleteQuietly(entry.file);
        }
      }
    } on FileSystemException {
      // A limpeza do cache não deve interromper a reprodução.
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // A remoção do arquivo é uma operação de melhor esforço.
    }
  }

  static String formatDuration(Duration value) {
    final seconds = value.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
