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
  Uint8List? _selectedBytes;
  UploadProgress? _progress;
  bool _showUploadForm = false;
  bool _pickingVideo = false;
  bool _uploading = false;
  bool _creatorMiniPlayer = false;
  int _uploadStep = 0;
  String? _creatorPreviewPlaybackId;
  String? _message;
  String? _fileSelectionError;
  double? _selectedAspectRatio;

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
      MaterialPageRoute<WatchExitAction>(
        builder: (_) => WatchVideoScreen(
          video: video,
          controller: controller,
          initializeFuture: initializeFuture,
        ),
      ),
    );

    if (!mounted) return;
    if (action == WatchExitAction.minimize) {
      setState(() => _creatorMiniPlayer = true);
    } else {
      await _closeCreatorPlayer();
    }
  }

  Future<void> _expandCreatorMiniPlayer() async {
    final controller = _creatorPlaybackController;
    final video = _selectedUploadedVideo;
    if (controller == null || video == null) return;

    final navigator = Navigator.of(context);
    setState(() => _creatorMiniPlayer = false);
    final action = await navigator.push<WatchExitAction>(
      MaterialPageRoute<WatchExitAction>(
        builder: (_) => WatchVideoScreen(
          video: video,
          controller: controller,
          initializeFuture: Future<void>.value(),
        ),
      ),
    );

    if (!mounted) return;
    if (action == WatchExitAction.minimize) {
      setState(() => _creatorMiniPlayer = true);
    } else {
      await _closeCreatorPlayer();
    }
  }

  Future<void> _closeCreatorPlayer() async {
    final oldController = _creatorPlaybackController;
    setState(() {
      _creatorPlaybackController = null;
      _selectedUploadedVideo = null;
      _creatorMiniPlayer = false;
    });
    await oldController?.dispose();
  }

  void _showVideoMenu(UploadedVideo video) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => const SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.bookmark_add_outlined),
              title: Text('Save to watchlist'),
            ),
            ListTile(
              leading: Icon(Icons.favorite_border),
              title: Text('Favorite video'),
            ),
            ListTile(leading: Icon(Icons.person), title: Text('View creator')),
            ListTile(
              leading: Icon(Icons.visibility_off_outlined),
              title: Text('Hide'),
            ),
          ],
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
      message: 'Creating Mux direct upload...',
    );

    try {
      final upload = await _muxClient.createDirectUpload(title: videoTitle);
      _setUploadStatus(message: 'Uploading video to Mux...');

      await _muxClient.uploadVideo(
        upload.url,
        bytes,
        onProgress: (progress) => _setUploadStatus(progress: progress),
      );

      _setUploadStatus(message: 'Upload complete. Waiting for playback ID...');
      final playbackId = await _muxClient.waitForPlaybackId(upload.id);
      uploadedVideos.insert(
        0,
        UploadedVideo(
          creator: widget.username,
          title: videoTitle,
          description: '',
          filename: file.name,
          playbackId: playbackId,
          uploadedAt: uploadedAt,
        ),
      );

      _setUploadStatus(message: 'Ready to watch. Playback ID: $playbackId');
      await _resetUploadForm(closeForm: true);
    } catch (error) {
      _setUploadStatus(message: 'Upload failed: $error', hasError: true);
    } finally {
      setState(() => _uploading = false);
    }
  }

  void _setUploadStatus({
    UploadProgress? progress,
    String? message,
    bool hasError = false,
  }) {
    final nextProgress = progress ?? _progress;
    final nextMessage = message ?? _message;
    setState(() {
      _progress = nextProgress;
      _message = nextMessage;
    });
    _uploadDialogData.value = _UploadDialogData(
      progress: nextProgress,
      message: nextMessage,
      hasError: hasError,
    );
  }

  Future<void> _uploadWithGlow() async {
    if (!mounted) return;
    _uploadDialogData.value = const _UploadDialogData(
      message: 'Creating Mux direct upload...',
    );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UploadingGlowDialog(data: _uploadDialogData),
    );
    await _uploadSelectedVideo();
    if (mounted && _message?.startsWith('Upload failed:') != true) {
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
        drawer: const SettingsDrawer(),
        appBar: AppBar(
          title: const Text('Creator Studio'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                avatar: const Icon(Icons.person, size: 18),
                label: Text(widget.username),
                onPressed: _logout,
              ),
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
                        : _buildMyVideos(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyVideos() {
    final myVideos = uploadedVideos
        .where((video) => video.creator == widget.username)
        .toList();
    final playbackController = _creatorPlaybackController;
    final selectedVideo = _selectedUploadedVideo;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${widget.username} Studio',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          myVideos.isEmpty
                              ? 'Draft your first subscriber-ready upload.'
                              : '${myVideos.length} published ${myVideos.length == 1 ? 'video' : 'videos'} in this session',
                        ),
                      ],
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
                            onMoreTap: () => _showVideoMenu(video),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        if (_creatorMiniPlayer &&
            selectedVideo != null &&
            playbackController != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: MiniVideoPlayer(
              video: selectedVideo,
              controller: playbackController,
              onExpand: _expandCreatorMiniPlayer,
              onClose: _closeCreatorPlayer,
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
    final uploadFailed = _message?.startsWith('Upload failed:') ?? false;
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
            label: Text(uploadFailed ? 'Retry upload' : 'Upload video'),
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
  const _UploadDialogData({this.progress, this.message, this.hasError = false});

  final UploadProgress? progress;
  final String? message;
  final bool hasError;
}

class _UploadingGlowDialog extends StatefulWidget {
  const _UploadingGlowDialog({required this.data});

  final ValueListenable<_UploadDialogData> data;

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
          return Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: SweepGradient(
                transform: GradientRotation(_controller.value * 6.28318),
                colors: const [
                  Color(0xFF6D5DF6),
                  Color(0xFF00D4FF),
                  Color(0xFFFF7AD9),
                  Color(0xFF6D5DF6),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.5),
                  blurRadius: 28,
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(27),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: ValueListenableBuilder<_UploadDialogData>(
                valueListenable: widget.data,
                builder: (context, data, _) {
                  final progress = data.progress;
                  final progressLabel = progress?.label;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        data.hasError
                            ? Icons.error_outline
                            : Icons.cloud_upload,
                        size: 54,
                        color: data.hasError
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        data.hasError ? 'Upload failed' : 'Uploading to Mux',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: progress?.fraction),
                      const SizedBox(height: 10),
                      Text(
                        progressLabel ?? data.message ?? 'Preparing upload...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (progressLabel != null && data.message != null) ...[
                        const SizedBox(height: 6),
                        Text(data.message!, textAlign: TextAlign.center),
                      ],
                      if (data.hasError) ...[
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
            ),
          );
        },
      ),
    );
  }
}
