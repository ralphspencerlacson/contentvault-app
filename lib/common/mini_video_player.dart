part of '../main.dart';

class MiniVideoPlayer extends StatelessWidget {
  const MiniVideoPlayer({
    super.key,
    required this.video,
    required this.controller,
    required this.onExpand,
    required this.onClose,
  });

  final UploadedVideo video;
  final VideoPlayerController controller;
  final VoidCallback onExpand;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('mini-${video.playbackId}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onClose(),
      child: _MiniVideoSurface(controller: controller, onExpand: onExpand),
    );
  }
}

class _MiniVideoSurface extends StatefulWidget {
  const _MiniVideoSurface({required this.controller, required this.onExpand});

  final VideoPlayerController controller;
  final VoidCallback onExpand;

  @override
  State<_MiniVideoSurface> createState() => _MiniVideoSurfaceState();
}

class _MiniVideoSurfaceState extends State<_MiniVideoSurface> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _togglePlay() {
    if (widget.controller.value.isPlaying) {
      widget.controller.pause();
    } else {
      widget.controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 240,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: GestureDetector(
            onTap: widget.onExpand,
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: Colors.black,
                    child: VideoPlayer(widget.controller),
                  ),
                  Center(
                    child: IconButton.filled(
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.46),
                      ),
                      onPressed: _togglePlay,
                      icon: Icon(
                        widget.controller.value.isPlaying
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
