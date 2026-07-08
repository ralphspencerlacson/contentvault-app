part of '../main.dart';

enum WatchExitAction { close, minimize }

Route<WatchExitAction> watchVideoRoute({
  required UploadedVideo video,
  required VideoPlayerController controller,
  required Future<void> initializeFuture,
  bool expandFromMini = false,
}) {
  return PageRouteBuilder<WatchExitAction>(
    transitionDuration: Duration(milliseconds: expandFromMini ? 360 : 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => WatchVideoScreen(
      video: video,
      controller: controller,
      initializeFuture: initializeFuture,
    ),
    transitionsBuilder: (_, animation, _, child) {
      if (!expandFromMini) {
        return FadeTransition(opacity: animation, child: child);
      }

      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      final offset = Tween<Offset>(
        begin: const Offset(0.28, 0.42),
        end: Offset.zero,
      ).animate(curved);
      final scale = Tween<double>(begin: 0.48, end: 1).animate(curved);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: offset,
          child: ScaleTransition(
            scale: scale,
            alignment: Alignment.bottomRight,
            child: child,
          ),
        ),
      );
    },
  );
}

class WatchVideoScreen extends StatefulWidget {
  const WatchVideoScreen({
    super.key,
    required this.video,
    required this.controller,
    required this.initializeFuture,
  });

  final UploadedVideo video;
  final VideoPlayerController controller;
  final Future<void> initializeFuture;

  @override
  State<WatchVideoScreen> createState() => _WatchVideoScreenState();
}

