part of '../main.dart';

class SubscriberScreen extends StatefulWidget {
  const SubscriberScreen({super.key, required this.username});

  final String username;

  @override
  State<SubscriberScreen> createState() => _SubscriberScreenState();
}

class _SubscriberScreenState extends State<SubscriberScreen> {
  VideoPlayerController? _controller;
  UploadedVideo? _selectedVideo;
  bool _miniPlayer = false;
  bool _showSearch = false;
  String? _previewPlaybackId;

  @override
  void dispose() {
    _hideMiniPlayer();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _playVideo(UploadedVideo video) async {
    final oldController = _controller;
    final controller = VideoPlayerController.networkUrl(video.playbackUri);
    final navigator = Navigator.of(context);
    final initializeFuture = controller.initialize().then(
      (_) => controller.play(),
    );

    setState(() {
      _controller = controller;
      _selectedVideo = video;
      _miniPlayer = false;
    });
    await oldController?.dispose();

    final action = await navigator.push<WatchExitAction>(
      watchVideoRoute(
        video: video,
        controller: controller,
        initializeFuture: initializeFuture,
      ),
    );

    if (!mounted) return;
    if (action == WatchExitAction.minimize) {
      setState(() => _miniPlayer = true);
      _showMiniPlayer();
    } else {
      await _closePlayer();
    }
  }

  Future<void> _expandMiniPlayer() async {
    final controller = _controller;
    final video = _selectedVideo;
    if (controller == null || video == null) return;

    final navigator = Navigator.of(context);
    _hideMiniPlayer();
    setState(() => _miniPlayer = false);
    final action = await navigator.push<WatchExitAction>(
      watchVideoRoute(
        video: video,
        controller: controller,
        initializeFuture: Future<void>.value(),
        expandFromMini: true,
      ),
    );

    if (!mounted) return;
    if (action == WatchExitAction.minimize) {
      setState(() => _miniPlayer = true);
      _showMiniPlayer();
    } else {
      await _closePlayer();
    }
  }

  Future<void> _closePlayer() async {
    final oldController = _controller;
    _hideMiniPlayer();
    setState(() {
      _controller = null;
      _selectedVideo = null;
      _miniPlayer = false;
    });
    await oldController?.dispose();
  }

  void _showMiniPlayer() {
    final video = _selectedVideo;
    final controller = _controller;
    if (video == null || controller == null) return;

    appMiniPlayer.value = AppMiniPlayer(
      video: video,
      controller: controller,
      onExpand: _expandMiniPlayer,
      onClose: _closePlayer,
    );
  }

  void _hideMiniPlayer() {
    if (appMiniPlayer.value?.controller == _controller) {
      appMiniPlayer.value = null;
    }
  }

  Future<void> _logout() async {
    await clearSession();
  }

  void _openCreatorVideos(String creator) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CreatorVideosScreen(creator: creator, onPlay: _playVideo),
      ),
    );
  }

  void _openCreatorDirectory() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CreatorDirectoryScreen(onOpenCreator: _openCreatorVideos),
      ),
    );
  }

  void _showVideoMenu(UploadedVideo video) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Icons.bookmark_add_outlined),
              title: Text('Watch later'),
            ),
            const ListTile(
              leading: Icon(Icons.favorite_border),
              title: Text('Favorite video'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('View ${video.creator}'),
              onTap: () {
                Navigator.of(context).pop();
                _openCreatorVideos(video.creator);
              },
            ),
            const ListTile(
              leading: Icon(Icons.visibility_off_outlined),
              title: Text('Hide'),
            ),
            const ListTile(
              leading: Icon(Icons.flag_outlined),
              title: Text('Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latestVideos = [...uploadedVideos]
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    final creators = latestVideos.map((video) => video.creator).toSet();

    return Scaffold(
      drawer: SettingsDrawer(
        username: widget.username,
        role: 'subscriber',
        onVideosTap: () => Navigator.of(context).pop(),
        onCreatorsTap: _openCreatorDirectory,
        onLogout: _logout,
      ),
      appBar: AppBar(
        title: _showSearch
            ? const TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search videos...',
                  border: InputBorder.none,
                ),
              )
            : const Text('Homepage'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => setState(() => _showSearch = !_showSearch),
            icon: Icon(_showSearch ? Icons.close : Icons.search),
          ),
        ],
      ),
      body: SafeArea(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: Theme.of(context).brightness == Brightness.dark
                  ? const [Color(0xFF101525), Color(0xFF080A12)]
                  : const [Color(0xFFF7F4FF), Color(0xFFFFFFFF)],
            ),
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 920),
              child: SizedBox.expand(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Latest videos',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final creator in creators)
                                ActionChip(
                                  avatar: const Icon(Icons.verified, size: 18),
                                  label: Text(creator),
                                  onPressed: () => _openCreatorVideos(creator),
                                ),
                              if (creators.isEmpty)
                                const Chip(label: Text('Waiting for uploads')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: latestVideos.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No uploaded videos are available in this app session.',
                                    ),
                                  )
                                : ListView(
                                    padding: EdgeInsets.only(
                                      bottom: _miniPlayer ? 170 : 0,
                                    ),
                                    children: [
                                      for (final video in latestVideos)
                                        VideoListTile(
                                          video: video,
                                          previewing:
                                              _previewPlaybackId ==
                                              video.playbackId,
                                          onPreviewVisible: () {
                                            if (_previewPlaybackId !=
                                                video.playbackId) {
                                              setState(
                                                () => _previewPlaybackId =
                                                    video.playbackId,
                                              );
                                            }
                                          },
                                          onTap: () => _playVideo(video),
                                          onCreatorTap: () =>
                                              _openCreatorVideos(video.creator),
                                          onMoreTap: () =>
                                              _showVideoMenu(video),
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CreatorVideosScreen extends StatelessWidget {
  const CreatorVideosScreen({
    super.key,
    required this.creator,
    required this.onPlay,
  });

  final String creator;
  final ValueChanged<UploadedVideo> onPlay;

  @override
  Widget build(BuildContext context) {
    final videos =
        uploadedVideos.where((video) => video.creator == creator).toList()
          ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));

    return Scaffold(
      appBar: AppBar(title: Text(creator)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '$creator videos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            for (final video in videos)
              VideoListTile(
                video: video,
                previewing: false,
                onPreviewVisible: () {},
                onTap: () => onPlay(video),
              ),
          ],
        ),
      ),
    );
  }
}

