import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/firebase_trips_datasource.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/repositories/trip_repository.dart';
import '../services/weather_service.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // ── Firebase & External ──────────────────────────────────────
  getIt.registerLazySingleton<FirebaseFirestore>(
    () => FirebaseFirestore.instance,
  );
  getIt.registerLazySingleton<FirebaseAuth>(
    () => FirebaseAuth.instance,
  );
  getIt.registerLazySingleton<FirebaseFunctions>(
    () => FirebaseFunctions.instance,
  );
  getIt.registerLazySingleton<Dio>(
    () => Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
    )),
  );
  getIt.registerLazySingleton<WeatherService>(
    () => WeatherService(dio: getIt<Dio>()),
  );

  // ── Data Sources ─────────────────────────────────────────────
  getIt.registerLazySingleton<FirebaseTripsDataSource>(
    () => FirebaseTripsDataSource(
      firestore: getIt<FirebaseFirestore>(),
      functions: getIt<FirebaseFunctions>(),
    ),
  );

  // ── Repositories ─────────────────────────────────────────────
  getIt.registerLazySingleton<TripRepository>(
    () => TripRepositoryImpl(getIt<FirebaseTripsDataSource>()),
  );
}
