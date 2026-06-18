import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // ── App Icon ───────────────────────────────
                _buildAppIcon()
                    .animate()
                    .fadeIn(duration: 700.ms)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: 28),

                // ── Başlık ─────────────────────────────────
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.inter(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.label,
                    letterSpacing: 0.37,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 8),

                Text(
                  'Yapay zeka destekli kişisel\nseyahat rehberiniz Via',
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryLabel,
                    height: 1.4,
                    letterSpacing: -0.4,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 350.ms),

                const Spacer(flex: 2),

                // ── Özellik Satırı ─────────────────────────
                _buildFeatureRow(context)
                    .animate()
                    .fadeIn(delay: 500.ms),

                const Spacer(flex: 2),

                // ── Google ile Giriş ───────────────────────
                _buildGoogleButton(context)
                    .animate()
                    .fadeIn(delay: 650.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOut),

                const SizedBox(height: 12),

                // ── Misafir Girişi ─────────────────────────
                _buildGuestButton(context)
                    .animate()
                    .fadeIn(delay: 750.ms)
                    .slideY(begin: 0.15, curve: Curves.easeOut),

                const SizedBox(height: 32),

                // ── Alt Not ────────────────────────────────
                Text(
                  'Giriş yaparak Gizlilik Politikası ve\nKullanım Koşullarını kabul etmiş olursunuz.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.tertiaryLabel,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 850.ms),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── App Icon — iOS App Icon Tarzı ──────────────────────────────
  Widget _buildAppIcon() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22), // iOS app icon radius
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withOpacity(0.35),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: 96,
          height: 96,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // ── Özellik Satırı ─────────────────────────────────────────────
  Widget _buildFeatureRow(BuildContext context) {
    final features = [
      (Icons.auto_awesome_rounded, 'AI Planlama', AppColors.primary),
      (Icons.headphones_rounded, 'Sesli Rehber', AppColors.systemTeal),
      (Icons.place_rounded, 'Mekan Bilgisi', AppColors.systemOrange),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: features.indexed.map((entry) {
        final (i, f) = entry;
        return _FeatureItem(icon: f.$1, label: f.$2, color: f.$3)
            .animate(delay: Duration(milliseconds: 550 + i * 80))
            .fadeIn()
            .slideY(begin: 0.2);
      }).toList(),
    );
  }

  // ── Google ile Giriş Butonu ────────────────────────────────────
  Widget _buildGoogleButton(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () => context.read<AuthCubit>().signInWithGoogle(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1D1D1F),
              disabledBackgroundColor: Colors.white60,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1D1D1F),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://www.google.com/favicon.ico',
                        width: 20,
                        height: 20,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.g_mobiledata, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Google ile Devam Et',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1D1D1F),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  // ── Misafir Girişi Butonu ──────────────────────────────────────
  Widget _buildGuestButton(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: TextButton(
            onPressed: isLoading
                ? null
                : () => context.read<AuthCubit>().signInAnonymously(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Misafir Olarak Devam Et',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: AppColors.primary,
                letterSpacing: -0.4,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Özellik Öğesi ────────────────────────────────────────────────
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryLabel,
          ),
        ),
      ],
    );
  }
}
