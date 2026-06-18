import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../services/pexels_photo_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WikiCityImage — Pexels API'den gelen URL ile şehir fotoğrafını render eder.
// FutureBuilder + CachedNetworkImage kombinasyonu.
// ─────────────────────────────────────────────────────────────────────────────

class WikiCityImage extends StatefulWidget {
  final String city;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const WikiCityImage({
    super.key,
    required this.city,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<WikiCityImage> createState() => _WikiCityImageState();
}

class _WikiCityImageState extends State<WikiCityImage> {
  late Future<String?> _photoFuture;

  @override
  void initState() {
    super.initState();
    // Future sadece bir kez oluşturulur — her rebuild'de yeniden çağrılmaz
    _photoFuture = PexelsCityPhotoService.getPhotoUrl(widget.city);
  }

  @override
  void didUpdateWidget(WikiCityImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) {
      _photoFuture = PexelsCityPhotoService.getPhotoUrl(widget.city);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _photoFuture,
      builder: (context, snapshot) {
        // ── Yükleniyor: shimmer göster ──
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer(context);
        }

        final url = snapshot.data;

        // ── URL başarıyla geldi ──
        if (url != null && url.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: url,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            placeholder: (_, __) => _buildShimmer(context),
            errorWidget: (_, __, ___) => _buildFallback(),
          );
        }

        // ── URL gelmedi: gradient fallback ──
        return _buildFallback();
      },
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return widget.placeholder ??
        Shimmer.fromColors(
          baseColor: AppColors.surfaceElevated,
          highlightColor: AppColors.surfaceHighlight,
          child: Container(
            width: widget.width,
            height: widget.height,
            color: AppColors.surfaceElevated,
          ),
        );
  }

  // URL gelmediğinde şehir baş harfiyle güzel bir gradient gösterir
  Widget _buildFallback() {
    if (widget.errorWidget != null) return widget.errorWidget!;
    final city = widget.city;
    final hue = (city.codeUnitAt(0) * 37 + city.length * 17) % 360;
    final color1 = HSLColor.fromAHSL(1, hue.toDouble(), 0.55, 0.25).toColor();
    final color2 = HSLColor.fromAHSL(1, (hue + 40) % 360, 0.60, 0.35).toColor();
    final initial = city.isNotEmpty ? city[0].toUpperCase() : '?';

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// CityPhotoBanner — Üst kısım hero banner (overlay + alt bilgi)
// ─────────────────────────────────────────────────────────────────────────────

class CityPhotoBanner extends StatelessWidget {
  final String city;
  final double height;
  final BorderRadius? borderRadius;
  final List<Color>? gradientColors;
  final Alignment gradientBegin;
  final Alignment gradientEnd;
  final Widget? child; // Stack üzerine eklenen içerik

  const CityPhotoBanner({
    super.key,
    required this.city,
    required this.height,
    this.borderRadius,
    this.gradientColors,
    this.gradientBegin = Alignment.topCenter,
    this.gradientEnd = Alignment.bottomCenter,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        [
          Colors.transparent,
          Colors.black.withOpacity(0.4),
          AppColors.background.withOpacity(0.9),
          AppColors.background,
        ];

    final clipRR = borderRadius ??
        const BorderRadius.vertical(bottom: Radius.circular(28));

    return ClipRRect(
      borderRadius: clipRR,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WikiCityImage(city: city, fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: gradientBegin,
                  end: gradientEnd,
                  colors: colors,
                ),
              ),
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CityPhotoCard — Dikdörtgen kart (trip listesi vs.)
// ─────────────────────────────────────────────────────────────────────────────

class CityPhotoCard extends StatelessWidget {
  final String city;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final Widget? overlay;

  const CityPhotoCard({
    super.key,
    required this.city,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WikiCityImage(city: city, fit: BoxFit.cover),
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CityPhotoAvatar — Küçük daire/kare fotoğraf (list tile, waypoint node)
// ─────────────────────────────────────────────────────────────────────────────

class CityPhotoAvatar extends StatelessWidget {
  final String city;
  final double size;
  final bool isCircle;
  final double borderRadius;

  const CityPhotoAvatar({
    super.key,
    required this.city,
    this.size = 52,
    this.isCircle = false,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final shape = isCircle
        ? const BoxDecoration(shape: BoxShape.circle)
        : BoxDecoration(borderRadius: BorderRadius.circular(borderRadius));

    return Container(
      width: size,
      height: size,
      decoration: shape,
      clipBehavior: Clip.antiAlias,
      child: WikiCityImage(
        city: city,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorWidget: Container(
          color: AppColors.surfaceElevated,
          child: const Icon(Icons.place_rounded,
              color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CityPhotoMiniCard — Popüler destinasyon yatay kartı
// ─────────────────────────────────────────────────────────────────────────────

class CityPhotoMiniCard extends StatelessWidget {
  final String city;
  final bool isSelected;
  final VoidCallback? onTap;

  const CityPhotoMiniCard({
    super.key,
    required this.city,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 100,
        height: 128,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 12,
                  )
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              WikiCityImage(city: city, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDD000000)],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  city,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 13,
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
