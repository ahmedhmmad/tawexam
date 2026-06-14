import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_config.dart';

/// Renders a question or choice image from a stored (possibly relative) URL.
/// Renders nothing when [imageUrl] is null/empty; shows a quiet broken-image
/// placeholder when the file can't be loaded so the exam stays usable.
///
/// When [enlargeable] is true, tapping opens a full-screen pinch-to-zoom
/// viewer — used for the main question image so small diagrams/text stay
/// readable without bloating the question layout.
class ExamImage extends StatelessWidget {
  const ExamImage({
    super.key,
    required this.imageUrl,
    this.maxHeight = 240,
    this.borderRadius = 12,
    this.enlargeable = false,
  });

  final String? imageUrl;
  final double maxHeight;
  final double borderRadius;
  final bool enlargeable;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolveMediaUrl(imageUrl);
    if (resolved == null) return const SizedBox.shrink();

    final image = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: CachedNetworkImage(
          imageUrl: resolved,
          fit: BoxFit.contain,
          width: double.infinity,
          placeholder: (context, url) => Container(
            height: 120,
            alignment: Alignment.center,
            color: Colors.grey.shade100,
            child: const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            height: 80,
            alignment: Alignment.center,
            color: Colors.grey.shade100,
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.grey.shade400,
              size: 32,
            ),
          ),
        ),
      ),
    );

    if (!enlargeable) return image;

    return Stack(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: () => _openFullScreen(context, resolved),
            child: image,
          ),
        ),
        // Subtle "tap to enlarge" affordance.
        Positioned(
          top: 8,
          left: 8,
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.zoom_out_map, color: Colors.white, size: 18),
            ),
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
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}
