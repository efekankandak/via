import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Başlangıç değerleri (Native Splash ile birebir eşleşme için)
  double _logoSize = 108;
  double _borderRadius = 54; // Tam daire (108 / 2)
  double _shadowOpacity = 0.0;
  double _textOpacity = 0.0;
  double _textTranslateY = 20.0;

  @override
  void initState() {
    super.initState();
    
    // İlk kare çizildikten hemen sonra animasyonu tetikle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _logoSize = 124; // Apple standardı boyutuna büyü
            _borderRadius = 28; // Daireden iOS rounded rectangle şekline dönüştür
            _shadowOpacity = 1.0; // Gölge/parlama efekti görünür olsun
            _textOpacity = 1.0; // Yazılar fade-in olsun
            _textTranslateY = 0.0; // Yazılar yukarı doğru süzülsün
          });
        }
      });
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Arka planda auth durumunu kontrol et
    final authCubit = context.read<AuthCubit>();
    await authCubit.checkAuthState();

    // 2. Animasyonun en az 2.5 saniye sürdüğünden emin olmak için bekle
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // 3. Oturum durumuna göre uygun ekrana yönlendir
    final state = authCubit.state;
    final hasUser = FirebaseAuth.instance.currentUser != null;
    final isAuthenticated = state is AuthAuthenticated || hasUser;

    if (isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Saf siyah Apple arka planı
      body: Stack(
        children: [
          // Logo — Her zaman ekranın tam ortasında (Layout sıçramalarını önler)
          Align(
            alignment: Alignment.center,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeOutBack,
              width: _logoSize,
              height: _logoSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.35 * _shadowOpacity), // Mor gölge
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.25 * _shadowOpacity), // Mavi gölge
                    blurRadius: 50,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_borderRadius),
                child: Image.asset(
                  'assets/images/app_logo.png',
                  width: _logoSize,
                  height: _logoSize,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // Yazılar — Logonun altında yer alacak şekilde bağımsız hizalanmış
          Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(0, 130 + _textTranslateY),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOut,
                opacity: _textOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Marka İsmi (Via)
                    Text(
                      'Via',
                      style: GoogleFonts.inter(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Alt Başlık
                    Text(
                      'Yapay Zeka Destekli Seyahat Rehberi',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.5),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
