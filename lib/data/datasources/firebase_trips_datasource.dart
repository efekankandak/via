import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/constants/app_constants.dart';
import '../models/trip_model.dart';

/// Firebase ile gezi planı oluşturma ve okuma işlemleri
class FirebaseTripsDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  FirebaseTripsDataSource({
    required FirebaseFirestore firestore,
    required FirebaseFunctions functions,
  })  : _firestore = firestore,
        _functions = functions;

  CollectionReference<Map<String, dynamic>> get _tripsRef =>
      _firestore.collection(AppConstants.tripsCollection);

  /// AI ile gezi planı oluştur (Firebase Function'ı çağırır)
  Future<TripModel> generateTrip({
    required String fromCity,
    required String toCity,
    required DateTime startDate,
    required DateTime endDate,
    required int durationDays,
    required List<String> preferences,
    required List<String> waypoints,
    required String userId,
  }) async {
    // 1. Firestore'da "generating" durumunda bir belge oluştur
    final docRef = await _tripsRef.add({
      'userId': userId,
      'fromCity': fromCity,
      'toCity': toCity,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'durationDays': durationDays,
      'preferences': preferences,
      'waypoints': waypoints,
      'status': 'generating',
      'days': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    final tripId = docRef.id;

    try {
      // 2. Firebase Function'ı arka planda çağır (Gemini AI plan üretimi)
      // Timeout süresini 300 saniye (5 dakika) olarak ayarlıyoruz ki yarıda kesilmesin.
      final callable = _functions.httpsCallable(
        'generateTrip',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 300)),
      );
      
      // Arka planda çalışması için await etmiyoruz (fire-and-forget).
      // Eğer bir hata oluşursa Firestore durumunu 'error' yapıyoruz.
      () async {
        try {
          await callable.call({
            'tripId': tripId,
            'fromCity': fromCity,
            'toCity': toCity,
            'startDate': startDate.toIso8601String(),
            'endDate': endDate.toIso8601String(),
            'durationDays': durationDays,
            'preferences': preferences,
            'waypoints': waypoints,
          });
        } catch (e) {
          // ignore: avoid_print
          print('Arka planda plan oluşturulurken hata oluştu: $e');
        }
      }();

      // 3. Firestore'da oluşturduğumuz geçici belgeyi hemen geri dönüyoruz.
      // Durumu 'generating' olacağı için UI otomatik olarak yükleme ekranına geçecektir.
      final doc = await _tripsRef.doc(tripId).get();
      return TripModel.fromFirestore(doc);
    } catch (e) {
      await _tripsRef.doc(tripId).update({'status': 'error'});
      rethrow;
    }
  }

  /// Kullanıcının tüm gezilerini getir
  Future<List<TripModel>> getUserTrips(String userId) async {
    final snapshot = await _tripsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map(TripModel.fromFirestore).toList();
  }

  /// ID ile gezi getir
  Future<TripModel?> getTripById(String tripId) async {
    final doc = await _tripsRef.doc(tripId).get();
    if (!doc.exists) return null;
    return TripModel.fromFirestore(doc);
  }

  /// Geziyi sil
  Future<void> deleteTrip(String tripId) async {
    await _tripsRef.doc(tripId).delete();
  }

  /// Gezi durumunu realtime izle (generating → ready geçişini yakala)
  Stream<TripModel?> watchTrip(String tripId) {
    return _tripsRef.doc(tripId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TripModel.fromFirestore(doc);
    });
  }

  /// Geziyi yeni bir kullanıcı ID'si ile yeni bir belge olarak Firestore'a kaydeder
  Future<void> saveTripAsNew(TripModel trip, String newUserId) async {
    final tripMap = trip.toMap();
    tripMap['userId'] = newUserId;
    tripMap['createdAt'] = FieldValue.serverTimestamp();
    await _tripsRef.add(tripMap);
  }
}
