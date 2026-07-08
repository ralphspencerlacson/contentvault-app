part of '../main.dart';

class MuxThumbnail extends StatelessWidget {
  const MuxThumbnail({super.key, required this.video});

  final UploadedVideo video;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 72,
        height: 48,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              video.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => ColoredBox(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.movie_outlined, color: colorScheme.primary),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.48),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoListTile extends StatelessWidget {
  const VideoListTile({
    super.key,
    required this.video,
    required this.previewing,
    required this.onPreviewVisible,
    required this.onTap,
    this.onCreatorTap,
    this.onMoreTap,
  });

  final UploadedVideo video;
  final bool previewing;
  final VoidCallback onPreviewVisible;
  final VoidCallback onTap;
  final VoidCallback? onCreatorTap;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('video-${video.playbackId}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0.72) onPreviewVisible();
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onTap,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    previewing
                        ? VideoPreviewThumbnail(video: video)
                        : VideoPoster(video: video),
                    Positioned(
                      left: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.62),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                previewing
                                    ? Icons.volume_off
                                    : Icons.play_arrow,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                previewing ? 'Previewing' : 'Tap to watch',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onCreatorTap,
                    child: CircleAvatar(
                      radius: 18,
                      child: Text(video.creator[video.creator.length - 1]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: onTap,
                          child: Text(
                            video.displayTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: onCreatorTap,
                          child: Text(
                            '${video.creator} • ${video.formattedUploadDate}',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(video.viewsLabel),
                            const SizedBox(width: 14),
                            Icon(
                              Icons.favorite,
                              size: 16,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 4),
                            Text(video.heartsLabel),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'More',
                    onPressed: onMoreTap,
                    icon: const Icon(Icons.more_vert),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPoster extends StatelessWidget {
  const VideoPoster({super.key, required this.video});

  final UploadedVideo video;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          video.thumbnailUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: Icon(Icons.movie_outlined, color: colorScheme.primary),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.play_arrow, color: Colors.white, size: 34),
            ),
          ),
        ),
      ],
    );
  }
}

class VideoPreviewThumbnail extends StatefulWidget {
  const VideoPreviewThumbnail({super.key, required this.video});

  final UploadedVideo video;

  @override
  State<VideoPreviewThumbnail> createState() => _VideoPreviewThumbnailState();
}

class _VideoPreviewThumbnailState extends State<VideoPreviewThumbnail> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _startPreview();
  }

  @override
  void didUpdateWidget(covariant VideoPreviewThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video.playbackId != widget.video.playbackId) {
      _controller?.dispose();
      _controller = null;
      _ready = false;
      _startPreview();
    }
  }

  Future<void> _startPreview() async {
    final controller = VideoPlayerController.networkUrl(
      widget.video.playbackUri,
    );
    _controller = controller;
    try {
      await controller.initialize();
      await controller.setVolume(0);
      await controller.setLooping(true);
      await controller.play();
    } catch (_) {
      if (_controller == controller) _controller = null;
      await controller.dispose();
      return;
    }
    if (!mounted || _controller != controller) {
      await controller.dispose();
      return;
    }
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (!_ready || controller == null) return VideoPoster(video: widget.video);

    return Stack(
      fit: StackFit.expand,
      children: [
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width,
            height: controller.value.size.height,
            child: VideoPlayer(controller),
          ),
        ),
        Align(
          alignment: Alignment.bottomRight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.volume_off, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
    );
  }
}
