part of '../main.dart';

class UploadStatusCard extends StatefulWidget {
  const UploadStatusCard({
    super.key,
    required this.progress,
    required this.message,
    required this.uploading,
  });

  final UploadProgress? progress;
  final String? message;
  final bool uploading;

  @override
  State<UploadStatusCard> createState() => _UploadStatusCardState();
}

class _UploadStatusCardState extends State<UploadStatusCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulse = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutCubic,
    );
    if (widget.uploading) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant UploadStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.uploading && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.uploading && _pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = widget.progress;
    final fraction = progress?.fraction;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1.08).animate(_pulse),
                  child: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary,
                    ),
                    child: Icon(
                      widget.uploading ? Icons.cloud_upload : Icons.check,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.uploading
                            ? 'Upload in progress'
                            : 'Upload status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.message ??
                            progress?.label ??
                            'Preparing upload...',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 12,
                value: fraction,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(progress?.label ?? 'Preparing upload...'),
                if (widget.uploading)
                  Text(
                    'Keep app open',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
