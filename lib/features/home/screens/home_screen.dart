import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/city_photo_widget.dart';
import '../../../domain/entities/trip_entity.dart';
import '../../../domain/repositories/trip_repository.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TripEntity> _trips = [];
  bool _isLoading = true;

  static const _discoverCities = [
    'İstanbul', 'Kapadokya', 'Antalya', 'Bodrum',
    'Trabzon', 'Mardin', 'İzmir', 'Pamukkale',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;
      final repo = context.read<TripRepository>();
      final trips = await repo.getUserTrips(userId);
      if (mounted) {
        setState(() {
          _trips = trips;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final greeting = _getGreeting();

          return Scaffold(
            backgroundColor: AppColors.background,
            body: RefreshIndicator(
              onRefresh: _loadTrips,
              color: AppColors.primary,
              backgroundColor: AppColors.surface,
              child: CustomScrollView(
                slivers: [
                  // ── iOS Large Title Header ──────────────────────
                  SliverToBoxAdapter(
                    child: _buildHeader(context, authState, greeting),
                  ),

                  // ── Yeni Gezi CTA ──────────────────────────────
                  SliverToBoxAdapter(
                    child: _buildNewTripButton(context),
                  ),

                  // ── Discover Section ───────────────────────────
                  SliverToBoxAdapter(
                    child: _buildDiscoverSection(context),
                  ),

                  // ── Gezilerim ──────────────────────────────────
                  if (_isLoading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else if (_trips.isEmpty)
                    SliverToBoxAdapter(
                      child: _buildEmptyState(context),
                    )
                  else ...[
                    // Bölüm Başlığı
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Gezilerim',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.label,
                                letterSpacing: 0.35,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_trips.length} gezi',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Gezi Kartları Listesi
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildTripCard(context, _trips[index], index),
                          childCount: _trips.length,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── iOS Large Title Header ──────────────────────────────────────
  Widget _buildHeader(BuildContext context, AuthState authState, String greeting) {
    final isAnonymous = authState is AuthAuthenticated ? authState.isAnonymous : true;
    final displayName = authState is AuthAuthenticated ? authState.displayName : null;
    final photoUrl = authState is AuthAuthenticated ? authState.photoUrl : null;

    final userName = isAnonymous
        ? 'Kaşif'
        : (displayName?.split(' ').first ?? 'Gezgin');

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: Selamlama + Avatar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryLabel,
                    letterSpacing: -0.2,
                  ),
                ),
                // Profil avatarı
                GestureDetector(
                  onTap: () => _showProfileBottomSheet(context, authState),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryBackground,
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: photoUrl != null && photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              Icons.person_rounded,
                              color: AppColors.secondaryLabel,
                              size: 20,
                            ),
                          )
                        : Icon(
                            isAnonymous
                                ? Icons.person_outline_rounded
                                : Icons.person_rounded,
                            color: AppColors.secondaryLabel,
                            size: 20,
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Büyük başlık — Apple Large Title
            Text(
              '$userName 👋',
              style: GoogleFonts.inter(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: AppColors.label,
                letterSpacing: 0.37,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  // ── Yeni Gezi CTA ──────────────────────────────────────────────
  Widget _buildNewTripButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: GestureDetector(
        onTap: () => context.push('/planner'),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yeni Gezi Planı Oluştur',
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    Text(
                      'AI destekli kişisel rehberiniz',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white70,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, curve: Curves.easeOut);
  }

  // ── Discover Section ────────────────────────────────────────────
  Widget _buildDiscoverSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Text(
            'Öne Çıkan Destinasyonlar',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.label,
              letterSpacing: 0.35,
            ),
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _discoverCities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final city = _discoverCities[index];
              return GestureDetector(
                onTap: () => context.push('/planner'),
                child: _buildDiscoverCard(context, city, index),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    ).animate().fadeIn(delay: 350.ms);
  }

  Widget _buildDiscoverCard(BuildContext context, String city, int index) {
    return SizedBox(
      width: 130,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            WikiCityImage(city: city, fit: BoxFit.cover),
            // Alt gradient
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.45, 1.0],
                ),
              ),
            ),
            // Şehir adı
            Positioned(
              left: 10,
              right: 10,
              bottom: 10,
              child: Text(
                city,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 400 + index * 60))
        .fadeIn()
        .slideX(begin: 0.1, curve: Curves.easeOut);
  }

  // ── Landscape Trip Card — Büyük Yatay Kart ─────────────────────
  Widget _buildTripCard(BuildContext context, TripEntity trip, int index) {
    final dateFormat = DateFormat('d MMM', 'tr_TR');

    return Dismissible(
      key: ValueKey(trip.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDeleteTrip(context, trip),
      onDismissed: (_) async {
        final repo = context.read<TripRepository>();
        await repo.deleteTrip(trip.id);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
      ),
      child: GestureDetector(
        onTap: () {
          if (trip.isReady) {
            context.push('/trip/${trip.id}');
          } else if (trip.isGenerating) {
            context.push('/generating/${trip.id}');
          }
        },
        onLongPress: () => _confirmDeleteTrip(context, trip).then((confirmed) {
          if (confirmed == true) {
            context.read<TripRepository>().deleteTrip(trip.id);
          }
        }),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.secondaryBackground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Fotoğraf Üst Alan ──
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      WikiCityImage(city: trip.toCity, fit: BoxFit.cover),
                      // Hafif gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.05),
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                      // Şehir adı
                      Positioned(
                        left: 16,
                        bottom: 14,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trip.toCity,
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.35,
                              ),
                            ),
                            Text(
                              '${trip.fromCity} → ${trip.toCity}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white70,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Durum badge
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _buildStatusBadge(trip.status),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Alt Bilgi Satırı — iOS Tarzı ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
                child: Row(
                  children: [
                    // Tarih
                    _InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label:
                          '${dateFormat.format(trip.startDate)} – ${dateFormat.format(trip.endDate)}',
                    ),
                    const SizedBox(width: 8),
                    // Süre
                    _InfoChip(
                      icon: Icons.access_time_rounded,
                      label: '${trip.durationDays} gün',
                    ),
                    const Spacer(),
                    // iOS chevron
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.tertiaryLabel,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 100 + index * 80))
        .fadeIn()
        .slideY(begin: 0.06, curve: Curves.easeOut);
  }

  // ── Silme Onay Dialog — iOS Alert Style ─────────────────────────
  Future<bool?> _confirmDeleteTrip(
      BuildContext context, TripEntity trip) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        title: Text(
          'Geziyi Sil',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: AppColors.label,
          ),
        ),
        content: Text(
          '${trip.fromCity} → ${trip.toCity} gezisi kalıcı olarak silinecek. Emin misiniz?',
          style: GoogleFonts.inter(
            color: AppColors.secondaryLabel,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'İptal',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w400,
                fontSize: 17,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Sil',
              style: GoogleFonts.inter(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status Badge ────────────────────────────────────────────────
  Widget _buildStatusBadge(TripStatus status) {
    switch (status) {
      case TripStatus.ready:
        return _StatusBadge(label: 'Hazır', color: AppColors.success);
      case TripStatus.generating:
        return _StatusBadge(
          label: 'Hazırlanıyor',
          color: AppColors.warning,
          showSpinner: true,
        );
      case TripStatus.error:
        return _StatusBadge(label: 'Hata', color: AppColors.error);
    }
  }

  // ── Empty State ─────────────────────────────────────────────────
  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
      child: Container(
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
                Icons.travel_explore_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'İlk Gezinizi Planlayın',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.label,
                letterSpacing: 0.38,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI rehberiniz hazır. Yukarıdaki butona\ntıklayarak ilk gezi planınızı oluşturun!',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppColors.secondaryLabel,
                height: 1.5,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Günaydın ☀️';
    if (hour < 18) return 'İyi günler 🌤️';
    return 'İyi akşamlar 🌙';
  }

  void _showProfileBottomSheet(BuildContext context, AuthState authState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16),
        ),
      ),
      builder: (bottomSheetContext) {
        final String name;
        final String email;
        final String? photoUrl;
        final bool isAnonymous;

        if (authState is AuthAuthenticated) {
          isAnonymous = authState.isAnonymous;
          name = isAnonymous ? 'Misafir Kullanıcı' : (authState.displayName ?? 'Gezgin');
          email = isAnonymous ? 'Anonim Giriş' : (authState.email ?? '');
          photoUrl = authState.photoUrl;
        } else {
          isAnonymous = true;
          name = 'Misafir Kullanıcı';
          email = 'Anonim Giriş';
          photoUrl = null;
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Profil',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.label,
                    letterSpacing: 0.35,
                  ),
                ),
                const SizedBox(height: 20),

                // Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      if (photoUrl != null && photoUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: CachedNetworkImage(
                            imageUrl: photoUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 56,
                              height: 56,
                              color: AppColors.tertiaryBackground,
                              child: const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 56,
                              height: 56,
                              color: AppColors.primary,
                              child: const Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.label,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.secondaryLabel,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (isAnonymous) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.systemOrange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.systemOrange.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.systemOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Hesabınızı Kaybetmeyin',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.systemOrange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Misafir girişi ile oluşturduğunuz planlar uygulama silindiğinde kaybolur. Hesabınızı kalıcı hale getirmek için Google ile bağlayın.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.secondaryLabel,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(bottomSheetContext);
                              context.read<AuthCubit>().signInWithGoogle();
                            },
                            icon: Image.network(
                              'https://www.google.com/favicon.ico',
                              width: 18,
                              height: 18,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.g_mobiledata, size: 20),
                            ),
                            label: Text(
                              'Google ile Bağla',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1D1D1F),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.tertiaryBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.secondaryLabel,
                          size: 22,
                        ),
                        title: Text(
                          'Uygulama Sürümü',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.label,
                          ),
                        ),
                        trailing: Text(
                          'v1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                      ),
                      Container(
                        height: 0.5,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        color: AppColors.separator,
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.systemRed,
                          size: 22,
                        ),
                        title: Text(
                          'Çıkış Yap',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.systemRed,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(bottomSheetContext);
                          context.read<AuthCubit>().signOut();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Yardımcı Widgetlar ────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.tertiaryLabel),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryLabel,
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool showSpinner;

  const _StatusBadge({
    required this.label,
    required this.color,
    this.showSpinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                color: color,
                strokeWidth: 1.5,
              ),
            )
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
