import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/pexels_photo_service.dart';
import '../../../domain/entities/place_entity.dart';
import '../cubit/place_detail_cubit.dart';
import '../cubit/place_detail_state.dart';

class PlaceDetailScreen extends StatelessWidget {
  final PlaceEntity place;

  const PlaceDetailScreen({super.key, required this.place});

  static const _categoryIcons = {
    'Müze': Icons.museum_rounded,
    'Doğa': Icons.park_rounded,
    'Restoran': Icons.restaurant_rounded,
    'Macera': Icons.hiking_rounded,
    'Tarih': Icons.account_balance_rounded,
    'Alışveriş': Icons.shopping_bag_rounded,
  };

  IconData get _icon {
    for (final entry in _categoryIcons.entries) {
      if (place.category.contains(entry.key)) return entry.value;
    }
    return Icons.place_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlaceDetailCubit(),
      child: PlaceDetailView(place: place, icon: _icon),
    );
  }
}

class PlaceDetailView extends StatefulWidget {
  final PlaceEntity place;
  final IconData icon;

  const PlaceDetailView({
    super.key,
    required this.place,
    required this.icon,
  });

  @override
  State<PlaceDetailView> createState() => _PlaceDetailViewState();
}

class _PlaceDetailViewState extends State<PlaceDetailView> {
  late Future<String?> _photoFuture;

  @override
  void initState() {
    super.initState();
    _photoFuture = PexelsCityPhotoService.getPlacePhotoUrl(
      widget.place.name,
      photoQuery: widget.place.photoQuery,
      category: widget.place.category,
      city: widget.place.city,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          _buildHeader(context),
          // İçerik
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TTS Oynatıcı
                  _buildTtsPlayer(context),
                  const SizedBox(height: 20),
                  // Bilgi bandı
                  _buildInfoRow(context),
                  const SizedBox(height: 24),
                  // AI Açıklama
                  _buildDescription(context),
                  const SizedBox(height: 24),
                  // Haritada Göster
                  _buildMapButton(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Header ─────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.45),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: Colors.white,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          widget.place.name,
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        background: FutureBuilder<String?>(
          future: _photoFuture,
          builder: (context, snapshot) {
            final url = snapshot.data;
            return Stack(
              fit: StackFit.expand,
              children: [
                if (url != null && url.isNotEmpty)
                  CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _buildFallbackHeader(),
                    errorWidget: (_, __, ___) => _buildFallbackHeader(),
                  )
                else
                  _buildFallbackHeader(),
                // Alt gradient
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.4, 1.0],
                        colors: [
                          Colors.black.withOpacity(0.15),
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFallbackHeader() {
    return Container(
      color: AppColors.secondaryBackground,
      child: Center(
        child: Icon(
          widget.icon,
          size: 72,
          color: AppColors.primary.withOpacity(0.2),
        ),
      ),
    );
  }

  // ── TTS Oynatıcı — iOS Now Playing Tarzı ───────────────────────
  Widget _buildTtsPlayer(BuildContext context) {
    return BlocBuilder<PlaceDetailCubit, PlaceDetailState>(
      builder: (context, state) {
        final cubit = context.read<PlaceDetailCubit>();
        final isPlaying = state.isPlaying;
        final isLoading = state.ttsStatus == TtsStatus.loading;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // İkon
                  _buildSoundIndicator(isPlaying),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sesli Rehber',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.label,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          isPlaying
                              ? 'Anlatım devam ediyor...'
                              : state.isPaused
                                  ? 'Duraklatıldı'
                                  : 'Bu mekan hakkında sesli bilgi al',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Play/Pause
                  GestureDetector(
                    onTap: () =>
                        cubit.togglePlayPause(widget.place.description),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                  if (isPlaying || state.isPaused) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: cubit.stop,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.tertiaryBackground,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.stop_rounded,
                          color: AppColors.secondaryLabel,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (state.ttsProgress > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: state.ttsProgress,
                    backgroundColor: AppColors.separator,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary),
                    minHeight: 3,
                  ),
                ),
              ],
            ],
          ),
        ).animate().fadeIn(delay: 200.ms);
      },
    );
  }

  Widget _buildSoundIndicator(bool isActive) {
    if (!isActive) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.headphones_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      );
    }

    return SizedBox(
      width: 40,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(4, (i) {
          return Container(
            width: 3,
            height: (i % 2 == 0 ? 18.0 : 26.0),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleY(
                begin: 0.3,
                end: 1.0,
                delay: Duration(milliseconds: i * 150),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOut,
              );
        }),
      ),
    );
  }

  // ── Bilgi Bandı ─────────────────────────────────────────────────
  Widget _buildInfoRow(BuildContext context) {
    return Row(
      children: [
        _InfoTag(
          icon: Icons.category_rounded,
          label: widget.place.category,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        _InfoTag(
          icon: Icons.schedule_rounded,
          label: widget.place.suggestedDuration,
          color: AppColors.systemTeal,
        ),
        if (widget.place.address != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _InfoTag(
              icon: Icons.location_on_rounded,
              label: widget.place.address!,
              color: AppColors.systemOrange,
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  // ── Açıklama ────────────────────────────────────────────────────
  Widget _buildDescription(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Hakkında',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.label,
                letterSpacing: 0.35,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'AI',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          widget.place.description,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: AppColors.secondaryLabel,
            height: 1.65,
            letterSpacing: -0.3,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  // ── Haritada Göster (Yol Tarifi) Butonu ─────────────────────────
  Widget _buildMapButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: _launchMapApp,
        icon: const Icon(Icons.map_rounded, size: 20),
        label: Text(
          'Yol Tarifi Al',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.separator, width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Future<void> _launchMapApp() async {
    final name = widget.place.name.trim();
    final lat = widget.place.lat;
    final lng = widget.place.lng;

    // "Sabah: ", "Öğleden Sonra: " gibi zaman/sıra etiketlerini temizle
    String cleanName = name;
    if (name.contains(':')) {
      final parts = name.split(':');
      final prefix = parts[0].toLowerCase().trim();
      if (prefix == 'sabah' ||
          prefix == 'öğle' ||
          prefix == 'öğleden sonra' ||
          prefix == 'akşam' ||
          prefix == 'gece' ||
          prefix.startsWith('gün') ||
          prefix.contains('durak') ||
          prefix.contains('mekan') ||
          RegExp(r'^\d+(\.\s*gün)?$').hasMatch(prefix)) {
        cleanName = parts.sublist(1).join(':').trim();
      }
    }

    // Arama yapılacak adres / mekan bilgisi
    final searchAddress = cleanName + (widget.place.city != null ? ", ${widget.place.city}" : "");

    Uri uri;
    if (Platform.isIOS) {
      // iOS: Apple Maps Yol Tarifi Intent'i (daddr = destination address)
      if (lat != null && lng != null) {
        uri = Uri.parse('maps://?daddr=$lat,$lng&q=${Uri.encodeComponent(cleanName)}');
      } else {
        uri = Uri.parse('maps://?daddr=${Uri.encodeComponent(searchAddress)}');
      }
    } else {
      // Android: Google Maps Yol Tarifi URL'si (destination = hedef mekan)
      // Koordinat yerine isimle aramak, arama kutusunda koordinat sayıları yerine mekan adının görünmesini sağlar
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(searchAddress)}');
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Web tabanlı Google Maps yol tarifi
        final webUri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=${Uri.encodeComponent(searchAddress)}'
        );
        if (await canLaunchUrl(webUri)) {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Yol tarifi uygulaması başlatılamadı';
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yol tarifi alınamadı: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// ── Bilgi Etiketi ─────────────────────────────────────────────────
class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
