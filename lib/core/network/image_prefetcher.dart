import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../constants/api_config.dart';

/// Pre-downloads question/choice images into the shared disk cache used by
/// CachedNetworkImage, so they remain renderable while the device is offline.
class ImagePrefetcher {
  const ImagePrefetcher();

  /// Fire-and-forget: failures are ignored so prefetching never blocks or
  /// breaks the exam flow (the UI falls back to a placeholder per image).
  Future<void> prefetch(Iterable<String?> imageUrls) async {
    final resolved = imageUrls
        .map(ApiConfig.resolveMediaUrl)
        .whereType<String>()
        .toSet();
    if (resolved.isEmpty) return;

    final cacheManager = DefaultCacheManager();
    await Future.wait(
      resolved.map((url) async {
        try {
          await cacheManager.downloadFile(url);
        } catch (error) {
          debugPrint('Image prefetch failed for $url: $error');
        }
      }),
    );
  }
}
