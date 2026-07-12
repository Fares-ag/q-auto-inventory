import 'package:flutter/material.dart';

/// Bumps Flutter's global decoded-image cache so list thumbnails stay in
/// memory after they scroll off-screen and don't have to be re-decoded
/// (re-painting a placeholder) when scrolled back into view.
///
/// Defaults are 1000 images / 100 MB which is too small for an inventory app
/// with hundreds of asset thumbnails.  We bump to:
///   - 5000 images
///   - 500 MB
///
/// Call once from `main()` after `WidgetsFlutterBinding.ensureInitialized()`.
void configureImageCache() {
  PaintingBinding.instance.imageCache.maximumSize = 5000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 500 * 1024 * 1024;
}
