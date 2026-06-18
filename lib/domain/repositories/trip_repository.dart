import '../entities/trip_entity.dart';

/// Gezi planı işlemleri için abstract repository
abstract class TripRepository {
  /// Yeni bir gezi planı oluştur (AI ile)
  Future<TripEntity> generateTrip({
    required String fromCity,
    required String toCity,
    required DateTime startDate,
    required DateTime endDate,
    required int durationDays,
    required List<String> preferences,
    required List<String> waypoints,
    required String userId,
  });

  /// Kullanıcının gezilerini getir
  Future<List<TripEntity>> getUserTrips(String userId);

  /// Belirli bir geziyi ID ile getir
  Future<TripEntity?> getTripById(String tripId);

  /// Geziyi sil
  Future<void> deleteTrip(String tripId);

  /// Firestore'dan realtime trip akışı (generating durumu izleme)
  Stream<TripEntity?> watchTrip(String tripId);

  /// Bir geziyi yeni bir kullanıcı ID'si ile yeni bir belge olarak kopyalar
  Future<void> saveTripAsNew(TripEntity trip, String newUserId);
}
