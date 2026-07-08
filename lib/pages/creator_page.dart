part of '../main.dart';

class CreatorScreen extends StatefulWidget {
  const CreatorScreen({super.key, required this.username});

  final String username;

  @override
  State<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends State<CreatorScreen> {
  final _muxClient = MuxClient(muxTokenId, muxTokenSecret);
  final _titleController = TextEditingController();
  final _uploadDialogData = ValueNotifier<_UploadDialogData>(
    const _UploadDialogData(message: 'Preparing upload...'),
  );
  VideoPlayerController? _previewController;
  VideoPlayerController? _creatorPlaybackController;
  PlatformFile? _selectedFile;
  UploadedVideo? _selectedUploadedVideo;
  UploadedVideo? _completedUploadVideo;
  Uint8List? _selectedBytes;
  UploadProgress? _progress;
  bool _showUploadForm = false;
  bool _showMyVideos = false;
  bool _pickingVideo = false;
  bool _uploading = false;
  bool _creatorMiniPlayer = false;
  bool _showCreatorHomeSearch = false;
  bool _showMyVideosSearch = false;
  int _uploadStep = 0;
  String? _creatorPreviewPlaybackId;
  String? _message;
  String? _fileSelectionError;
  double? _selectedAspectRatio;
  bool _uploadFailed = false;

  bool get _selectedRatioIsValid =>
      _selectedAspectRatio != null &&
      isSupportedUploadAspectRatio(_selectedAspectRatio!);

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      if (_showUploadForm && _selectedFile != null && mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _hideCreatorMiniPlayer();
    _previewController?.dispose();
    _creatorPlaybackController?.dispose();
    _uploadDialogData.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _playUploadedVideo(UploadedVideo video) async {
    final oldController = _creatorPlaybackController;
    final controller = VideoPlayerController.networkUrl(video.playbackUri);
    final navigator = Navigator.of(context);
    final initializeFuture = controller.initialize().then(
      (_) => controller.play(),
    );

    setState(() {
      _creatorPlaybackController = controller;
      _selectedUploadedVideo = video;
      _creatorMiniPlayer = false;
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
      setState(() => _creatorMiniPlayer = true);
      _showCreatorMiniPlayer();
    } else {
      await _closeCreatorPlayer();
    }
  }

  Future<void> _expandCreatorMiniPlayer() async {
    final controller = _creatorPlaybackController;
    final video = _selectedUploadedVideo;
    if (controller == null || video == null) return;

    final navigator = Navigator.of(context);
    _hideCreatorMiniPlayer();
    setState(() => _creatorMiniPlayer = false);
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
      setState(() => _creatorMiniPlayer = true);
      _showCreatorMiniPlayer();
    } else {
      await _closeCreatorPlayer();
    }
  }

  Future<void> _closeCreatorPlayer() async {
    final oldController = _creatorPlaybackController;
    _hideCreatorMiniPlayer();
    setState(() {
      _creatorPlaybackController = null;
      _selectedUploadedVideo = null;
      _creatorMiniPlayer = false;
    });
    await oldController?.dispose();
  }

  void _showCreatorMiniPlayer() {
    final video = _selectedUploadedVideo;
    final controller = _creatorPlaybackController;
    if (video == null || controller == null) return;

    appMiniPlayer.value = AppMiniPlayer(
      video: video,
      controller: controller,
      onExpand: _expandCreatorMiniPlayer,
      onClose: _closeCreatorPlayer,
    );
  }

  void _hideCreatorMiniPlayer() {
    if (appMiniPlayer.value?.controller == _creatorPlaybackController) {
      appMiniPlayer.value = null;
    }
  }

  void _showMyVideoMenu(UploadedVideo video) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit')),
            ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

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
                      onPlay: _playUploadedVideo,
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

  void _openCreatorDirectory() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CreatorDirectoryScreen(
          onOpenCreator: (creator) {
            Future<void>.microtask(() {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => CreatorVideosScreen(
                    creator: creator,
                    onPlay: _playUploadedVideo,
                  ),
                ),
              );
            });
          },
        ),
      ),
    );
  }

  Future<void> _pickVideo() async {
    setState(() {
      _pickingVideo = true;
      _fileSelectionError = null;
      _message = 'Preparing video preview...';
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null) {
      if (mounted) {
        setState(() {
          _pickingVideo = false;
          _message = null;
        });
      }
      return;
    }

    final oldController = _previewController;
    VideoPlayerController? previewController;
    double? aspectRatio;
    String? fileError;

    if (!_isSupportedVideoFile(file)) {
      await oldController?.dispose();
      setState(() {
        _selectedFile = null;
        _selectedBytes = null;
        _previewController = null;
        _selectedAspectRatio = null;
        _pickingVideo = false;
        _fileSelectionError =
            'Invalid file type. Please select an MP4, MOV, M4V, WEBM, MKV, AVI, or 3GP video.';
        _message = _fileSelectionError;
      });
      return;
    }

    if (file.path != null) {
      try {
        previewController = VideoPlayerController.file(File(file.path!));
        await previewController.initialize();
        await previewController.setLooping(true);
        await previewController.setVolume(0);
        await previewController.play();
        aspectRatio = previewController.value.aspectRatio;
      } catch (_) {
        await previewController?.dispose();
        previewController = null;
        fileError =
            'Could not preview this video. The file may be corrupted or unsupported.';
      }
    } else if (file.bytes == null) {
      fileError = 'Could not read this video file. Please choose another file.';
    }

    if (fileError == null && aspectRatio == null) {
      fileError =
          'Could not detect the video ratio. Please choose another file.';
    }

    if (fileError == null &&
        aspectRatio != null &&
        !isSupportedUploadAspectRatio(aspectRatio)) {
      fileError =
          'Invalid ratio: ${formatAspectRatio(aspectRatio)}. Upload a 16:9 landscape video.';
    }

    await oldController?.dispose();
    setState(() {
      _selectedFile = file;
      _selectedBytes = file.bytes;
      _previewController = previewController;
      _selectedAspectRatio = aspectRatio;
      _pickingVideo = false;
      _progress = null;
      _fileSelectionError = fileError;
      _message = fileError;
    });
  }

  bool _isSupportedVideoFile(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    const allowedExtensions = {
      'mp4',
      'mov',
      'm4v',
      'webm',
      'mkv',
      'avi',
      '3gp',
    };
    return extension != null && allowedExtensions.contains(extension);
  }

  Future<void> _uploadSelectedVideo() async {
    if (muxTokenId.isEmpty || muxTokenSecret.isEmpty) {
      setState(() => _message = 'Run with MUX_TOKEN_ID and MUX_TOKEN_SECRET.');
      return;
    }

    final videoTitle = _titleController.text.trim();
    if (videoTitle.isEmpty) {
      setState(() => _message = 'Add a video title before uploading.');
      return;
    }

    final file = _selectedFile;
    if (file == null) {
      setState(() => _message = 'Pick a video before uploading.');
      return;
    }

    if (!_selectedRatioIsValid) {
      setState(
        () => _message =
            'Please upload a 16:9 landscape video before uploading to Mux.',
      );
      return;
    }

    final bytes =
        _selectedBytes ??
        (file.path == null ? null : await File(file.path!).readAsBytes());
    if (bytes == null) {
      setState(() => _message = 'Could not read the selected video file.');
      return;
    }

    final uploadedAt = DateTime.now().toUtc();

    setState(() => _uploading = true);
    _setUploadStatus(
      progress: const UploadProgress(sentBytes: 0, totalBytes: 0),
      message: 'Preparing your upload...',
    );

    try {
      final upload = await _muxClient.createDirectUpload(title: videoTitle);
      _setUploadStatus(message: 'Uploading your video...');

      await _muxClient.uploadVideo(
        upload.url,
        bytes,
        onProgress: (progress) => _setUploadStatus(progress: progress),
      );

      _setUploadStatus(message: 'Processing your video...');
      final playbackId = await _muxClient.waitForPlaybackId(upload.id);
      final uploadedVideo = UploadedVideo(
        creator: widget.username,
        title: videoTitle,
        description: '',
        filename: file.name,
        playbackId: playbackId,
        uploadedAt: uploadedAt,
      );
      uploadedVideos.insert(0, uploadedVideo);
      setState(() => _completedUploadVideo = uploadedVideo);

      _setUploadStatus(message: 'Your video is ready.', isReady: true);
      await _resetUploadForm(closeForm: true);
    } catch (error) {
      // TODO: Persist the raw upload error/response to an upload logs collection.
      _setUploadStatus(
        message: 'Upload failed. Please try again.',
        hasError: true,
      );
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _setUploadStatus({
    UploadProgress? progress,
    String? message,
    bool hasError = false,
    bool isReady = false,
  }) {
    final nextProgress = progress ?? _progress;
    final nextMessage = message ?? _message;
    setState(() {
      _progress = nextProgress;
      _message = nextMessage;
      _uploadFailed = hasError;
    });
    _uploadDialogData.value = _UploadDialogData(
      progress: nextProgress,
      message: nextMessage,
      hasError: hasError,
      isReady: isReady,
    );
  }

  Future<void> _viewCompletedUpload() async {
    final video = _completedUploadVideo;
    if (video == null) return;
    Navigator.of(context).pop();
    setState(() => _completedUploadVideo = null);
    await _playUploadedVideo(video);
  }

  Future<void> _uploadWithGlow() async {
    if (!mounted) return;
    _uploadDialogData.value = const _UploadDialogData(
      message: 'Preparing your upload...',
    );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UploadingGlowDialog(
        data: _uploadDialogData,
        onViewVideo: _viewCompletedUpload,
      ),
    );
    await _uploadSelectedVideo();
    if (mounted && !_uploadFailed && _completedUploadVideo == null) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _logout() async {
    if (_uploading) {
      _showUploadInProgressWarning();
      return;
    }

    await clearSession();
  }

  void _showUploadInProgressWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Upload is still running. Keep the app open until it finishes.',
        ),
      ),
    );
  }

  void _openUploadForm() {
    setState(() {
      _showMyVideos = true;
      _showUploadForm = true;
      _message = null;
    });
  }

  Future<void> _closeUploadForm() async {
    if (_uploading) {
      _showUploadInProgressWarning();
      return;
    }

    await _resetUploadForm(closeForm: true);
  }

  Future<void> _resetUploadForm({required bool closeForm}) async {
    final oldController = _previewController;
    _titleController.clear();
    setState(() {
      _selectedFile = null;
      _selectedBytes = null;
      _previewController = null;
      _selectedAspectRatio = null;
      _fileSelectionError = null;
      _uploadStep = 0;
      _progress = null;
      _message = null;
      _uploadFailed = false;
      if (closeForm) _showUploadForm = false;
    });
    await oldController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: !_uploading && !_showUploadForm,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _uploading) _showUploadInProgressWarning();
        if (!didPop && !_uploading && _showUploadForm) _closeUploadForm();
      },
      child: Scaffold(
        drawer: SettingsDrawer(
          username: widget.username,
          role: 'creator',
          onVideosTap: () {
            Navigator.of(context).pop();
            setState(() {
              _showMyVideos = false;
              _showUploadForm = false;
            });
          },
          onCreatorsTap: _openCreatorDirectory,
          onMyVideosTap: () {
            Navigator.of(context).pop();
            setState(() => _showMyVideos = true);
          },
          onLogout: _logout,
        ),
        appBar: AppBar(
          title: _showCreatorHomeSearch && !_showMyVideos && !_showUploadForm
              ? const TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search videos...',
                    border: InputBorder.none,
                  ),
                )
              : Text(
                  _showMyVideos || _showUploadForm
                      ? 'Creator Studio'
                      : 'Homepage',
                ),
          actions: [
            if (!_showMyVideos && !_showUploadForm)
              IconButton(
                tooltip: 'Search',
                onPressed: () => setState(
                  () => _showCreatorHomeSearch = !_showCreatorHomeSearch,
                ),
                icon: Icon(_showCreatorHomeSearch ? Icons.close : Icons.search),
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
                constraints: const BoxConstraints(maxWidth: 820),
                child: SizedBox.expand(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final offset = Tween<Offset>(
                        begin: const Offset(0, 0.08),
                        end: Offset.zero,
                      ).animate(animation);
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(position: offset, child: child),
                      );
                    },
                    child: _showUploadForm
                        ? _buildUploadForm()
                        : _showMyVideos
                        ? _buildMyVideos()
                        : _buildCreatorHomepage(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreatorHomepage() {
    final latestVideos = [...uploadedVideos]
      ..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    final creators = latestVideos.map((video) => video.creator).toSet();

    return Padding(
      key: const ValueKey('creator-homepage'),
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
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CreatorVideosScreen(
                          creator: creator,
                          onPlay: _playUploadedVideo,
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
          Expanded(
            child: latestVideos.isEmpty
                ? const Center(
                    child: Text(
                      'No uploaded videos are available in this app session.',
                    ),
                  )
                : ListView(
                    padding: EdgeInsets.only(
                      bottom: _creatorMiniPlayer ? 170 : 0,
                    ),
                    children: [
                      for (final video in latestVideos)
                        VideoListTile(
                          video: video,
                          previewing:
                              _creatorPreviewPlaybackId == video.playbackId,
                          onPreviewVisible: () {
                            if (_creatorPreviewPlaybackId != video.playbackId) {
                              setState(
                                () => _creatorPreviewPlaybackId =
                                    video.playbackId,
                              );
                            }
                          },
                          onTap: () => _playUploadedVideo(video),
                          onCreatorTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => CreatorVideosScreen(
                                  creator: video.creator,
                                  onPlay: _playUploadedVideo,
                                ),
                              ),
                            );
                          },
                          onMoreTap: () => _showHomepageVideoMenu(video),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyVideos() {
    final myVideos = uploadedVideos
        .where((video) => video.creator == widget.username)
        .toList();
    return Stack(
      key: const ValueKey('my-videos'),
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _showMyVideosSearch
                        ? const TextField(
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search my videos...',
                              border: InputBorder.none,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'My Videos',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                myVideos.isEmpty
                                    ? 'Draft your first subscriber-ready upload.'
                                    : '${myVideos.length} published ${myVideos.length == 1 ? 'video' : 'videos'} in this session',
                              ),
                            ],
                          ),
                  ),
                  IconButton(
                    tooltip: 'Search',
                    onPressed: () => setState(
                      () => _showMyVideosSearch = !_showMyVideosSearch,
                    ),
                    icon: Icon(
                      _showMyVideosSearch ? Icons.close : Icons.search,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _openUploadForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Upload'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: myVideos.isEmpty
                    ? Card(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.video_library_outlined,
                                  size: 54,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Your shelf is empty',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Add a landscape video and it will appear here as soon as Mux finishes preparing playback.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _openUploadForm,
                                  icon: const Icon(Icons.cloud_upload),
                                  label: const Text('Start upload'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.only(
                          bottom: _creatorMiniPlayer ? 170 : 0,
                        ),
                        itemCount: myVideos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final video = myVideos[index];
                          return VideoListTile(
                            video: video,
                            previewing:
                                _creatorPreviewPlaybackId == video.playbackId,
                            onPreviewVisible: () {
                              if (_creatorPreviewPlaybackId !=
                                  video.playbackId) {
                                setState(
                                  () => _creatorPreviewPlaybackId =
                                      video.playbackId,
                                );
                              }
                            },
                            onTap: () => _playUploadedVideo(video),
                            onMoreTap: () => _showMyVideoMenu(video),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadForm() {
    final selectedFile = _selectedFile;
    final titleReady = _titleController.text.trim().isNotEmpty;
    final canUpload =
        selectedFile != null && !_uploading && _selectedRatioIsValid;

    return Padding(
      key: const ValueKey('upload-form'),
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        MediaQuery.viewInsetsOf(context).bottom > 0 ? 8 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _uploading ? null : _closeUploadForm,
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Upload a video to Mux',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          StepProgress(currentStep: _uploadStep),
          const SizedBox(height: 14),
          Expanded(
            child: _uploadStep == 0
                ? _buildDetailsStep(titleReady)
                : _buildVideoStep(selectedFile, canUpload),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(bool titleReady) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _titleController,
          enabled: !_uploading,
          decoration: const InputDecoration(
            labelText: 'Video title',
            hintText: 'Example: Morning workout preview',
          ),
          textInputAction: TextInputAction.next,
        ),
        const Spacer(),
        FilledButton.icon(
          onPressed: titleReady ? () => setState(() => _uploadStep = 1) : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Next: select video'),
        ),
      ],
    );
  }

  Widget _buildVideoStep(PlatformFile? selectedFile, bool canUpload) {
    final pickingVideo = _pickingVideo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _uploading || pickingVideo ? null : _pickVideo,
          icon: pickingVideo
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.video_file),
          label: Text(
            pickingVideo
                ? 'Preparing preview...'
                : selectedFile == null
                ? 'Pick Video'
                : 'Change Video',
          ),
        ),
        if (_fileSelectionError != null) ...[
          const SizedBox(height: 10),
          _FileErrorBanner(message: _fileSelectionError!),
        ],
        if (pickingVideo) ...[
          const SizedBox(height: 10),
          const Expanded(child: _VideoPreviewLoadingCard()),
        ] else if (selectedFile != null) ...[
          const SizedBox(height: 10),
          Expanded(child: _buildPreviewCard(selectedFile)),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: canUpload ? _uploadWithGlow : null,
            icon: const Icon(Icons.cloud_upload),
            label: Text(_uploadFailed ? 'Retry upload' : 'Upload video'),
          ),
        ] else
          const Expanded(
            child: Center(child: Text('Select a 16:9 landscape video.')),
          ),
      ],
    );
  }

  Widget _buildPreviewCard(PlatformFile file) {
    final previewController = _previewController;
    final title = _titleController.text.trim();
    final aspectRatio = _selectedAspectRatio;
    final ratioIsValid = _selectedRatioIsValid;
    final fileError = _fileSelectionError;

    return LayoutBuilder(
      builder: (context, constraints) {
        final previewHeight = (constraints.maxHeight * 0.48).clamp(
          120.0,
          220.0,
        );

        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: previewHeight,
                child:
                    previewController != null &&
                        previewController.value.isInitialized
                    ? FittedBox(
                        fit: BoxFit.cover,
                        clipBehavior: Clip.hardEdge,
                        child: SizedBox(
                          width: previewController.value.size.width,
                          height: previewController.value.size.height,
                          child: VideoPlayer(previewController),
                        ),
                      )
                    : ColoredBox(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Text('Preview unavailable for this file.'),
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title.isEmpty ? 'Untitled video' : title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text('Creator: ${widget.username}'),
                      Text(
                        'Filename: ${file.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text('Size: ${formatFileSize(file.size)}'),
                      if (aspectRatio != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          ratioIsValid
                              ? 'Aspect ratio accepted: ${formatAspectRatio(aspectRatio)}'
                              : 'Invalid ratio: ${formatAspectRatio(aspectRatio)}. Upload a 16:9 landscape video.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ratioIsValid
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (fileError != null) ...[
                        const SizedBox(height: 6),
                        _FileErrorBanner(message: fileError),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final steps = ['Details', 'Video'];
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: i <= currentStep
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white.withValues(alpha: 0.08),
              ),
              child: Text(
                steps[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: i <= currentStep
                      ? Theme.of(context).colorScheme.onPrimary
                      : null,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (i != steps.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _VideoPreviewLoadingCard extends StatefulWidget {
  const _VideoPreviewLoadingCard();

  @override
  State<_VideoPreviewLoadingCard> createState() =>
      _VideoPreviewLoadingCardState();
}

class _VideoPreviewLoadingCardState extends State<_VideoPreviewLoadingCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Card(
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary.withValues(
                    alpha: 0.10 + (_controller.value * 0.14),
                  ),
                  colorScheme.secondary.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 18),
                Text(
                  'Preparing video preview',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Checking file type, reading metadata, and validating aspect ratio.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FileErrorBanner extends StatelessWidget {
  const _FileErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadDialogData {
  const _UploadDialogData({
    this.progress,
    this.message,
    this.hasError = false,
    this.isReady = false,
  });

  final UploadProgress? progress;
  final String? message;
  final bool hasError;
  final bool isReady;
}

class _UploadingGlowDialog extends StatefulWidget {
  const _UploadingGlowDialog({required this.data, required this.onViewVideo});

  final ValueListenable<_UploadDialogData> data;
  final VoidCallback onViewVideo;

  @override
  State<_UploadingGlowDialog> createState() => _UploadingGlowDialogState();
}

class _UploadingGlowDialogState extends State<_UploadingGlowDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = Curves.easeInOut.transform(_controller.value);
          final colorScheme = Theme.of(context).colorScheme;

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(
                    alpha: 0.22 + pulse * 0.16,
                  ),
                  blurRadius: 40 + pulse * 18,
                  spreadRadius: 3 + pulse * 4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: ValueListenableBuilder<_UploadDialogData>(
              valueListenable: widget.data,
              builder: (context, data, _) {
                final progress = data.progress;
                final progressLabel = progress?.label;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _UploadPulseSphere(
                      progress: pulse,
                      hasError: data.hasError,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      data.hasError ? 'Upload failed' : 'Uploading video',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: progress?.fraction),
                    const SizedBox(height: 10),
                    Text(
                      progressLabel ??
                          data.message ??
                          'Preparing your upload...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (progressLabel != null && data.message != null) ...[
                      const SizedBox(height: 6),
                      Text(data.message!, textAlign: TextAlign.center),
                    ],
                    if (data.isReady) ...[
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: widget.onViewVideo,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('View video'),
                      ),
                    ] else if (data.hasError) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Close'),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Keep this screen open while we prepare playback.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _UploadPulseSphere extends StatelessWidget {
  const _UploadPulseSphere({required this.progress, required this.hasError});

  final double progress;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = hasError ? colorScheme.error : colorScheme.primary;
    final size = 76 + progress * 8;

    return SizedBox(
      width: 118,
      height: 118,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 108 + progress * 8,
            height: 108 + progress * 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: baseColor.withValues(alpha: 0.08),
              boxShadow: [
                BoxShadow(
                  color: baseColor.withValues(alpha: 0.28 + progress * 0.18),
                  blurRadius: 28 + progress * 18,
                  spreadRadius: 2 + progress * 5,
                ),
              ],
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.35, -0.45),
                radius: 0.95,
                colors: [
                  Colors.white.withValues(alpha: 0.95),
                  baseColor.withValues(alpha: 0.72),
                  baseColor.withValues(alpha: 0.95),
                ],
              ),
            ),
            child: Icon(
              hasError ? Icons.error_outline : Icons.cloud_upload,
              color: hasError ? colorScheme.onError : colorScheme.onPrimary,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }
}
