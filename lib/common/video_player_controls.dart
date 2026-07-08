part of '../main.dart';

class VideoControls extends StatefulWidget {
  const VideoControls({
    super.key,
    required this.controller,
    this.onFullscreen,
    this.fullscreenIcon = Icons.fullscreen,
    this.fullscreenTooltip = 'Fullscreen',
  });

  final VideoPlayerController controller;
  final VoidCallback? onFullscreen;
  final IconData fullscreenIcon;
  final String fullscreenTooltip;

  @override
  State<VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<VideoControls> {
  Timer? _hideTimer;
  Offset? _lastDoubleTapPosition;
  var _controlsVisible = true;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
    _scheduleHideControls();
  }

  @override
  void didUpdateWidget(covariant VideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_refresh);
      widget.controller.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _scheduleHideControls();
  }

  void _scheduleHideControls() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() => _controlsVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final value = controller.value;
    final duration = value.duration;
    final position = value.position;
    final maxMilliseconds = duration.inMilliseconds <= 0
        ? 1.0
        : duration.inMilliseconds.toDouble();
    final currentMilliseconds = position.inMilliseconds.clamp(
      0,
      duration.inMilliseconds <= 0 ? 1 : duration.inMilliseconds,
    );
    final isFinished =
        duration.inMilliseconds > 0 &&
        position.inMilliseconds >= duration.inMilliseconds - 300;

    void seekBy(int seconds) {
      final target = position + Duration(seconds: seconds);
      if (target < Duration.zero) {
        controller.seekTo(Duration.zero);
        return;
      }
      if (duration > Duration.zero && target > duration) {
        controller.seekTo(duration);
        return;
      }
      controller.seekTo(target);
      _showControls();
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _showControls,
      onDoubleTapDown: (details) =>
          _lastDoubleTapPosition = details.localPosition,
      onDoubleTap: () {
        final box = context.findRenderObject() as RenderBox?;
        final width = box?.size.width ?? 0;
        final tapX = _lastDoubleTapPosition?.dx ?? (width / 2);
        seekBy(tapX < width / 2 ? -5 : 5);
      },
      child: Stack(
        children: [
          AnimatedOpacity(
            opacity: _controlsVisible ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            child: IgnorePointer(
              ignoring: !_controlsVisible,
              child: Stack(
                children: [
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.42,
                            ),
                            fixedSize: const Size(46, 46),
                          ),
                          onPressed: () => seekBy(-5),
                          icon: const Icon(Icons.replay_5),
                        ),
                        const SizedBox(width: 14),
                        IconButton.filled(
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.46,
                            ),
                            fixedSize: const Size(58, 58),
                          ),
                          onPressed: () {
                            if (isFinished) {
                              controller.seekTo(Duration.zero);
                              controller.play();
                            } else if (value.isPlaying) {
                              controller.pause();
                            } else {
                              controller.play();
                            }
                            _showControls();
                          },
                          icon: Icon(
                            isFinished
                                ? Icons.replay
                                : value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                        ),
                        const SizedBox(width: 14),
                        IconButton.filledTonal(
                          color: Colors.white,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(
                              alpha: 0.42,
                            ),
                            fixedSize: const Size(46, 46),
                          ),
                          onPressed: () => seekBy(5),
                          icon: const Icon(Icons.forward_5),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.78),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(4, 40, 4, 3),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 2.5,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 5,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                            overlayRadius: 12,
                                          ),
                                    ),
                                    child: Slider(
                                      value: currentMilliseconds.toDouble(),
                                      min: 0,
                                      max: maxMilliseconds,
                                      onChanged: (milliseconds) {
                                        controller.seekTo(
                                          Duration(
                                            milliseconds: milliseconds.round(),
                                          ),
                                        );
                                        _showControls();
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: widget.fullscreenTooltip,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints.tightFor(
                                    width: 38,
                                    height: 38,
                                  ),
                                  color: Colors.white,
                                  onPressed: widget.onFullscreen,
                                  icon: Icon(widget.fullscreenIcon, size: 22),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }
}