class CreatorBrowseVideosScreen extends StatefulWidget {
  const CreatorBrowseVideosScreen({super.key, required this.onPlay});

  final ValueChanged<UploadedVideo> onPlay;

  @override
  State<CreatorBrowseVideosScreen> createState() =>
      _CreatorBrowseVideosScreenState();
}

class _CreatorBrowseVideosScreenState extends State<CreatorBrowseVideosScreen> {
  bool _showSearch = false;

  void _showHomepageVideoMenu(UploadedVideo video) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              leading: Icon(Icons.bookmark_add_outlined),
              title: Text('Watch later'),
            ),
            const ListTile(
              leading: Icon(Icons.favorite_border),
              title: Text('Favorite video'),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('View ${video.creator}'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => CreatorVideosScreen(
                      creator: video.creator,
                      onPlay: widget.onPlay,
                    ),
                  ),
                );
              },
            ),
            const ListTile(
              leading: Icon(Icons.visibility_off_outlined),
              title: Text('Hide'),
            ),
            const ListTile(
              leading: Icon(Icons.flag_outlined),
              title: Text('Report'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final latestVideos = [...uploadedVideos]
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    final creators = latestVideos.map((video) => video.creator).toSet();

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? const TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search videos...',
                  border: InputBorder.none,
                ),
              )
            : const Text('Homepage'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => setState(() => _showSearch = !_showSearch),
            icon: Icon(_showSearch ? Icons.close : Icons.search),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Latest creator videos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final creator in creators)
                  ActionChip(
                    avatar: const Icon(Icons.verified, size: 18),
                    label: Text(creator),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CreatorVideosScreen(
                            creator: creator,
                            onPlay: widget.onPlay,
                          ),
                        ),
                      );
                    },
                  ),
                if (creators.isEmpty)
                  const Chip(label: Text('Waiting for uploads')),
              ],
            ),
            const SizedBox(height: 16),
            if (latestVideos.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No videos are available in this app session.'),
                ),
              ),
            for (final video in latestVideos)
              VideoListTile(
                video: video,
                previewing: false,
                onPreviewVisible: () {},
                onTap: () => widget.onPlay(video),
                onCreatorTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CreatorVideosScreen(
                        creator: video.creator,
                        onPlay: widget.onPlay,
                      ),
                    ),
                  );
                },
                onMoreTap: () => _showHomepageVideoMenu(video),
              ),
          ],
        ),
      ),
    );
  }
}

class CreatorDirectoryScreen extends StatefulWidget {
  const CreatorDirectoryScreen({super.key, required this.onOpenCreator});

  final ValueChanged<String> onOpenCreator;

  @override
  State<CreatorDirectoryScreen> createState() => _CreatorDirectoryScreenState();
}

class _CreatorDirectoryScreenState extends State<CreatorDirectoryScreen> {
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    final creators =
        uploadedVideos.map((video) => video.creator).toSet().toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? const TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search creators...',
                  border: InputBorder.none,
                ),
              )
            : const Text('Creators'),
        actions: [
          IconButton(
            tooltip: 'Search',
            onPressed: () => setState(() => _showSearch = !_showSearch),
            icon: Icon(_showSearch ? Icons.close : Icons.search),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Creators', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            if (creators.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Creators will appear after videos are uploaded.',
                  ),
                ),
              ),
            for (final creator in creators)
              Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(creator[creator.length - 1]),
                  ),
                  title: Text('John Doe'),
                  subtitle: Text('@$creator'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onOpenCreator(creator);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
