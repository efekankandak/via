import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../cubit/trip_planner_cubit.dart';
import '../cubit/trip_planner_state.dart';
import '../widgets/step_city_selection.dart';
import '../widgets/step_date_selection.dart';
import '../widgets/step_preferences.dart';
import '../widgets/step_waypoints.dart';

class TripPlannerScreen extends StatelessWidget {
  const TripPlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TripPlannerCubit, TripPlannerState>(
      listener: (context, state) {
        if (state.generatingTripId != null && !state.isGenerating) {
          context.go('/generating/${state.generatingTripId}');
        }
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // iOS Navigation Bar
                _buildNavBar(context, state),
                // Adım göstergesi
                _buildStepIndicator(state),
                // İçerik
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCurrentStep(context, state),
                  ),
                ),
                // Alt buton
                _buildBottomButton(context, state),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── iOS Navigation Bar ──────────────────────────────────────────
  Widget _buildNavBar(BuildContext context, TripPlannerState state) {
    final stepTitles = [
      'Nereden → Nereye',
      'Tarih & Süre',
      'Tercihlerim',
      'Yol Üstü Duraklar',
    ];
    final stepIndex = PlannerStep.values.indexOf(state.currentStep);

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          // iOS geri butonu
          IconButton(
            onPressed: () {
              if (state.currentStep == PlannerStep.citySelection) {
                context.pop();
              } else {
                context.read<TripPlannerCubit>().previousStep();
              }
            },
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  stepTitles[stepIndex],
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: AppColors.label,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Adım ${stepIndex + 1} / 4',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
          // Kapat butonu
          IconButton(
            onPressed: () => context.go('/home'),
            icon: const Icon(
              Icons.close_rounded,
              color: AppColors.secondaryLabel,
              size: 22,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  // ── iOS Step Indicator ──────────────────────────────────────────
  Widget _buildStepIndicator(TripPlannerState state) {
    final stepIndex = PlannerStep.values.indexOf(state.currentStep);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= stepIndex;
          return Expanded(
            child: Container(
              height: 3,
              margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : AppColors.tertiaryBackground,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context, TripPlannerState state) {
    switch (state.currentStep) {
      case PlannerStep.citySelection:
        return const StepCitySelection(key: ValueKey('city'));
      case PlannerStep.dateSelection:
        return const StepDateSelection(key: ValueKey('date'));
      case PlannerStep.preferences:
        return const StepPreferences(key: ValueKey('pref'));
      case PlannerStep.waypoints:
        return const StepWaypoints(key: ValueKey('way'));
    }
  }

  // ── Alt Buton — iOS Filled Button ──────────────────────────────
  Widget _buildBottomButton(BuildContext context, TripPlannerState state) {
    final cubit = context.read<TripPlannerCubit>();
    final isLastStep = state.currentStep == PlannerStep.waypoints;
    final canProceed = _canProceed(state);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: canProceed
              ? () {
                  if (isLastStep) {
                    cubit.generateTrip();
                  } else if (state.currentStep == PlannerStep.preferences) {
                    _showWaypointSelectionDialog(context, cubit);
                  } else {
                    cubit.nextStep();
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.tertiaryBackground,
            disabledForegroundColor: AppColors.tertiaryLabel,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: state.isGenerating
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Plan oluşturuluyor...',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  isLastStep ? 'Planımı Oluştur ✨' : 'Devam Et',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.4,
                  ),
                ),
        ),
      ),
    );
  }

  bool _canProceed(TripPlannerState state) {
    switch (state.currentStep) {
      case PlannerStep.citySelection:
        return state.canProceedStep1;
      case PlannerStep.dateSelection:
        return state.canProceedStep2;
      case PlannerStep.preferences:
        return state.canProceedStep3;
      case PlannerStep.waypoints:
        return true;
    }
  }

  void _showWaypointSelectionDialog(BuildContext context, TripPlannerCubit cubit) {
    showCupertinoDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => CupertinoAlertDialog(
        title: Text(
          'Yol Üstü Duraklar',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            'Rotanız üzerinde uğramak istediğiniz başka duraklar/şehirler eklemek ister misiniz?',
            style: GoogleFonts.inter(
              color: AppColors.secondaryLabel,
            ),
          ),
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: Text(
              'Hayır, Direkt Oluştur',
              style: GoogleFonts.inter(
                color: Colors.white54,
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.generateTrip();
            },
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              'Evet, Durak Ekle',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.nextStep();
            },
          ),
        ],
      ),
    );
  }
}
