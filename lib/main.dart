import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/pexels_photo_service.dart';
import 'core/theme/app_theme.dart';
import 'domain/repositories/trip_repository.dart';
import 'features/auth/cubit/auth_cubit.dart';
import 'firebase_options.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Türkçe tarih biçimlendirme
  await initializeDateFormatting('tr_TR', null);

  // Sistem UI ayarları — Apple Dark Mode
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Firebase başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Dependency Injection kurulumu
  await setupDependencies();

  // Fotoğraf önbelleğini disk'ten yükle (anında fotoğraf için)
  await PexelsCityPhotoService.init();

  runApp(const SanalRehberApp());
}

class SanalRehberApp extends StatelessWidget {
  const SanalRehberApp({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<TripRepository>(
      create: (_) => getIt<TripRepository>(),
      child: BlocProvider<AuthCubit>(
        create: (_) => AuthCubit(
          auth: FirebaseAuth.instance,
          googleSignIn: GoogleSignIn(),
        )..checkAuthState(),
        child: Builder(
          builder: (context) {
            final router = AppRouter.createRouter(context);
            return MaterialApp.router(
              title: 'Via',
              theme: AppTheme.darkTheme,
              themeMode: ThemeMode.dark,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              locale: const Locale('tr', 'TR'),
              supportedLocales: const [
                Locale('tr', 'TR'),
                Locale('en', 'US'),
              ],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            );
          },
        ),
      ),
    );
  }
}
