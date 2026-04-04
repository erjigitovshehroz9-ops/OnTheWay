import 'package:flutter/material.dart';

import 'job_image_local_stub.dart'
    if (dart.library.io) 'job_image_local_io.dart' as job_image_local;

/// Mahsulot rasmi: mahalliy fayl yo‘li yoki `http(s)` URL.
/// Bo‘sh, noto‘g‘ri yoki yo‘q fayl uchun placeholder.
class JobImageThumbnail extends StatelessWidget {
  const JobImageThumbnail({
    super.key,
    required this.imageRef,
    this.size = 64,
    this.borderRadius = 12,
  });

  final String imageRef;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: size,
        height: size,
        child: _JobImageCore(
          imageRef: imageRef,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Detail sahifa: kattaroq preview; [onOpenLightbox] berilsa, bosilganda to‘liq ekran.
class JobImageDetailPreview extends StatelessWidget {
  const JobImageDetailPreview({
    super.key,
    required this.imageRef,
    this.maxHeight = 240,
    this.borderRadius = 16,
  });

  final String imageRef;
  final double maxHeight;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final ref = imageRef.trim();
    if (ref.isEmpty) {
      return _PlaceholderCard(
        height: maxHeight,
        borderRadius: borderRadius,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showJobImageLightbox(context, imageRef),
        borderRadius: BorderRadius.circular(borderRadius),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: SizedBox(
              width: double.infinity,
              height: maxHeight,
              child: _JobImageCore(
                imageRef: imageRef,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JobImageCore extends StatelessWidget {
  const _JobImageCore({
    required this.imageRef,
    required this.fit,
  });

  final String imageRef;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final ref = imageRef.trim();
    if (ref.isEmpty) {
      return const _ImagePlaceholder();
    }

    if (_isRemote(ref)) {
      return Image.network(
        ref,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
      );
    }

    return job_image_local.buildLocalJobImage(
      ref,
      fit,
      error: const _ImagePlaceholder(),
    );
  }
}

bool _isRemote(String ref) {
  final t = ref.trim().toLowerCase();
  return t.startsWith('http://') || t.startsWith('https://');
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ColoredBox(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.9),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          size: 28,
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({
    required this.height,
    required this.borderRadius,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: const _ImagePlaceholder(),
      ),
    );
  }
}

void showJobImageLightbox(BuildContext context, String imageRef) {
  final ref = imageRef.trim();
  if (ref.isEmpty) return;

  showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: _isRemote(ref)
                  ? Image.network(
                      ref,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                    )
                  : job_image_local.buildLocalJobImage(
                      ref,
                      BoxFit.contain,
                      error: const _ImagePlaceholder(),
                    ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      );
    },
  );
}
