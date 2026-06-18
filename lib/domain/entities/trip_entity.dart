import 'package:equatable/equatable.dart';
import 'place_entity.dart';

/// Günlük gezi planı
class TripDayEntity extends Equatable {
  final int dayNumber;
  final String city;
  final List<PlaceEntity> places;

  const TripDayEntity({
    required this.dayNumber,
    required this.city,
    required this.places,
  });

  @override
  List<Object?> get props => [dayNumber, city, places];
}

/// Ana gezi planı entity'si
class TripEntity extends Equatable {
  final String id;
  final String userId;
  final String fromCity;
  final String toCity;
  final DateTime startDate;
  final DateTime endDate;
  final int durationDays;
  final List<String> preferences;
  final List<String> waypoints;  // Yol üstü şehirler
  final TripStatus status;
  final List<TripDayEntity> days;
  final DateTime createdAt;

  const TripEntity({
    required this.id,
    required this.userId,
    required this.fromCity,
    required this.toCity,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.preferences,
    required this.waypoints,
    required this.status,
    required this.days,
    required this.createdAt,
  });

  bool get isReady => status == TripStatus.ready;
  bool get isGenerating => status == TripStatus.generating;
  bool get hasError => status == TripStatus.error;

  @override
  List<Object?> get props => [
        id, userId, fromCity, toCity, startDate, endDate,
        durationDays, preferences, waypoints, status, days, createdAt,
      ];
}

enum TripStatus {
  generating,
  ready,
  error,
}
