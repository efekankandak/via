import '../../domain/entities/trip_entity.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/firebase_trips_datasource.dart';
import '../models/trip_model.dart';

class TripRepositoryImpl implements TripRepository {
  final FirebaseTripsDataSource _dataSource;

  TripRepositoryImpl(this._dataSource);

  @override
  Future<TripEntity> generateTrip({
    required String fromCity,
    required String toCity,
    required DateTime startDate,
    required DateTime endDate,
    required int durationDays,
    required List<String> preferences,
    required List<String> waypoints,
    required String userId,
  }) async {
    return _dataSource.generateTrip(
      fromCity: fromCity,
      toCity: toCity,
      startDate: startDate,
      endDate: endDate,
      durationDays: durationDays,
      preferences: preferences,
      waypoints: waypoints,
      userId: userId,
    );
  }

  @override
  Future<List<TripEntity>> getUserTrips(String userId) async {
    return _dataSource.getUserTrips(userId);
  }

  @override
  Future<TripEntity?> getTripById(String tripId) async {
    return _dataSource.getTripById(tripId);
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    return _dataSource.deleteTrip(tripId);
  }

  @override
  Stream<TripEntity?> watchTrip(String tripId) {
    return _dataSource.watchTrip(tripId);
  }

  @override
  Future<void> saveTripAsNew(TripEntity trip, String newUserId) async {
    if (trip is TripModel) {
      await _dataSource.saveTripAsNew(trip, newUserId);
    } else {
      final model = TripModel(
        id: '',
        userId: newUserId,
        fromCity: trip.fromCity,
        toCity: trip.toCity,
        startDate: trip.startDate,
        endDate: trip.endDate,
        durationDays: trip.durationDays,
        preferences: trip.preferences,
        waypoints: trip.waypoints,
        status: trip.status,
        days: trip.days,
        createdAt: trip.createdAt,
      );
      await _dataSource.saveTripAsNew(model, newUserId);
    }
  }
}