class _WatchVideoScreenState extends State<WatchVideoScreen> {
  var _dragDistance = 0.0;
  final _detailsScrollController = ScrollController();
  final _commentController = TextEditingController();
  final _expandedReplies = <int>{};
  final _replyingComments = <int>{};
  final _commentsKey = GlobalKey();
  late UploadedVideo _video;
  late VideoPlayerController _controller;
  late Future<void> _initializeFuture;
  var _ownsController = false;
  bool _hearted = false;
  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _video = widget.video;
    _controller = widget.controller;
    _initializeFuture = widget.initializeFuture;
  }

  @override
  void dispose() {
    _detailsScrollController.dispose();
    _commentController.dispose();
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _minimize() {
    if (_ownsController) {
      Navigator.of(context).pop(WatchExitAction.close);
      return;
    }
    Navigator.of(context).pop(WatchExitAction.minimize);
  }

  Future<void> _openFullscreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FullscreenVideoScreen(
          controller: _controller,
          onNextVideo: _playNextVideo,
        ),
      ),
    );
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  void _scrollToComments() {
    final context = _commentsKey.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  List<UploadedVideo> get _nextVideos {
    final videos = [...uploadedVideos]
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    return videos
        .where((video) => video.playbackId != _video.playbackId)
        .toList();
  }

  Future<VideoPlayerController?> _playNextVideo() async {
    final nextVideos = _nextVideos;
    if (nextVideos.isEmpty) return null;
    return _playSuggestedVideo(nextVideos.first, disposePrevious: false);
  }

  Future<VideoPlayerController> _playSuggestedVideo(
    UploadedVideo video, {
    bool disposePrevious = true,
  }) async {
    final oldController = _controller;
    final shouldDisposeOld = _ownsController;
    final controller = VideoPlayerController.networkUrl(video.playbackUri);
    final initializeFuture = controller.initialize().then(
      (_) => controller.play(),
    );

    setState(() {
      _video = video;
      _controller = controller;
      _initializeFuture = initializeFuture;
      _ownsController = true;
      _hearted = false;
      _descriptionExpanded = false;
      _expandedReplies.clear();
      _replyingComments.clear();
    });
    if (_detailsScrollController.hasClients) {
      _detailsScrollController.jumpTo(0);
    }
    if (shouldDisposeOld && disposePrevious) {
      await oldController.dispose();
    } else {
      await oldController.pause();
    }
    return controller;
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    final width = MediaQuery.sizeOf(context).width;
    final videoHeight = (width * 0.64).clamp(232.0, 340.0);
    final dragProgress = (_dragDistance / 420).clamp(0.0, 1.0);

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _minimize();
      },
      child: Scaffold(
        body: Stack(
          children: [
            AnimatedOpacity(
              opacity: 1 - (dragProgress * 0.9),
              duration: const Duration(milliseconds: 80),
              child: ListView(
                controller: _detailsScrollController,
                padding: EdgeInsets.fromLTRB(18, videoHeight + 18, 18, 28),
                children: [
                  const SizedBox(height: 16),
                  Text(
                    video.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Creator: ${video.creator}'),
                  Text('Uploaded: ${video.formattedUploadDate}'),
                  const SizedBox(height: 12),
                  _WatchStats(
                    video: video,
                    hearted: _hearted,
                    onHeart: () => setState(() => _hearted = !_hearted),
                    onComments: _scrollToComments,
                  ),
                  const SizedBox(height: 18),
                  _DescriptionBubble(
                    video: video,
                    expanded: _descriptionExpanded,
                    onToggleExpanded: () => setState(
                      () => _descriptionExpanded = !_descriptionExpanded,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _NextVideosSection(
                    videos: _nextVideos,
                    onPlay: _playSuggestedVideo,
                  ),
                  const SizedBox(height: 22),
                  TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a public comment...',
                      suffixIcon: IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.send),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    key: _commentsKey,
                    children: [
                      Expanded(
                        child: Text(
                          'Comments',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Text('${video.mockComments.length} threads'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < video.mockComments.length; i++)
                    _CommentBubble(
                      comment: video.mockComments[i],
                      repliesExpanded: _expandedReplies.contains(i),
                      onToggleReplies: () {
                        setState(() {
                          if (!_expandedReplies.remove(i)) {
                            _expandedReplies.add(i);
                          }
                        });
                      },
                      replying: _replyingComments.contains(i),
                      onReply: () {
                        setState(() {
                          if (!_replyingComments.remove(i)) {
                            _replyingComments.add(i);
                          }
                        });
                      },
                    ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _PinnedVideoHeader(
                video: video,
                controller: _controller,
                initializeFuture: _initializeFuture,
                onMinimize: _minimize,
                onFullscreen: _openFullscreen,
                dragDistance: _dragDistance,
                expandedHeight: videoHeight,
                onDragUpdate: (details) {
                  setState(() {
                    _dragDistance = (_dragDistance + details.delta.dy).clamp(
                      0.0,
                      420.0,
                    );
                  });
                },
                onDragEnd: () {
                  if (_dragDistance > 90) _minimize();
                  setState(() => _dragDistance = 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinnedVideoHeader extends StatelessWidget {
  const _PinnedVideoHeader({
    required this.video,
    required this.controller,
    required this.initializeFuture,
    required this.onMinimize,
    required this.onFullscreen,
    required this.dragDistance,
    required this.expandedHeight,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final UploadedVideo video;
  final VideoPlayerController controller;
  final Future<void> initializeFuture;
  final VoidCallback onMinimize;
  final VoidCallback onFullscreen;
  final double dragDistance;
  final double expandedHeight;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final progress = (dragDistance / 420).clamp(0.0, 1.0);
    final size = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final scale = 1 - (progress * 0.52);
    final finalWidth = size.width * scale;
    final finalHeight = expandedHeight * scale;
    final targetX = (size.width - finalWidth - 16).clamp(0.0, size.width);
    final targetY =
        (size.height - safePadding.top - safePadding.bottom - finalHeight - 16)
            .clamp(0.0, size.height);
    final translateX = targetX * progress;
    final translateY = targetY * progress;

    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: expandedHeight,
        child: GestureDetector(
          onVerticalDragUpdate: onDragUpdate,
          onVerticalDragEnd: (_) => onDragEnd(),
          child: Transform.translate(
            offset: Offset(translateX, translateY),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18 * progress),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      if (progress > 0)
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: 0.35 * progress,
                          ),
                          blurRadius: 24 * progress,
                        ),
                    ],
                  ),
                  child: FutureBuilder<void>(
                    future: initializeFuture,
                    builder: (context, snapshot) {
                      final hasError = snapshot.hasError;
                      final isReady =
                          snapshot.connectionState == ConnectionState.done &&
                          !hasError &&
                          controller.value.isInitialized;

                      return SizedBox(
                        width: double.infinity,
                        height: expandedHeight,
                        child: ColoredBox(
                          color: Colors.black,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (isReady)
                                FittedBox(
                                  fit: BoxFit.cover,
                                  clipBehavior: Clip.hardEdge,
                                  child: SizedBox(
                                    width: controller.value.size.width,
                                    height: controller.value.size.height,
                                    child: VideoPlayer(controller),
                                  ),
                                )
                              else
                                Image.network(
                                  video.thumbnailUrl,
                                  fit: BoxFit.cover,
                                ),
                              if (!isReady)
                                ColoredBox(
                                  color: Colors.black.withValues(alpha: 0.58),
                                  child: Center(
                                    child: hasError
                                        ? const Text(
                                            'Could not load video.',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 12),
                                              Text(
                                                'Loading video...',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              Positioned(
                                left: 8,
                                top: 8,
                                child: IconButton.filledTonal(
                                  tooltip: 'Mini player',
                                  onPressed: onMinimize,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                ),
                              ),
                              if (isReady)
                                VideoControls(
                                  controller: controller,
                                  onFullscreen: onFullscreen,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WatchStats extends StatelessWidget {
  const _WatchStats({
    required this.video,
    required this.hearted,
    required this.onHeart,
    required this.onComments,
  });

  final UploadedVideo video;
  final bool hearted;
  final VoidCallback onHeart;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      children: [
        _StatChip(
          icon: Icons.visibility_outlined,
          label: video.viewsLabel,
          color: colorScheme.primary,
        ),
        _StatChip(
          icon: hearted ? Icons.favorite : Icons.favorite_border,
          label: '${video.heartsLabel} hearts',
          color: colorScheme.error,
          onTap: onHeart,
        ),
        _StatChip(
          icon: Icons.mode_comment_outlined,
          label: '${video.mockComments.length} comments',
          color: colorScheme.secondary,
          onTap: onComments,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionBubble extends StatelessWidget {
  const _DescriptionBubble({
    required this.video,
    required this.expanded,
    required this.onToggleExpanded,
  });

  final UploadedVideo video;
  final bool expanded;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Description', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            video.displayDescription,
            maxLines: expanded ? null : 4,
            overflow: expanded ? TextOverflow.visible : TextOverflow.fade,
            softWrap: true,
            style: const TextStyle(fontFamily: 'monospace', height: 1.45),
          ),
          if (expanded) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                video.playbackId,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.58),
                ),
              ),
            ),
          ],
          Center(
            child: TextButton.icon(
              onPressed: onToggleExpanded,
              icon: Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              ),
              label: Text(expanded ? 'View less' : 'View more'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    required this.repliesExpanded,
    required this.onToggleReplies,
    required this.replying,
    required this.onReply,
  });

  final MockComment comment;
  final bool repliesExpanded;
  final VoidCallback onToggleReplies;
  final bool replying;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final replies = comment.replies;
    final visibleReplies = repliesExpanded ? replies : replies.take(1).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text(comment.authorInitial)),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 5),
                      Text(comment.body),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: onReply,
                            icon: const Icon(Icons.reply, size: 16),
                            label: Text(replying ? 'Cancel reply' : 'Reply'),
                          ),
                          TextButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.keyboard_arrow_up, size: 18),
                            label: const Text('Upvote 12'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (replying) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: TextField(
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Reply to ${comment.author}...',
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send),
                  ),
                ),
              ),
            ),
          ],
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 54),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final reply in visibleReplies)
                    _ReplyBubble(reply: reply),
                  if (replies.length > 1)
                    TextButton(
                      onPressed: onToggleReplies,
                      child: Text(
                        repliesExpanded
                            ? 'View less replies'
                            : 'View ${replies.length - visibleReplies.length} more replies',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NextVideosSection extends StatelessWidget {
  const _NextVideosSection({required this.videos, required this.onPlay});

  final List<UploadedVideo> videos;
  final ValueChanged<UploadedVideo> onPlay;

  @override
  Widget build(BuildContext context) {
    final suggestions = videos.take(4).toList();
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Next videos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        for (final video in suggestions)
          Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () => onPlay(video),
              child: SizedBox(
                height: 96,
                child: Row(
                  children: [
                    SizedBox(
                      width: 156,
                      height: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            video.thumbnailUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => ColoredBox(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.movie_outlined,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                          Center(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.48),
                                shape: BoxShape.circle,
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.displayTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const Spacer(),
                            Text(
                              video.creator,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${video.viewsLabel} • ${video.formattedUploadDate}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  const _ReplyBubble({required this.reply});

  final MockReply reply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(radius: 14, child: Text(reply.authorInitial)),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reply.author,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(reply.body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
