import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_theme_tokens.dart';
import 'premium_map_style.dart';

/// OpenStreetMap tile usage policy — keep visible on map UIs.
class PremiumMapAttribution extends StatelessWidget {
  const PremiumMapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '© OpenStreetMap contributors',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            height: 1,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Circular blue marker with white letter (pickup **A** / dropoff **B**).
class PremiumRouteLetterMarker extends StatelessWidget {
  const PremiumRouteLetterMarker({
    super.key,
    required this.label,
    this.diameter = 40,
    this.fontSize = 17,
  });

  final String label;
  final double diameter;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.brandPrimary,
        border: Border.all(
          color: t.surface,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: t.brandPrimary.withValues(alpha: 0.22),
            blurRadius: 0,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: t.textOnPrimary,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

/// Courier / delivery vehicle on the route — subtle “live” motion.
class PremiumCourierMarker extends StatefulWidget {
  const PremiumCourierMarker({
    super.key,
    this.size = 52,
    this.bearingDeg = 0,
    this.icon = Icons.two_wheeler_rounded,
  });

  final double size;
  /// Optional map rotation / movement direction in degrees (not wired by default).
  final double bearingDeg;
  /// Buyurtma transport turi yoki kuryer vositasi (standart — mototsikl).
  final IconData icon;

  @override
  State<PremiumCourierMarker> createState() => _PremiumCourierMarkerState();
}

class _PremiumCourierMarkerState extends State<PremiumCourierMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _bob;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _bob = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bob,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bob.value),
          child: child,
        );
      },
      child: Transform.rotate(
        angle: widget.bearingDeg * 3.141592653589793 / 180,
        child: _CourierPinBody(size: widget.size, icon: widget.icon),
      ),
    );
  }
}

class _CourierPinBody extends StatelessWidget {
  const _CourierPinBody({required this.size, required this.icon});

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            t.card,
            t.surfaceAlt,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: t.brandPrimary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: t.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: t.brandPrimary.withValues(alpha: 0.45),
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: size * 0.52,
        color: t.brandPrimary,
      ),
    );
  }
}

/// Static courier marker (no animation) — better for dense maps (e.g. admin).
class PremiumCourierMarkerStatic extends StatelessWidget {
  const PremiumCourierMarkerStatic({
    super.key,
    this.size = 48,
    this.icon = Icons.two_wheeler_rounded,
  });

  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _CourierPinBody(size: size, icon: icon);
  }
}

/// Top-left floating back control (light surface, soft shadow).
class PremiumMapFloatingBackButton extends StatelessWidget {
  const PremiumMapFloatingBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: t.card,
      elevation: 6,
      shadowColor: t.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: t.borderSoft),
      ),
      child: InkWell(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: t.iconPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom-right my-location / recenter (white, soft shadow).
class PremiumMapLocationButton extends StatelessWidget {
  const PremiumMapLocationButton({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.icon = Icons.my_location_rounded,
  });

  final VoidCallback onPressed;
  final String? tooltip;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final child = Material(
      color: t.card,
      elevation: 6,
      shadowColor: t.shadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: t.borderSoft),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            icon,
            size: 24,
            color: t.brandPrimary,
          ),
        ),
      ),
    );
    if (tooltip == null) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

/// Fit camera to [points] with padding for floating UI.
void premiumFitBounds(
  MapController controller, {
  required List<LatLng> points,
  EdgeInsets padding = const EdgeInsets.fromLTRB(56, 88, 56, 120),
  double maxZoom = 16,
}) {
  if (points.isEmpty) return;
  if (points.length == 1) {
    controller.move(points.first, 15);
    return;
  }
  final bounds = LatLngBounds.fromPoints(points);
  controller.fitCamera(
    CameraFit.bounds(
      bounds: bounds,
      padding: padding,
      maxZoom: maxZoom,
    ),
  );
}
