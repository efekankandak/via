import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/city_photo_widget.dart';
import '../../../core/widgets/city_picker_bottom_sheet.dart';
import '../cubit/trip_planner_cubit.dart';
import '../cubit/trip_planner_state.dart';

class StepWaypoints extends StatefulWidget {
  const StepWaypoints({super.key});

  @override
  State<StepWaypoints> createState() => _StepWaypointsState();
}

class _StepWaypointsState extends State<StepWaypoints> {
  Future<void> _pickAndAddWaypoint() async {
    final cubit = context.read<TripPlannerCubit>();
    final picked = await CityPickerBottomSheet.show(
      context,
      title: 'Yol Üstü Durak Ekle',
    );
    if (picked != null) {
      cubit.addWaypoint(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TripPlannerCubit, TripPlannerState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yol Üstü Duraklar',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.label,
                  letterSpacing: 0.36,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 6),
              Text(
                'Rota üzerinde uğramak istediğiniz şehirleri ekleyin.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.secondaryLabel,
                  height: 1.5,
                  letterSpacing: -0.2,
                ),
              ).animate().fadeIn(delay: 180.ms),

              const SizedBox(height: 24),

              // ── Seçim Alanı (81 İl Seçimi) ─────────
              GestureDetector(
                onTap: _pickAndAddWaypoint,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.separator.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.add_location_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Şehir Seçip Durak Ekle...',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondaryLabel,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.add_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1, curve: Curves.easeOut),

              const SizedBox(height: 28),

              // ── Rota Görselleştirme ───────────────
              if (state.waypoints.isNotEmpty) ...[
                Text(
                  'Güzergahınız',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryLabel,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 16),
                _buildRouteVisualization(context, state),
              ] else
                _buildEmptyState(context).animate().fadeIn(delay: 380.ms),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRouteVisualization(
      BuildContext context, TripPlannerState state) {
    final allStops = [state.fromCity, ...state.waypoints, state.toCity];

    return Column(
      children: allStops.indexed.map((entry) {
        final (index, city) = entry;
        final isFirst = index == 0;
        final isLast = index == allStops.length - 1;
        final isWaypoint = !isFirst && !isLast;

        final nodeColor = isFirst
            ? AppColors.primary
            : isLast
                ? AppColors.systemOrange
                : AppColors.systemTeal;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Şehir Fotoğraf
                  Stack(
                    children: [
                      CityPhotoAvatar(
                        city: city,
                        size: 48,
                        isCircle: false,
                        borderRadius: 10,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: nodeColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.secondaryBackground, width: 2),
                          ),
                          child: Icon(
                            isFirst
                                ? Icons.trip_origin_rounded
                                : isLast
                                    ? Icons.place_rounded
                                    : Icons.radio_button_checked_rounded,
                            color: Colors.white,
                            size: 9,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isFirst
                              ? 'Kalkış Noktası'
                              : isLast
                                  ? 'Varış Noktası'
                                  : 'Durak $index',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: nodeColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          city,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.label,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sil butonu
                  if (isWaypoint)
                    GestureDetector(
                      onTap: () =>
                          context.read<TripPlannerCubit>().removeWaypoint(city),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: AppColors.error,
                          size: 16,
                        ),
                      ),
                    ),

                  if (isFirst || isLast)
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: nodeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isFirst
                            ? Icons.flight_takeoff_rounded
                            : Icons.flag_rounded,
                        color: nodeColor,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),

            // Bağlayıcı çizgi
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 36),
                child: Column(
                  children: List.generate(
                    4,
                    (_) => Container(
                      width: 2,
                      height: 5,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.separator,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        )
            .animate(delay: Duration(milliseconds: 80 * index))
            .fadeIn()
            .slideX(begin: -0.06, curve: Curves.easeOut);
      }).toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.secondaryBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.route_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Yol Üstü Durak Ekle',
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.label,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Güzergahınıza eklemek istediğiniz durakları\nyukarıdan seçebilirsiniz.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.secondaryLabel,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
