import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../cubit/trip_planner_cubit.dart';
import '../cubit/trip_planner_state.dart';

class StepPreferences extends StatelessWidget {
  const StepPreferences({super.key});

  static const _preferenceConfig = <String, (IconData, Color)>{
    'Kültür & Tarih': (Icons.account_balance_rounded, AppColors.culturePrimary),
    'Doğa & Manzara': (Icons.park_rounded, AppColors.naturePrimary),
    'Yemek & Mutfak': (Icons.restaurant_rounded, AppColors.foodPrimary),
    'Macera & Spor': (Icons.hiking_rounded, AppColors.adventurePrimary),
    'Alışveriş': (Icons.shopping_bag_rounded, AppColors.systemPink),
    'Gece Hayatı': (Icons.nightlife_rounded, AppColors.systemPurple),
    'Müze & Sanat': (Icons.museum_rounded, AppColors.systemTeal),
    'Mimari': (Icons.domain_rounded, AppColors.systemMint),
  };

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
                'Seyahat Tarzınız?',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.label,
                  letterSpacing: 0.36,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 6),
              Text(
                'Birden fazla seçebilirsiniz. Via planınızı buna göre şekillendirir.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.secondaryLabel,
                  letterSpacing: -0.2,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 20),

              // Seçim sayacı
              if (state.selectedPreferences.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${state.selectedPreferences.length} tercih seçildi ✓',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ).animate().fadeIn(),

              const SizedBox(height: 16),

              // Tercih kartları grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: AppConstants.travelPreferences.indexed.map((entry) {
                  final (index, pref) = entry;
                  final config = _preferenceConfig[pref] ??
                      (Icons.star_rounded, AppColors.primary);
                  final isSelected = state.selectedPreferences.contains(pref);

                  return _PreferenceCard(
                    label: pref,
                    icon: config.$1,
                    color: config.$2,
                    isSelected: isSelected,
                    animationDelay: Duration(milliseconds: 280 + index * 50),
                    onTap: () =>
                        context.read<TripPlannerCubit>().togglePreference(pref),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final Duration animationDelay;

  const _PreferenceCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.animationDelay,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.12)
              : AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: color.withOpacity(0.4), width: 1.5)
              : null,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(isSelected ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_rounded,
                    color: color,
                    size: 20,
                  ).animate().scale(begin: const Offset(0, 0)),
              ],
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.label : AppColors.secondaryLabel,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate(delay: animationDelay).fadeIn().slideY(begin: 0.12, curve: Curves.easeOut);
  }
}
