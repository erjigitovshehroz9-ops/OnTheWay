import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

/// PNG o‘rniga: reference uslubidagi delivery illustration.
class SenderCreateJobHeroCard extends StatelessWidget {
  const SenderCreateJobHeroCard({super.key, required this.onTap});

  final VoidCallback onTap;

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: onTap,
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E3A8A),
                Color(0xFF2563EB),
                Color(0xFF3B82F6),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.32),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  right: -32,
                  top: -24,
                  child: IgnorePointer(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -18,
                  bottom: -20,
                  child: IgnorePointer(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Buyurtma yaratish',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                height: 1.06,
                                letterSpacing: -0.35,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Yangi buyurtmani tezda yarating',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const _HeroRouteIllustration(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pin → S-marshrut → quti; + alohida.
class _HeroRouteIllustration extends StatelessWidget {
  const _HeroRouteIllustration();

  @override
  Widget build(BuildContext context) {
    const w = 114.0;
    const h = 100.0;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ReferenceRouteDashedPainter(
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
          Positioned(
            left: 8,
            top: 0,
            child: const _GlassPackageBadge(),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: const _PremiumLightGreenFabWithHalo(),
          ),
          Positioned(
            left: 0,
            bottom: 0,
            child: const _OutlineLocationPin(),
          ),
        ],
      ),
    );
  }
}

class _GlassPackageBadge extends StatelessWidget {
  const _GlassPackageBadge();

  static const double _side = 40;
  static const double _r = 11;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(_r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: _side,
          height: _side,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_r),
            color: Colors.white.withValues(alpha: 0.22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.48),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.inventory_2_outlined,
            size: 19,
            color: Colors.white.withValues(alpha: 0.96),
          ),
        ),
      ),
    );
  }
}

class _PremiumLightGreenFabWithHalo extends StatelessWidget {
  const _PremiumLightGreenFabWithHalo();

  static const _mintMid = Color(0xFF34D399);
  static const _mintLight = Color(0xFF6EE7B7);
  static const _mintHighlight = Color(0xFF86EFAC);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 0.8,
              ),
            ),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2DD4BF),
                  _mintMid,
                  _mintLight,
                  _mintHighlight,
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.45),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineLocationPin extends StatelessWidget {
  const _OutlineLocationPin();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.location_on_outlined,
      size: 19,
      color: Colors.white.withValues(alpha: 0.92),
      shadows: [
        Shadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}

class _ReferenceRouteDashedPainter extends CustomPainter {
  _ReferenceRouteDashedPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(w * 0.05, h * 0.91)
      ..cubicTo(
        w * 0.18,
        h * 0.80,
        w * 0.34,
        h * 0.72,
        w * 0.52,
        h * 0.62,
      )
      ..cubicTo(
        w * 0.70,
        h * 0.52,
        w * 0.62,
        h * 0.38,
        w * 0.44,
        h * 0.32,
      )
      ..cubicTo(
        w * 0.32,
        h * 0.28,
        w * 0.36,
        h * 0.34,
        w * 0.42,
        h * 0.36,
      );

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.75
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        const dashLen = 5.2;
        const gapLen = 4.0;
        final end = (distance + dashLen).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLen + gapLen;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ReferenceRouteDashedPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
