import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart'
    show SystemChrome, SystemUiMode, SystemUiOverlay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_tokens.dart';
import '../models.dart';
import '../post_video_tools.dart';
import 'post_card.dart' show PostImageView;

final activeVideoProvider = NotifierProvider<ActiveVideo, Object?>(
  ActiveVideo.new,
);

class ActiveVideo extends Notifier<Object?> {
  @override
  Object? build() => null;

  void claim(Object owner) => state = owner;
}

class PostVideoPlayer extends ConsumerStatefulWidget {
  const PostVideoPlayer({required this.post, super.key});

  final CommunityPost post;

  @override
  ConsumerState<PostVideoPlayer> createState() => _PostVideoPlayerState();
}

class _PostVideoPlayerState extends ConsumerState<PostVideoPlayer>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _starting = false;
  bool _failed = false;
  bool _wasPlaying = false;

  Route<void>? _fullscreenRoute;

  bool get _fullscreen => _fullscreenRoute != null;

  VideoKey get _key => (postId: widget.post.id, video: widget.post.video!);

  bool get _hidden {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    return (!TickerMode.valuesOf(context).enabled && !_fullscreen) ||
        (lifecycle != null && lifecycle != AppLifecycleState.resumed);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hidden) _controller?.pause();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _controller?.pause();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = _controller;
    controller?.removeListener(_onControllerChange);
    final route = _fullscreenRoute;
    if (controller != null && route != null) {
      _closeThenRelease(route, controller);
    } else {
      controller?.dispose();
    }
    super.dispose();
  }

  static void _closeThenRelease(
    Route<void> route,
    VideoPlayerController controller,
  ) {
    scheduleMicrotask(() {
      if (route.isActive) route.navigator?.removeRoute(route);
      WidgetsBinding.instance
        ..addPostFrameCallback((_) => controller.dispose())
        ..scheduleFrame();
    });
  }

  void _onControllerChange() {
    final playing = _controller?.value.isPlaying ?? false;
    if (playing && !_wasPlaying) {
      ref.read(activeVideoProvider.notifier).claim(this);
    }
    _wasPlaying = playing;
  }

  Future<void> _start() async {
    if (_starting) return;
    final key = _key;
    if (_failed) ref.invalidate(postVideoFileProvider(key));
    setState(() {
      _starting = true;
      _failed = false;
    });
    VideoPlayerController? controller;
    String? path;
    try {
      final file = await ref.read(postVideoFileProvider(key).future);
      path = file;
      if (!mounted) return;
      controller = VideoPlayerController.file(File(file));
      await controller.initialize();
    } on Object {
      unawaited(controller?.dispose());
      if (path != null && controller != null) {
        unawaited(File(path).delete().then((_) {}, onError: (_) {}));
      }
      if (mounted) {
        setState(() {
          _starting = false;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) {
      unawaited(controller.dispose());
      return;
    }
    controller.addListener(_onControllerChange);
    setState(() {
      _controller = controller;
      _starting = false;
    });
    if (!_hidden) unawaited(controller.play());
  }

  static Widget _posterImage(CommunityPost post) => ExcludeSemantics(
    child: PostImageView(postId: post.id, index: 0, placeholder: post.thumb),
  );

  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (controller == null || _fullscreen) return;
    final route = MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => PostVideoFullscreen(
        controller: controller,
        poster: _posterImage(widget.post),
      ),
    );
    _fullscreenRoute = route;
    await Navigator.of(context, rootNavigator: true).push(route);
    if (mounted) _fullscreenRoute = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final post = widget.post;
    final video = post.video!;
    final controller = _controller;
    final duration = PostVideoTools.formatDuration(video.duration);
    ref.listen(activeVideoProvider, (_, owner) {
      if (!identical(owner, this)) _controller?.pause();
    });
    return Semantics(
      container: true,
      label: l10n.postVideoSemantics(duration),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AspectRatio(
          aspectRatio: post.aspectRatios.first,
          child: ColoredBox(
            color: AppColors.black,
            child: controller == null
                ? _Poster(
                    post: post,
                    duration: duration,
                    starting: _starting,
                    failed: _failed,
                    onPlay: _start,
                  )
                : VideoControlsOverlay(
                    controller: controller,
                    onFullscreen: _openFullscreen,
                    poster: _posterImage(post),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({
    required this.post,
    required this.duration,
    required this.starting,
    required this.failed,
    required this.onPlay,
  });

  final CommunityPost post;
  final String duration;
  final bool starting;
  final bool failed;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExcludeSemantics(
          child: PostImageView(
            postId: post.id,
            index: 0,
            placeholder: post.thumb,
          ),
        ),
        const ColoredBox(color: Color(0x33000000)),
        Center(
          child: starting
              ? Semantics(
                  liveRegion: true,
                  label: l10n.videoLoading,
                  child: const SizedBox.square(
                    dimension: 40,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                )
              : _BigPlayButton(
                  icon: failed
                      ? Icons.refresh_rounded
                      : Icons.play_arrow_rounded,
                  tooltip: failed ? l10n.retryAction : l10n.playVideoAction,
                  onPressed: onPlay,
                ),
        ),
        if (failed)
          Positioned(
            left: AppSpacing.md,
            right: AppSpacing.md,
            bottom: AppSpacing.md,
            child: Semantics(
              liveRegion: true,
              child: _Pill(text: l10n.videoLoadFailed),
            ),
          )
        else
          Positioned(
            left: AppSpacing.sm,
            bottom: AppSpacing.sm,
            child: ExcludeSemantics(
              child: _Pill(text: duration, icon: Icons.videocam_rounded),
            ),
          ),
      ],
    );
  }
}

class VideoControlsOverlay extends StatefulWidget {
  const VideoControlsOverlay({
    required this.controller,
    required this.onFullscreen,
    this.isFullscreen = false,
    this.poster,
    super.key,
  });

  final VideoPlayerController controller;
  final VoidCallback onFullscreen;
  final bool isFullscreen;

  final Widget? poster;

  @override
  State<VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<VideoControlsOverlay> {
  bool _visible = true;
  Timer? _hide;

  VideoPlayerController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onChange);
    _scheduleHide();
  }

  @override
  void didUpdateWidget(VideoControlsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    _hide?.cancel();
    _c.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  bool get _ended {
    final value = _c.value;
    return !value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration;
  }

  void _scheduleHide() {
    _hide?.cancel();
    _hide = Timer(const Duration(seconds: 3), () {
      if (mounted &&
          _c.value.isPlaying &&
          !MediaQuery.accessibleNavigationOf(context)) {
        setState(() => _visible = false);
      }
    });
  }

  void _toggleVisible() {
    setState(() => _visible = !_visible);
    if (_visible) _scheduleHide();
  }

  Future<void> _playPause() async {
    if (_c.value.isPlaying) {
      await _c.pause();
    } else {
      if (_ended) await _c.seekTo(Duration.zero);
      await _c.play();
    }
    _scheduleHide();
  }

  Future<void> _toggleMute() async {
    await _c.setVolume(_c.value.volume > 0 ? 0 : 1);
    _scheduleHide();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final value = _c.value;
    final showControls =
        _visible ||
        !value.isPlaying ||
        MediaQuery.accessibleNavigationOf(context);
    final muted = value.volume == 0;
    final ratio = value.aspectRatio > 0 ? value.aspectRatio : 16 / 9;
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleVisible,
          child: Center(
            child: AspectRatio(
              aspectRatio: ratio,
              child: _ended && widget.poster != null
                  ? widget.poster
                  : VideoPlayer(_c),
            ),
          ),
        ),
        IgnorePointer(
          ignoring: !showControls,
          child: AnimatedOpacity(
            opacity: showControls ? 1 : 0,
            duration: AppMotion.of(context, AppMotion.short),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0x99000000)],
                        stops: [0.55, 1],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: _BigPlayButton(
                    icon: value.isPlaying
                        ? Icons.pause_rounded
                        : _ended
                        ? Icons.replay_rounded
                        : Icons.play_arrow_rounded,
                    tooltip: value.isPlaying
                        ? l10n.pauseVideoAction
                        : _ended
                        ? l10n.replayVideoAction
                        : l10n.playVideoAction,
                    onPressed: _playPause,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.xs,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        ExcludeSemantics(
                          child: Text(
                            '${PostVideoTools.formatDuration(value.position)}'
                            ' / ${PostVideoTools.formatDuration(value.duration)}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: VideoProgressIndicator(
                                  _c,
                                  allowScrubbing: true,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  colors: VideoProgressColors(
                                    playedColor: AppColors.neon,
                                    bufferedColor: AppColors.white.withValues(
                                      alpha: 0.35,
                                    ),
                                    backgroundColor: AppColors.white.withValues(
                                      alpha: 0.15,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: muted ? l10n.unmuteAction : l10n.muteAction,
                          color: AppColors.white,
                          onPressed: _toggleMute,
                          icon: Icon(
                            muted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                          ),
                        ),
                        IconButton(
                          tooltip: widget.isFullscreen
                              ? l10n.exitFullscreenAction
                              : l10n.fullscreenAction,
                          color: AppColors.white,
                          onPressed: widget.onFullscreen,
                          icon: Icon(
                            widget.isFullscreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PostVideoFullscreen extends StatefulWidget {
  const PostVideoFullscreen({required this.controller, this.poster, super.key});

  final VideoPlayerController controller;
  final Widget? poster;

  @override
  State<PostVideoFullscreen> createState() => _PostVideoFullscreenState();
}

class _PostVideoFullscreenState extends State<PostVideoFullscreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
    final value = widget.controller.value;
    if (!value.isPlaying && value.position < value.duration) {
      unawaited(widget.controller.seekTo(value.position));
    }
  }

  @override
  void dispose() {
    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      ),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: VideoControlsOverlay(
          controller: widget.controller,
          poster: widget.poster,
          isFullscreen: true,
          onFullscreen: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class _BigPlayButton extends StatelessWidget {
  const _BigPlayButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 38,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.neon,
        foregroundColor: AppColors.black,
        minimumSize: const Size.square(64),
        shape: const CircleBorder(),
      ),
      icon: Icon(icon),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.white),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
