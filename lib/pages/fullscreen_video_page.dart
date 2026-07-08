part of '../main.dart';

class FullscreenVideoScreen extends StatefulWidget {
  const FullscreenVideoScreen({
    super.key,
    required this.controller,
    this.onNextVideo,
  });

  final VideoPlayerController controller;
  final Future<VideoPlayerController?> Function()? onNextVideo;

  @override
  State<FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
}

class _FullscreenVideoScreenState extends State<FullscreenVideoScreen> {
  var _horizontalDrag = 0.0;
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _controller.addListener(_refreshControls);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _controller.removeListener(_refreshControls);
    super.dispose();
  }

  void _refreshControls() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          onHorizontalDragUpdate: (details) =>
              _horizontalDrag += details.delta.dx,
          onHorizontalDragEnd: (_) async {
            if (_horizontalDrag < -90) {
              final nextController = await widget.onNextVideo?.call();
              if (mounted && nextController != null) {
                _controller.removeListener(_refreshControls);
                _controller = nextController;
                _controller.addListener(_refreshControls);
                setState(() {});
              }
            }
            _horizontalDrag = 0;
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
              Positioned(
                right: 18,
                top: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    child: Text(
                      'Swipe left for next',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              VideoControls(
                controller: _controller,
                onFullscreen: () => Navigator.of(context).pop(),
                fullscreenIcon: Icons.fullscreen_exit,
                fullscreenTooltip: 'Exit fullscreen',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
