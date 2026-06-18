import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../cubit/trip_detail_cubit.dart';
import '../cubit/trip_detail_state.dart';

class GeneratingScreen extends StatefulWidget {
  final String tripId;
  const GeneratingScreen({super.key, required this.tripId});

  @override
  State<GeneratingScreen> createState() => _GeneratingScreenState();
}

class _GeneratingScreenState extends State<GeneratingScreen> {
  int _messageIndex = 0;

  static const _messages = [
    'Şehirler araştırılıyor...',
    'Mekanlar seçiliyor...',
    'Güzergah hesaplanıyor...',
    'Plan düzenleniyor...',
    'Son rötuşlar yapılıyor...',
    'Planınız neredeyse hazır! ✨',
  ];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _startMessageRotation();
    context.read<TripDetailCubit>().watchTrip(widget.tripId);
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
      });
      _startMessageRotation();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripDetailCubit, TripDetailState>(
      listener: (context, state) {
        if (state is TripDetailLoaded && state.trip.isReady) {
          context.go('/trip/${widget.tripId}');
        } else if (state is TripDetailError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing orb
                  _buildPulsingOrb(),

                  const SizedBox(height: 48),

                  Text(
                    'AI Planınızı\nHazırlıyor',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.label,
                      letterSpacing: 0.36,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 16),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: Text(
                      _messages[_messageIndex],
                      key: ValueKey(_messageIndex),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: AppColors.secondaryLabel,
                        letterSpacing: -0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Minimal step dots
                  _buildStepDots(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingOrb() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dış halka — pulsing
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.15),
                width: 1,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.15, 1.15),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                begin: const Offset(1.15, 1.15),
                end: const Offset(0.85, 0.85),
                duration: 2.seconds,
                curve: Curves.easeInOut,
              ),

          // İç orb
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final isActive = i <= _messageIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary
                : AppColors.tertiaryBackground,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
