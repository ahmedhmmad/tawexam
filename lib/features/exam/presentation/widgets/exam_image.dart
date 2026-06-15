import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_config.dart';

/// Renders a question or choice image from a stored (possibly relative) URL.
/// Renders nothing when [imageUrl] is null/empty; shows a quiet broken-image
/// placeholder when the file can't be loaded so the exam stays usable.
///
/// When [enlargeable] is true the image opens a full-screen pinch-zoom viewer
/// on tap. The zoom affordance is shown as a caption *below* the image (when
/// [showZoomHint] is true) so it never overlaps the image content.
class ExamImage extends StatelessWidget {
  const ExamImage({
    super.key,
    required this.imageUrl,
    this.maxHeight = 240,
    this.borderRadius = 14,
    this.enlargeable = false,
    this.showZoomHint = false,
  });

  final String? imageUrl;
  final double maxHeight;
  final double borderRadius;
  final bool enlargeable;
  final bool showZoomHint;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolveMediaUrl(imageUrl);
    if (resolved == null) return const SizedBox.shrink();

    final framed = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: CachedNetworkImage(
          imageUrl: resolved,
          fit: BoxFit.contain,
          width: double.infinity,
          placeholder: (context, url) => Container(
            height: 120,
            alignment: Alignment.center,
            color: Colors.grey.shade50,
            child: const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 80,
            alignment: Alignment.center,
            color: Colors.grey.shade50,
            child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400, size: 32),
          ),
        ),
      ),
    );

    if (!enlargeable) return framed;

    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: () => _openFullScreen(context, resolved),
        child: framed,
      ),
    );

    if (!showZoomHint) return tappable;

    // Caption below the image — keeps the zoom hint off the image content.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tappable,
        const SizedBox(height: 6),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.zoom_out_map, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                'اضغط على الصورة للتكبير',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openFullScreen(BuildContext context, String resolvedUrl) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => _FullScreenImage(imageUrl: resolvedUrl),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }
}

/// Full-screen, pinch-zoomable image viewer. Uses the same cache key as the
/// inline image, so it shows instantly and works offline.
class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 26),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
