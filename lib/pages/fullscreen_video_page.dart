part of '../main.dart';

class FullscreenVideoScreen extends StatefulWidget {
  const FullscreenVideoScreen({super.key, required this.controller});

  final VideoPlayerController controller;

  @override
  State<FullscreenVideoScreen> createState() => _FullscreenVideoScreenState();
}

class _FullscreenVideoScreenState extends State<FullscreenVideoScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_refreshControls);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_refreshControls);
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: widget.controller.value.aspectRatio,
                child: VideoPlayer(widget.controller),
              ),
            ),
            VideoControls(
              controller: widget.controller,
              onFullscreen: () => Navigator.of(context).pop(),
              fullscreenIcon: Icons.fullscreen_exit,
              fullscreenTooltip: 'Exit fullscreen',
            ),
          ],
        ),
      ),
    );
  }
}
