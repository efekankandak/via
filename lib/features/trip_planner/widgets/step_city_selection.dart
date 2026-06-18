import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/city_photo_widget.dart';
import '../../../core/widgets/city_picker_bottom_sheet.dart';
import '../cubit/trip_planner_cubit.dart';
import '../cubit/trip_planner_state.dart';


class StepCitySelection extends StatefulWidget {
  const StepCitySelection({super.key});

  @override
  State<StepCitySelection> createState() => _StepCitySelectionState();
}

class _StepCitySelectionState extends State<StepCitySelection> {
  static const _featured = [
    'İstanbul', 'Antalya', 'Kapadokya', 'Bodrum',
    'İzmir', 'Trabzon', 'Mardin', 'Bursa',
  ];

  Future<void> _pickCity({required bool isFrom}) async {
    final state = context.read<TripPlannerCubit>().state;
    final current = isFrom ? state.fromCity : state.toCity;

    final picked = await CityPickerBottomSheet.show(
      context,
      title: isFrom ? 'Nereden Gidiyorsunuz?' : 'Nereye Gidiyorsunuz?',
      currentCity: current.isEmpty ? null : current,
    );

    if (picked != null && mounted) {
      if (isFrom) {
        context.read<TripPlannerCubit>().setFromCity(picked);
      } else {
        context.read<TripPlannerCubit>().setToCity(picked);
      }
    }
  }

  void _swapCities() {
    final state = context.read<TripPlannerCubit>().state;
    context.read<TripPlannerCubit>().setFromCity(state.toCity);
    context.read<TripPlannerCubit>().setToCity(state.fromCity);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripPlannerCubit, TripPlannerState>(
      builder: (context, state) {
        final hasFrom = state.fromCity.isNotEmpty;
        final hasTo = state.toCity.isNotEmpty;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero Bölümü ──────────────────────────────
              _buildHero(context, state),

              // ── İçerik ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rotanızı Belirleyin',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.label,
                        letterSpacing: 0.36,
                      ),
                    ).animate().fadeIn(delay: 80.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Türkiye\'nin 81 ilinden seçin',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.secondaryLabel,
                        letterSpacing: -0.2,
                      ),
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 20),

                    // ── Şehir Seçim Kartları ─────────────
                    _buildCitySelector(context, state),

                    const SizedBox(height: 24),

