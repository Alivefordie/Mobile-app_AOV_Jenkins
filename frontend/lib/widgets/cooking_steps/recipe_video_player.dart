import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class RecipeVideoPlayer extends StatefulWidget {
  const RecipeVideoPlayer({
    super.key,
    required this.url,
    required this.isActive,
  });

  final String url;
  final bool isActive;

  @override
  State<RecipeVideoPlayer> createState() => _RecipeVideoPlayerState();
}

class _RecipeVideoPlayerState extends State<RecipeVideoPlayer> {
  VideoPlayerController? _controller;
  Object? _error;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadVideo());
  }

  @override
  void didUpdateWidget(covariant RecipeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      unawaited(_loadVideo());
    } else if (oldWidget.isActive && !widget.isActive) {
      unawaited(_controller?.pause());
    }
  }

  @override
  void dispose() {
    _loadGeneration++;
    unawaited(_controller?.dispose());
    super.dispose();
  }

  Future<void> _loadVideo() async {
    final generation = ++_loadGeneration;
    final previousController = _controller;
    _controller = null;
    await previousController?.dispose();

    final uri = Uri.tryParse(widget.url);
    if (uri == null || !uri.hasScheme) {
      if (mounted) setState(() => _error = const FormatException());
      return;
    }

    if (mounted) setState(() => _error = null);
    final controller = VideoPlayerController.networkUrl(
      uri,
      videoPlayerOptions: VideoPlayerOptions(
        allowBackgroundPlayback: false,
        mixWithOthers: false,
      ),
    );

    try {
      await controller.initialize();
      await controller.setLooping(false);
      if (!mounted || generation != _loadGeneration) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (error) {
      debugPrint('Video initialization failed for ${widget.url}: $error');
      await controller.dispose();
      if (mounted && generation == _loadGeneration) {
        setState(() => _error = error);
      }
    }
  }

  Future<void> _openFullscreen() async {
    final controller = _controller;
    if (controller == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _FullscreenVideoPage(controller: controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _VideoMessage(
        icon: Icons.videocam_off_outlined,
        message: _errorMessage(_error!),
        actionLabel: 'ลองอีกครั้ง',
        onAction: _loadVideo,
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const _VideoMessage(
        icon: Icons.play_circle_outline_rounded,
        message: 'กำลังโหลดวิดีโอ...',
      );
    }

    final aspectRatio = controller.value.aspectRatio == 0
        ? 16 / 9
        : controller.value.aspectRatio;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: _VideoSurface(
        controller: controller,
        onFullscreen: _openFullscreen,
      ),
    );
  }

  String _errorMessage(Object error) {
    if (kDebugMode) {
      final details = error.toString().replaceFirst('PlatformException(', '');
      return 'เล่นวิดีโอไม่ได้\n$details';
    }
    return 'ไม่สามารถเล่นวิดีโอนี้ได้';
  }
}

class _VideoSurface extends StatefulWidget {
  const _VideoSurface({
    required this.controller,
    required this.onFullscreen,
    this.onRotate,
    this.isFullscreen = false,
  });

  final VideoPlayerController controller;
  final VoidCallback onFullscreen;
  final VoidCallback? onRotate;
  final bool isFullscreen;

  @override
  State<_VideoSurface> createState() => _VideoSurfaceState();
}

class _VideoSurfaceState extends State<_VideoSurface> {
  late final Widget _videoTexture;
  Timer? _controlsTimer;
  bool _controlsVisible = true;
  bool _volumePanelVisible = false;
  DateTime _lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  bool _lastPlaying = false;
  bool _lastBuffering = false;
  double _lastVolume = 1;

  @override
  void initState() {
    super.initState();
    _videoTexture = RepaintBoundary(
      child: Center(child: VideoPlayer(widget.controller)),
    );
    _captureValue();
    widget.controller.addListener(_onControllerChanged);
    _scheduleControlsHide();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _captureValue() {
    final value = widget.controller.value;
    _lastPlaying = value.isPlaying;
    _lastBuffering = value.isBuffering;
    _lastVolume = value.volume;
  }

  void _onControllerChanged() {
    if (!mounted) return;
    final value = widget.controller.value;
    final stateChanged =
        value.isPlaying != _lastPlaying ||
        value.isBuffering != _lastBuffering ||
        value.volume != _lastVolume;
    final now = DateTime.now();
    final positionUpdateDue =
        _controlsVisible &&
        now.difference(_lastUiUpdate) >= const Duration(milliseconds: 300);
    if (!stateChanged && !positionUpdateDue) return;

    _captureValue();
    _lastUiUpdate = now;
    setState(() {});
  }

  void _showControls() {
    _controlsTimer?.cancel();
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleControlsHide();
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _controlsTimer?.cancel();
      setState(() {
        _controlsVisible = false;
        _volumePanelVisible = false;
      });
    } else {
      _showControls();
    }
  }

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();
    if (!widget.controller.value.isPlaying || _volumePanelVisible) return;
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _controlsVisible = false;
          _volumePanelVisible = false;
        });
      }
    });
  }

  Future<void> _togglePlayback() async {
    final controller = widget.controller;
    if (controller.value.position >= controller.value.duration) {
      await controller.seekTo(Duration.zero);
    }
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    _showControls();
  }

  Future<void> _seekBy(Duration offset) async {
    final value = widget.controller.value;
    final target = value.position + offset;
    final clamped = target < Duration.zero
        ? Duration.zero
        : target > value.duration
        ? value.duration
        : target;
    await widget.controller.seekTo(clamped);
    _showControls();
  }

  Future<void> _setVolume(double volume) async {
    await widget.controller.setVolume(volume.clamp(0, 1));
    _showControls();
  }

  Future<void> _toggleMute() async {
    final volume = widget.controller.value.volume;
    await _setVolume(volume == 0 ? 1 : 0);
  }

  Future<void> _setSpeed(double speed) async {
    await widget.controller.setPlaybackSpeed(speed);
    _showControls();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _videoTexture,
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleControls,
            onDoubleTapDown: (details) {
              final width = context.size?.width ?? 0;
              unawaited(
                _seekBy(
                  details.localPosition.dx < width / 2
                      ? const Duration(seconds: -10)
                      : const Duration(seconds: 10),
                ),
              );
            },
          ),
          IgnorePointer(
            ignoring: !_controlsVisible,
            child: AnimatedOpacity(
              opacity: _controlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: _buildControls(value),
            ),
          ),
          if (value.isBuffering)
            const IgnorePointer(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF24BDB8)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControls(VideoPlayerValue value) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black45, Colors.transparent, Colors.black87],
              stops: [0, 0.45, 1],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RoundControlButton(
                tooltip: 'ย้อนกลับ 10 วินาที',
                icon: Icons.replay_10_rounded,
                onPressed: () => _seekBy(const Duration(seconds: -10)),
              ),
              const SizedBox(width: 16),
              _RoundControlButton(
                tooltip: value.isPlaying ? 'หยุดชั่วคราว' : 'เล่น',
                icon: value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                iconSize: 38,
                onPressed: _togglePlayback,
              ),
              const SizedBox(width: 16),
              _RoundControlButton(
                tooltip: 'เดินหน้า 10 วินาที',
                icon: Icons.forward_10_rounded,
                onPressed: () => _seekBy(const Duration(seconds: 10)),
              ),
            ],
          ),
        ),
        if (_volumePanelVisible)
          Positioned(
            left: 14,
            right: 14,
            bottom: 62,
            child: _VolumePanel(
              volume: value.volume,
              onChanged: _setVolume,
              onMute: _toggleMute,
              onDecrease: () => _setVolume(value.volume - 0.1),
              onIncrease: () => _setVolume(value.volume + 0.1),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              widget.isFullscreen ? 20 : 8,
              0,
              widget.isFullscreen ? 20 : 8,
              widget.isFullscreen ? 12 : 3,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                VideoProgressIndicator(
                  widget.controller,
                  allowScrubbing: true,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFF24BDB8),
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white24,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: value.volume == 0 ? 'เปิดเสียง' : 'ปรับเสียง',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        setState(() {
                          _volumePanelVisible = !_volumePanelVisible;
                        });
                        _showControls();
                      },
                      onLongPress: _toggleMute,
                      icon: Icon(
                        value.volume == 0
                            ? Icons.volume_off_rounded
                            : value.volume < 0.5
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded,
                        color: Colors.white,
                      ),
                    ),
                    PopupMenuButton<double>(
                      tooltip: 'ความเร็วการเล่น',
                      initialValue: value.playbackSpeed,
                      onSelected: _setSpeed,
                      color: const Color(0xFF292733),
                      icon: Text(
                        '${value.playbackSpeed}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 0.5, child: Text('0.5x')),
                        PopupMenuItem(value: 0.75, child: Text('0.75x')),
                        PopupMenuItem(value: 1, child: Text('1.0x')),
                        PopupMenuItem(value: 1.25, child: Text('1.25x')),
                        PopupMenuItem(value: 1.5, child: Text('1.5x')),
                        PopupMenuItem(value: 2, child: Text('2.0x')),
                      ],
                    ),
                    if (widget.onRotate != null)
                      IconButton(
                        tooltip: 'หมุนหน้าจอ',
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onRotate,
                        icon: const Icon(
                          Icons.screen_rotation_rounded,
                          color: Colors.white,
                        ),
                      ),
                    IconButton(
                      tooltip: widget.isFullscreen ? 'ออกจากเต็มจอ' : 'เต็มจอ',
                      visualDensity: VisualDensity.compact,
                      onPressed: widget.onFullscreen,
                      icon: Icon(
                        widget.isFullscreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0
        ? '$hours:$minutes:$seconds'
        : '${duration.inMinutes}:$seconds';
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  const _FullscreenVideoPage({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  bool _isLandscape = true;

  @override
  void initState() {
    super.initState();
    unawaited(_enterFullscreen());
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _toggleOrientation() async {
    _isLandscape = !_isLandscape;
    await SystemChrome.setPreferredOrientations(
      _isLandscape
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );
    if (mounted) setState(() {});
  }

  Future<void> _exitFullscreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  void dispose() {
    unawaited(_exitFullscreen());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.controller.value;
    final aspectRatio = value.aspectRatio == 0 ? 16 / 9 : value.aspectRatio;
    return PopScope(
      onPopInvokedWithResult: (_, _) => unawaited(_exitFullscreen()),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: _VideoSurface(
              controller: widget.controller,
              isFullscreen: true,
              onRotate: _toggleOrientation,
              onFullscreen: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundControlButton extends StatelessWidget {
  const _RoundControlButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconSize = 28,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.58),
        foregroundColor: Colors.white,
      ),
      iconSize: iconSize,
      icon: Icon(icon),
    );
  }
}

class _VolumePanel extends StatelessWidget {
  const _VolumePanel({
    required this.volume,
    required this.onChanged,
    required this.onMute,
    required this.onDecrease,
    required this.onIncrease,
  });

  final double volume;
  final ValueChanged<double> onChanged;
  final VoidCallback onMute;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: volume == 0 ? 'เปิดเสียง' : 'ปิดเสียง',
            onPressed: onMute,
            icon: Icon(
              volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip: 'ลดเสียง',
            onPressed: onDecrease,
            icon: const Icon(Icons.remove_rounded, color: Colors.white),
          ),
          Expanded(
            child: Slider(
              value: volume.clamp(0, 1),
              onChanged: onChanged,
              activeColor: const Color(0xFF24BDB8),
              inactiveColor: Colors.white30,
            ),
          ),
          IconButton(
            tooltip: 'เพิ่มเสียง',
            onPressed: onIncrease,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _VideoMessage extends StatelessWidget {
  const _VideoMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(
        color: const Color(0xFF242230),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white70, size: 42),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70),
              ),
              if (actionLabel != null && onAction != null)
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ),
        ),
      ),
    );
  }
}
