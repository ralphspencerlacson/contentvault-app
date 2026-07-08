part of '../main.dart';

enum WatchExitAction { close, minimize }

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
  final _commentsKey = GlobalKey();
  bool _hearted = false;
  bool _descriptionExpanded = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _detailsScrollController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _minimize() {
    Navigator.of(context).pop(WatchExitAction.minimize);
  }

  Future<void> _openFullscreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => FullscreenVideoScreen(controller: widget.controller),
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

  @override
  Widget build(BuildContext context) {
    final video = widget.video;

    return PopScope<void>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _minimize();
      },
      child: Scaffold(
        body: Column(
          children: [
            _PinnedVideoHeader(
              video: video,
              controller: widget.controller,
              initializeFuture: widget.initializeFuture,
              onMinimize: _minimize,
              onFullscreen: _openFullscreen,
              onDragUpdate: (details) => _dragDistance += details.delta.dy,
              onDragEnd: () {
                if (_dragDistance > 90) _minimize();
                _dragDistance = 0;
              },
            ),
            Expanded(
              child: ListView(
                controller: _detailsScrollController,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                children: [
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
                  const SizedBox(height: 12),
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

class _PinnedVideoHeader extends StatelessWidget {
  const _PinnedVideoHeader({
    required this.video,
    required this.controller,
    required this.initializeFuture,
    required this.onMinimize,
    required this.onFullscreen,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final UploadedVideo video;
  final VideoPlayerController controller;
  final Future<void> initializeFuture;
  final VoidCallback onMinimize;
  final VoidCallback onFullscreen;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: GestureDetector(
        onVerticalDragUpdate: onDragUpdate,
        onVerticalDragEnd: (_) => onDragEnd(),
        child: FutureBuilder<void>(
          future: initializeFuture,
          builder: (context, snapshot) {
            final hasError = snapshot.hasError;
            final isReady =
                snapshot.connectionState == ConnectionState.done &&
                !hasError &&
                controller.value.isInitialized;

            return AspectRatio(
              aspectRatio: isReady ? controller.value.aspectRatio : 16 / 9,
              child: ColoredBox(
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isReady)
                      VideoPlayer(controller)
                    else
                      Image.network(video.thumbnailUrl, fit: BoxFit.cover),
                    if (!isReady)
                      ColoredBox(
                        color: Colors.black.withValues(alpha: 0.58),
                        child: Center(
                          child: hasError
                              ? const Text(
                                  'Could not load video.',
                                  style: TextStyle(color: Colors.white),
                                )
                              : const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 12),
                                    Text(
                                      'Loading video...',
                                      style: TextStyle(color: Colors.white),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              video.displayDescription,
              maxLines: expanded ? null : 4,
              overflow: expanded ? TextOverflow.visible : TextOverflow.fade,
              softWrap: true,
              style: const TextStyle(fontFamily: 'monospace', height: 1.45),
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: onToggleExpanded,
              icon: Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              ),
              label: Text(expanded ? 'View less' : 'View more'),
            ),
          ),
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
      ),
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    required this.repliesExpanded,
    required this.onToggleReplies,
  });

  final MockComment comment;
  final bool repliesExpanded;
  final VoidCallback onToggleReplies;

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
                            onPressed: () {},
                            icon: const Icon(Icons.reply, size: 16),
                            label: const Text('Reply'),
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
