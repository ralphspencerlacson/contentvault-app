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
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
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
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
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

    return Stack(
      children: [
        Center(
          child: IconButton.filled(
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.46),
              fixedSize: const Size(54, 54),
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
            },
            icon: Icon(
              isFinished
                  ? Icons.replay
                  : value.isPlaying
                  ? Icons.pause
                  : Icons.play_arrow,
            ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 12,
                            ),
                          ),
                          child: Slider(
                            value: currentMilliseconds.toDouble(),
                            min: 0,
                            max: maxMilliseconds,
                            onChanged: (milliseconds) {
                              controller.seekTo(
                                Duration(milliseconds: milliseconds.round()),
                              );
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