                    // ── Öne Çıkan Destinasyonlar ─────────
                    if (!hasFrom || !hasTo) ...[
                      Text(
                        'Popüler Destinasyonlar',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondaryLabel,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),

              // ── Featured Cities ──────────────────────
              if (!hasFrom || !hasTo) ...[
                SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _featured.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final city = _featured[i];
                      return _FeaturedCityCard(
                        city: city,
                        onTap: () {
                          if (!hasTo) {
                            context.read<TripPlannerCubit>().setToCity(city);
                          } else if (!hasFrom) {
                            context.read<TripPlannerCubit>().setFromCity(city);
                          }
                        },
                      )
                          .animate(delay: Duration(milliseconds: 450 + i * 50))
                          .fadeIn()
                          .slideX(begin: 0.1, curve: Curves.easeOut);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── Tüm 81 İl Butonu ──────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GestureDetector(
                  onTap: () => _pickCity(isFrom: !hasFrom),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.list_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Tüm 81 İli Göster',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.tertiaryLabel, size: 20),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 550.ms),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ── Hero Bölümü ───────────────────────────────────────────────
  Widget _buildHero(BuildContext context, TripPlannerState state) {
    final hasTo = state.toCity.isNotEmpty;
    final hasFrom = state.fromCity.isNotEmpty;

    if (hasFrom && hasTo) {
      return _buildDualCityHero(state).animate().fadeIn();
    }
    if (hasTo) {
      return _CityBanner(city: state.toCity, height: 190)
          .animate(key: ValueKey(state.toCity))
          .fadeIn();
    }
    return _buildWelcomeBanner().animate().fadeIn();
  }

  Widget _buildWelcomeBanner() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(20)),
            child: WikiCityImage(
              city: 'İstanbul',
              width: double.infinity,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.2),
                  AppColors.background.withOpacity(0.85),
                  AppColors.background,
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Türkiye\'yi Keşfet 🇹🇷',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '81 il, sonsuz keşif',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDualCityHero(TripPlannerState state) {
    return SizedBox(
      height: 170,
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 170,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        WikiCityImage(city: state.fromCity, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nereden',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                state.fromCity,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 170,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        WikiCityImage(city: state.toCity, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nereye',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                state.toCity,
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Ortadaki uçak
          Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.flight_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Şehir Seçim Kartları ───────────────────────────────────────
  Widget _buildCitySelector(BuildContext context, TripPlannerState state) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _CityPickCard(
            label: 'NEREDEN',
            city: state.fromCity.isEmpty ? null : state.fromCity,
            icon: Icons.flight_takeoff_rounded,
            color: AppColors.primary,
            hint: 'Kalkış şehri seçin',
            onTap: () => _pickCity(isFrom: true),
            isTop: true,
          ),
          _buildSwapRow(),
          _CityPickCard(
            label: 'NEREYE',
            city: state.toCity.isEmpty ? null : state.toCity,
            icon: Icons.flight_land_rounded,
            color: AppColors.systemOrange,
            hint: 'Varış şehri seçin',
            onTap: () => _pickCity(isFrom: false),
            isTop: false,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.08, curve: Curves.easeOut);
  }

  Widget _buildSwapRow() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 0.5,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: AppColors.separator,
        ),
        GestureDetector(
          onTap: _swapCities,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.swap_vert_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

// ── City Pick Card ────────────────────────────────────────────────
class _CityPickCard extends StatelessWidget {
  final String label;
  final String? city;
  final IconData icon;
  final Color color;
  final String hint;
  final VoidCallback onTap;
  final bool isTop;

  const _CityPickCard({
    required this.label,
    required this.city,
    required this.icon,
    required this.color,
    required this.hint,
    required this.onTap,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    final hasCity = city != null && city!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, isTop ? 14 : 10, 14, isTop ? 10 : 14),
        child: Row(
          children: [
            // Şehir fotoğrafı avatarı
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: hasCity
                  ? ClipRRect(
                      key: ValueKey(city),
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: WikiCityImage(
                          city: city!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorWidget: Container(
                            color: color.withOpacity(0.12),
                            child: Icon(icon, color: color, size: 20),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      key: const ValueKey('empty'),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.tertiaryLabel,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      hasCity ? city! : hint,
                      key: ValueKey(city),
                      style: GoogleFonts.inter(
                        fontSize: hasCity ? 17 : 15,
                        fontWeight:
                            hasCity ? FontWeight.w600 : FontWeight.w400,
                        color: hasCity
                            ? AppColors.label
                            : AppColors.tertiaryLabel,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              hasCity ? Icons.edit_rounded : Icons.add_rounded,
              color: hasCity ? color : AppColors.tertiaryLabel,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Featured City Card ────────────────────────────────────────────
class _FeaturedCityCard extends StatelessWidget {
  final String city;
  final VoidCallback onTap;

  const _FeaturedCityCard({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 120,
          height: 130,
          child: Stack(
            fit: StackFit.expand,
            children: [
              WikiCityImage(city: city, fit: BoxFit.cover),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                    stops: [0.4, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  city,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── City Banner ───────────────────────────────────────────────────
class _CityBanner extends StatelessWidget {
  final String city;
  final double height;

  const _CityBanner({required this.city, required this.height});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            WikiCityImage(city: city, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                    AppColors.background,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 14,
              child: Row(
                children: [
                  Icon(Icons.place_rounded,
                      color: AppColors.systemOrange, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    city,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
