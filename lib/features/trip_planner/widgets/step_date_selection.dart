import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/city_photo_widget.dart';
import '../cubit/trip_planner_cubit.dart';
import '../cubit/trip_planner_state.dart';

class StepDateSelection extends StatelessWidget {
  const StepDateSelection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripPlannerCubit, TripPlannerState>(
      builder: (context, state) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Atmosferik Banner ──────────────────
              _buildAtmosphericBanner(context, state),

              // ── İçerik ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ne Zaman Gidiyorsunuz?',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.label,
                        letterSpacing: 0.36,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 6),
                    Text(
                      'Gezi tarihleri ve süresini belirleyin',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.secondaryLabel,
                        letterSpacing: -0.2,
                      ),
                    ).animate().fadeIn(delay: 180.ms),

                    const SizedBox(height: 24),

                    // ── Tarih Seçici ─────────────────
                    GestureDetector(
                      onTap: () => _pickDateRange(context),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DateBox(
                                label: 'BAŞLANGIÇ',
                                date: state.startDate,
                                color: AppColors.primary,
                                icon: Icons.flight_takeoff_rounded,
                              ),
                            ),
                            Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 14),
                              width: 0.5,
                              height: 48,
                              color: AppColors.separator,
                            ),
                            Expanded(
                              child: _DateBox(
                                label: 'BİTİŞ',
                                date: state.endDate,
                                color: AppColors.systemOrange,
                                icon: Icons.flight_land_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1, curve: Curves.easeOut),

                    // ── Süre Gösterimi ───────────────
                    if (state.startDate != null &&
                        state.endDate != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${state.durationDays} Günlük Gezi',
                                  style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${state.toCity.isEmpty ? "Destinasyon" : state.toCity} bekleniyor',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn().scale(
                          begin: const Offset(0.97, 0.97)),
                    ],

                    const SizedBox(height: 28),

                    // ── Hızlı Seçimler ──────────────
                    Text(
                      'Hızlı Seçimler',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryLabel,
                      ),
                    ).animate().fadeIn(delay: 380.ms),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: const [
                        _QuickDayChip(days: 2, label: 'Hafta Sonu', emoji: '🌅'),
                        _QuickDayChip(days: 3, label: '3 Gün', emoji: '🏙️'),
                        _QuickDayChip(days: 5, label: '5 Gün', emoji: '✈️'),
                        _QuickDayChip(days: 7, label: '1 Hafta', emoji: '🗺️'),
                        _QuickDayChip(days: 10, label: '10 Gün', emoji: '🌍'),
                        _QuickDayChip(days: 14, label: '2 Hafta', emoji: '🏝️'),
                      ],
                    ).animate().fadeIn(delay: 460.ms),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAtmosphericBanner(
      BuildContext context, TripPlannerState state) {
    final hasCity = state.toCity.isNotEmpty;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SizeTransition(sizeFactor: animation, child: child),
      ),
      child: hasCity
          ? CityPhotoBanner(
              key: ValueKey(state.toCity),
              city: state.toCity,
              height: 180,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
              gradientBegin: Alignment.topCenter,
              gradientEnd: Alignment.bottomCenter,
              gradientColors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
                AppColors.background.withOpacity(0.85),
                AppColors.background,
              ],
              child: Positioned(
                left: 20,
                bottom: 14,
                child: Row(
                  children: [
                    Icon(Icons.place_rounded,
                        color: AppColors.systemOrange, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      state.toCity,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Seçilen Destinasyon',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox(key: ValueKey('empty'), height: 0),
    );
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      locale: const Locale('tr', 'TR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.secondaryBackground,
              onSurface: AppColors.label,
            ),
          ),
          child: child!,
        );
      },
    );
    if (result != null && context.mounted) {
      context
          .read<TripPlannerCubit>()
          .setDateRange(result.start, result.end);
    }
  }
}

// ── DateBox ───────────────────────────────────────────────────────
class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? date;
  final Color color;
  final IconData icon;

  const _DateBox({
    required this.label,
    required this.date,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM', 'tr_TR');
    final yearFormat = DateFormat('yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.tertiaryLabel,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (date != null) ...[
          Text(
            dateFormat.format(date!),
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            yearFormat.format(date!),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.secondaryLabel,
            ),
          ),
        ] else
          Text(
            'Seç',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.tertiaryLabel,
            ),
          ),
      ],
    );
  }
}

// ── QuickDayChip ──────────────────────────────────────────────────
class _QuickDayChip extends StatelessWidget {
  final int days;
  final String label;
  final String emoji;

  const _QuickDayChip({
    required this.days,
    required this.label,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));
        final end = tomorrow.add(Duration(days: days - 1));
        context.read<TripPlannerCubit>().setDateRange(tomorrow, end);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryLabel,
              ),
            ),
            Text(
              '$days gün',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
