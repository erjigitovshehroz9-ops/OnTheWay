import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/startup_reachability.dart';
import '../../../core/providers/core_providers.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reach = ref.watch(startupReachabilityProvider);
    final auth = ref.watch(authSessionProvider);

    final String? blockingMessage;
    final VoidCallback? onRetry;

    if (reach.hasError) {
      final e = reach.error!;
      blockingMessage =
          e is StartupReachabilityFailure ? e.message : e.toString();
      onRetry = () => ref.invalidate(startupReachabilityProvider);
    } else if (reach.hasValue && auth.hasError) {
      final e = auth.error!;
      blockingMessage = e is TimeoutException
          ? "Kutish vaqti tugadi. Qayta urinib ko'ring."
          : "Ilovani yuklashda muammo yuz berdi. Qayta urinib ko'ring.\n($e)";
      onRetry = () {
        ref.invalidate(authSessionProvider);
        ref.invalidate(appDatabaseProvider);
        if (kIsWeb) {
          ref.invalidate(userBackingStoreProvider);
          ref.invalidate(jobLocalPersistenceProvider);
        }
        ref.invalidate(sharedPreferencesProvider);
      };
    } else {
      blockingMessage = null;
      onRetry = null;
    }

    final showCenterLoader = blockingMessage == null &&
        (reach.isLoading || (reach.hasValue && auth.isLoading));

    return _PremiumSplashBody(
      showCenterLoader: showCenterLoader,
      blockingMessage: blockingMessage,
      onRetry: onRetry,
    );
  }
}

class _PremiumSplashBody extends StatefulWidget {
  const _PremiumSplashBody({
    required this.showCenterLoader,
    this.blockingMessage,
    this.onRetry,
  });

  final bool showCenterLoader;
  final String? blockingMessage;
  final VoidCallback? onRetry;

  static const String _brandTitle = 'ON THE WAY';
  static const String _brandSubtitle =
      "Yuboruvchi va kuryerlarni tez bog'laydigan aqlli platforma";
  static const String _logoAssetPath = 'assets/images/logo.png';

  @override
  State<_PremiumSplashBody> createState() => _PremiumSplashBodyState();
}

class _PremiumSplashBodyState extends State<_PremiumSplashBody>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bgFade;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textFade;
  late final Animation<double> _loaderFade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1850),
    );
    _bgFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 0.72, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.78, curve: Curves.easeInOut),
      ),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.42, 0.9, curve: Curves.easeOut),
      ),
    );
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
    );
    _loaderFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.62, 1.0, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final shortestSide = size.shortestSide;
    final logoSize = shortestSide.clamp(186.0, 250.0).toDouble();
    final titleFontSize = shortestSide < 360 ? 50.0 : 58.0;
    final subtitleFontSize = shortestSide < 360 ? 20.5 : 22.5;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _bgFade,
          child: Stack(
            children: [
              const Positioned.fill(child: _SplashBackgroundDecoration()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 3),
                      FadeTransition(
                        opacity: _logoFade,
                        child: ScaleTransition(
                          scale: _logoScale,
                          child: Center(
                            child: _SplashLogo(
                              size: logoSize,
                              assetPath: _PremiumSplashBody._logoAssetPath,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      FadeTransition(
                        opacity: _textFade,
                        child: SlideTransition(
                          position: _textSlide,
                          child: _SplashBrandContent(
                            titleFontSize: titleFontSize,
                            subtitleFontSize: subtitleFontSize,
                            title: _PremiumSplashBody._brandTitle,
                            subtitle: _PremiumSplashBody._brandSubtitle,
                          ),
                        ),
                      ),
                      const Spacer(flex: 4),
                      if (widget.showCenterLoader) ...[
                        FadeTransition(
                          opacity: _loaderFade,
                          child: const Center(child: _SplashLoaderSection()),
                        ),
                        const SizedBox(height: 26),
                      ],
                      if (widget.blockingMessage != null) ...[
                        const Spacer(flex: 1),
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 40,
                          color: scheme.error.withValues(alpha: 0.9),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.blockingMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (widget.onRetry != null) ...[
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: widget.onRetry,
                            child: const Text("Qayta urinish"),
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                      if (!widget.showCenterLoader && widget.blockingMessage == null)
                        const SizedBox(height: 26),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplashBrandContent extends StatelessWidget {
  const _SplashBrandContent({
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.title,
    required this.subtitle,
  });

  final double titleFontSize;
  final double subtitleFontSize;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final brandBlue = isLight ? const Color(0xFF003A90) : const Color(0xFF93C5FD);
    final brandBlueMuted =
        isLight ? const Color(0xFF003A90) : const Color(0xFFBFDBFE);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.35,
            fontSize: titleFontSize,
            color: brandBlue,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 348),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                height: 1.34,
                fontSize: subtitleFontSize,
                letterSpacing: 0.1,
                color: brandBlueMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({
    required this.size,
    required this.assetPath,
  });

  final double size;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cachePx = (size * dpr).round();
    return RepaintBoundary(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: Theme.of(context).colorScheme.surface,
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          cacheWidth: cachePx > 0 ? cachePx : null,
          cacheHeight: cachePx > 0 ? cachePx : null,
          gaplessPlayback: true,
        ),
      ),
    );
  }
}

class _SplashBackgroundDecoration extends StatelessWidget {
  const _SplashBackgroundDecoration();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: Theme.of(context).colorScheme.surface);
  }
}

class _SplashLoaderSection extends StatelessWidget {
  const _SplashLoaderSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.12, -0.2),
          radius: 0.95,
          colors: [Color(0xFFFFFFFF), Color(0xFFF3F4F6), Color(0xFFFAFAFA)],
          stops: [0.0, 0.74, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1C003A90),
            blurRadius: 26,
            offset: Offset(0, 13),
          ),
          BoxShadow(
            color: Color(0x1CFFFFFF),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: 42,
          height: 42,
          child: Stack(
            alignment: Alignment.center,
            children: const [
              SizedBox(
                width: 42,
                height: 42,
                child: CircularProgressIndicator(
                  strokeWidth: 3.2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF003A90)),
                  backgroundColor: Color(0x22003A90),
                ),
              ),
              SizedBox(
                width: 26,
                height: 26,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0x14003A90), Color(0x14FFFFFF)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
