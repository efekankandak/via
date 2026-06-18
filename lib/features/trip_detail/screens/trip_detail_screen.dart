import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/di/injection.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/city_photo_widget.dart';
import '../../../core/services/weather_service.dart';
import '../../../core/services/pexels_photo_service.dart';
import '../../../domain/entities/trip_entity.dart';
import '../../../domain/entities/place_entity.dart';
import '../cubit/trip_detail_cubit.dart';
import '../cubit/trip_detail_state.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  int _selectedDayIndex = 0;
  int _selectedSegment = 0; // 0: Liste, 1: Harita
  PlaceEntity? _selectedPlaceOnMap;
  Map<DateTime, WeatherInfo> _weatherForecast = {};
  bool _isWeatherLoading = false;

  @override
  void initState() {
    super.initState();
    context.read<TripDetailCubit>().loadTrip(widget.tripId);
  }

  Future<void> _loadWeather(TripEntity trip) async {
    if (_weatherForecast.isNotEmpty || _isWeatherLoading) return;
    
    // UI döngülerini önlemek için bir sonraki karede setState yapalım
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _isWeatherLoading = true);

      // Varsayılan koordinatlar (Ankara)
      double lat = 39.9334;
      double lng = 32.8597;

      // Gezinin mekanlarından geçerli ilk koordinatları bulmaya çalış
      for (final day in trip.days) {
        for (final place in day.places) {
          if (place.lat != null && place.lng != null) {
            lat = place.lat!;
            lng = place.lng!;
            break;
          }
        }
      }

      final weatherService = getIt<WeatherService>();
      final forecast = await weatherService.getForecastForDates(
        latitude: lat,
        longitude: lng,
        startDate: trip.startDate,
        endDate: trip.endDate,
      );

      if (mounted) {
        setState(() {
          _weatherForecast = forecast;
          _isWeatherLoading = false;
        });
      }
    });
  }

  Color _getCategoryColor(String category) {
    if (category.contains('Müze') || category.contains('Kültür')) return AppColors.culturePrimary;
    if (category.contains('Doğa') || category.contains('Manzara')) return AppColors.naturePrimary;
    if (category.contains('Restoran') || category.contains('Yemek') || category.contains('Mutfak')) return AppColors.foodPrimary;
    if (category.contains('Macera') || category.contains('Spor')) return AppColors.adventurePrimary;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripDetailCubit, TripDetailState>(
      listener: (context, state) {
        if (state is TripDetailLoaded) {
          _loadWeather(state.trip);
        }
      },
      child: BlocBuilder<TripDetailCubit, TripDetailState>(
        builder: (context, state) {
          if (state is TripDetailLoading) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            );
          }
          if (state is TripDetailError) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.error, size: 44),
                    const SizedBox(height: 16),
                    Text(state.message,
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Ana Sayfa'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (state is TripDetailLoaded) {
            return _buildContent(context, state.trip);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, TripEntity trip) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // iOS Navigation Header
          _buildSliverHeader(context, trip),
          
          // Gezi özeti ve kontroller
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildTripSummary(context, trip),
                _buildDaySelector(trip),
                _buildWeatherWidget(trip),
                _buildRainAlertBanner(trip),
                _buildViewToggle(),
              ],
            ),
          ),
          
          // İçerik Alanı (Liste veya Harita)
          if (_selectedSegment == 0)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _buildPlacesList(trip),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 100),
              sliver: SliverToBoxAdapter(
                child: _buildMapView(trip),
              ),
            ),
        ],
      ),
      
      // Floating AI Assistant Button (Rehbere Sor)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/chat', extra: {
            'tripId': trip.id,
            'city': trip.days[_selectedDayIndex].city,
            'tripTheme': trip.preferences.join(', '),
          });
        },
        backgroundColor: AppColors.primary,
        icon: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        label: Text(
          'Rehbere Sor',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector(TripEntity trip) {
    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: trip.days.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedDayIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text('${index + 1}. Gün'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedDayIndex = index;
                    _selectedPlaceOnMap = null; // Haritadaki seçili pini sıfırla
                  });
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.secondaryBackground,
              labelStyle: GoogleFonts.inter(
                color: isSelected ? Colors.white : AppColors.secondaryLabel,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
              showCheckmark: false,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.transparent,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherWidget(TripEntity trip) {
    final dayDate = trip.startDate.add(Duration(days: _selectedDayIndex));
    final lookupDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
    final weatherInfo = _weatherForecast[lookupDate];

    if (_isWeatherLoading) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CupertinoActivityIndicator(color: Colors.white54),
        ),
      );
    }

    if (weatherInfo == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1C1C1E), width: 0.5),
      ),
      child: Row(
        children: [
          Text(
            weatherInfo.icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hava Durumu: ${weatherInfo.description}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'En Düşük: ${weatherInfo.minTemp.toStringAsFixed(0)}°C • En Yüksek: ${weatherInfo.maxTemp.toStringAsFixed(0)}°C',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRainAlertBanner(TripEntity trip) {
    final dayDate = trip.startDate.add(Duration(days: _selectedDayIndex));
    final lookupDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
    final weatherInfo = _weatherForecast[lookupDate];

    if (weatherInfo == null || !weatherInfo.isRainy) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        final dayNum = _selectedDayIndex + 1;
        final prompt = 'Seyahatimin $dayNum. günü hava yağmurlu görünüyor. Bana ${trip.days[_selectedDayIndex].city} şehrinde o günkü seyahat planıma uygun kapalı alternatif mekanlar önerebilir misin?';
        context.push('/chat', extra: {
          'tripId': trip.id,
          'city': trip.days[_selectedDayIndex].city,
          'tripTheme': 'Yağmurlu gün planı alternatifi',
          'initialMessage': prompt,
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF7F1D1D).withOpacity(0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF991B1B).withOpacity(0.4), width: 1),
        ),
        child: Row(
          children: [
            const Icon(CupertinoIcons.info_circle_fill, color: Color(0xFFF87171), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌧️ Seyahatin Bu Gününde Yağmur Bekleniyor!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFECACA),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Via Asistanı\'ndan kapalı mekan alternatifi almak için tıklayın.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFFFCA5A5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, color: Color(0xFFF87171), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: _selectedSegment,
        backgroundColor: const Color(0xFF1C1C1E),
        thumbColor: const Color(0xFF2C2C2E),
        children: {
          0: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.list_bullet, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Liste Görünümü',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          1: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.map, size: 16, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Harita Görünümü',
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        },
        onValueChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedSegment = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildPlacesList(TripEntity trip) {
    final day = trip.days[_selectedDayIndex];
    return Column(
      children: [
        ...day.places.indexed.map((entry) {
          final (pIndex, place) = entry;
          return _PlaceRow(
            place: place,
            index: pIndex,
            isLast: pIndex == day.places.length - 1,
            onTap: () => context.push('/place', extra: place),
          )
              .animate(delay: Duration(milliseconds: pIndex * 60))
              .fadeIn()
              .slideX(begin: 0.03, curve: Curves.easeOut);
        }),
      ],
    );
  }

  Widget _buildMapView(TripEntity trip) {
    final day = trip.days[_selectedDayIndex];
    final List<Marker> markers = [];
    final List<LatLng> points = [];

    for (int i = 0; i < day.places.length; i++) {
      final p = day.places[i];
      if (p.lat != null && p.lng != null) {
        final latLng = LatLng(p.lat!, p.lng!);
        points.add(latLng);

        final markerColor = _getCategoryColor(p.category);

        markers.add(
          Marker(
            point: latLng,
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedPlaceOnMap = p;
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: markerColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${i + 1}',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    LatLng center = const LatLng(39.9334, 32.8597); // Varsayılan Ankara
    if (points.isNotEmpty) {
      double avgLat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      double avgLng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
      center = LatLng(avgLat, avgLng);
    }

    final polyline = Polyline(
      points: points,
      color: AppColors.primary.withOpacity(0.8),
      strokeWidth: 4.0,
      borderColor: Colors.black26,
      borderStrokeWidth: 1.0,
    );

    return Container(
      height: 440,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1C1C1E), width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 12.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.sanalrehber.sanalrehber',
                ),
                if (points.isNotEmpty)
                  PolylineLayer(
                    polylines: [polyline],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
            
            // Apple Maps-style floating card
            if (_selectedPlaceOnMap != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: _buildFloatingPlaceCard(_selectedPlaceOnMap!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingPlaceCard(PlaceEntity place) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E), // systemGray6
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2C2C2E), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Resim
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child: FutureBuilder<String?>(
                future: PexelsCityPhotoService.getPlacePhotoUrl(
                  place.name,
                  city: place.city,
                  category: place.category,
                  photoQuery: place.photoQuery,
                ),
                builder: (context, snapshot) {
                  final url = snapshot.data;
                  if (url != null && url.isNotEmpty) {
                    return CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFF2C2C2E)),
                      errorWidget: (_, __, ___) => Container(color: const Color(0xFF2C2C2E)),
                    );
                  }
                  return Container(
                    color: const Color(0xFF2C2C2E),
                    child: const Icon(Icons.place_rounded, color: Colors.white24, size: 24),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  place.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  place.category,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _getCategoryColor(place.category),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  place.suggestedDuration,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          // Detay Git butonu
          IconButton(
            icon: const Icon(CupertinoIcons.chevron_right_circle_fill, color: AppColors.primary, size: 28),
            onPressed: () => context.push('/place', extra: place),
          ),
        ],
      ),
    );
  }

  // ── iOS Navigation Header ──────────────────────────────────────
  Widget _buildSliverHeader(BuildContext context, TripEntity trip) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      leading: GestureDetector(
        onTap: () => context.go('/home'),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground.withOpacity(0.8),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.chevron_left_rounded,
            size: 28,
            color: AppColors.primary,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          '${trip.fromCity} → ${trip.toCity}',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.label,
            letterSpacing: -0.4,
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            WikiCityImage(city: trip.toCity, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.15),
                    Colors.black.withOpacity(0.65),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gezi Özeti ─────────────────────────────────────────────────
  Widget _buildTripSummary(BuildContext context, TripEntity trip) {
    final dateFormat = DateFormat('d MMM yyyy', 'tr_TR');
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // İstatistik satırı
          Row(
            children: [
              _StatCard(
                icon: Icons.calendar_today_rounded,
                label: 'Süre',
                value: '${trip.durationDays} Gün',
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.place_rounded,
                label: 'Mekan',
                value: '${trip.days.fold(0, (s, d) => s + d.places.length)}',
                color: AppColors.systemOrange,
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.route_rounded,
                label: 'Durak',
                value: '${trip.waypoints.length + 2}',
                color: AppColors.systemTeal,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Tarih bandı
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondaryBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range_rounded,
                    color: AppColors.secondaryLabel, size: 18),
                const SizedBox(width: 8),
                Text(
                  '${dateFormat.format(trip.startDate)} – ${dateFormat.format(trip.endDate)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.secondaryLabel,
                  ),
                ),
                const Spacer(),
                // Tercihler
                ...trip.preferences.take(2).map((p) {
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      p.split(' ').first,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }
}

// ── İstatistik Kartı ──────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.tertiaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mekan Satırı — iOS Table Row ──────────────────────────────────
class _PlaceRow extends StatelessWidget {
  final dynamic place;
  final int index;
  final bool isLast;
  final VoidCallback onTap;

  const _PlaceRow({
    required this.place,
    required this.index,
    required this.isLast,
    required this.onTap,
  });

  static const _categoryColors = {
    'Müze': AppColors.culturePrimary,
    'Doğa': AppColors.naturePrimary,
    'Restoran': AppColors.foodPrimary,
    'Macera': AppColors.adventurePrimary,
  };

  Color get _color {
    for (final entry in _categoryColors.entries) {
      if (place.category.contains(entry.key)) return entry.value;
    }
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Numara
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.label,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        place.category,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.schedule_rounded,
                          size: 12, color: AppColors.tertiaryLabel),
                      const SizedBox(width: 3),
                      Text(
                        place.suggestedDuration,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.tertiaryLabel,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // iOS chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.tertiaryLabel,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
