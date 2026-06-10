import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_config.dart';

/// Renders a question or choice image from a stored (possibly relative) URL.
/// Renders nothing when [imageUrl] is null/empty; shows a quiet broken-image
/// placeholder when the file can't be loaded so the exam stays usable.
class ExamImage extends StatelessWidget {
  const ExamImage({
    super.key,
    required this.imageUrl,
    this.maxHeight = 240,
    this.borderRadius = 8,
  });

  final String? imageUrl;
  final double maxHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolveMediaUrl(imageUrl);
    if (resolved == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: CachedNetworkImage(
          imageUrl: resolved,
          fit: BoxFit.contain,
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
  }
}
