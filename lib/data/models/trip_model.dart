import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/place_entity.dart';
import '../../domain/entities/trip_entity.dart';

/// Firestore <-> Domain dönüşümü için Place modeli
class PlaceModel extends PlaceEntity {
  const PlaceModel({
    required super.id,
    required super.name,
    required super.description,
    required super.category,
    required super.suggestedDuration,
    super.lat,
    super.lng,
    super.imageUrl,
    super.address,
    super.photoQuery,
    super.city,
  });

  factory PlaceModel.fromMap(Map<String, dynamic> map) {
    return PlaceModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? '',
      suggestedDuration: map['suggestedDuration'] as String? ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      imageUrl: map['imageUrl'] as String?,
      address: map['address'] as String?,
      photoQuery: map['photoQuery'] as String?,
      city: map['city'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'suggestedDuration': suggestedDuration,
      'lat': lat,
      'lng': lng,
      'imageUrl': imageUrl,
      'address': address,
      'photoQuery': photoQuery,
      'city': city,
    };
  }
}

/// Firestore <-> Domain dönüşümü için TripDay modeli
class TripDayModel extends TripDayEntity {
  const TripDayModel({
    required super.dayNumber,
    required super.city,
    required super.places,
  });

  factory TripDayModel.fromMap(Map<String, dynamic> map) {
    final city = map['city'] as String? ?? '';
    final placesList = (map['places'] as List<dynamic>?)
            ?.map((p) {
              final placeMap = Map<String, dynamic>.from(p as Map);
              placeMap['city'] = city; // Güne ait şehir bilgisini mekanlara enjekte et
              return PlaceModel.fromMap(placeMap);
            })
            .toList() ??
        [];
    return TripDayModel(
      dayNumber: map['dayNumber'] as int? ?? 0,
      city: city,
      places: placesList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'city': city,
      'places': places
          .map((p) => PlaceModel(
                id: p.id,
                name: p.name,
                description: p.description,
                category: p.category,
                suggestedDuration: p.suggestedDuration,
                lat: p.lat,
                lng: p.lng,
                imageUrl: p.imageUrl,
                address: p.address,
                photoQuery: p.photoQuery,
                city: p.city,
              ).toMap())
          .toList(),
    };
  }
}

/// Firestore <-> Domain dönüşümü için Trip modeli
class TripModel extends TripEntity {
  const TripModel({
    required super.id,
    required super.userId,
    required super.fromCity,
    required super.toCity,
    required super.startDate,
    required super.endDate,
    required super.durationDays,
    required super.preferences,
    required super.waypoints,
    required super.status,
    required super.days,
    required super.createdAt,
  });

  factory TripModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return TripModel.fromMap({'id': doc.id, ...data});
  }

  factory TripModel.fromMap(Map<String, dynamic> map) {
    final daysList = (map['days'] as List<dynamic>?)
            ?.map((d) => TripDayModel.fromMap(d as Map<String, dynamic>))
            .toList() ??
        [];

    return TripModel(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      fromCity: map['fromCity'] as String? ?? '',
      toCity: map['toCity'] as String? ?? '',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      durationDays: map['durationDays'] as int? ?? 1,
      preferences: List<String>.from(map['preferences'] as List? ?? []),
      waypoints: List<String>.from(map['waypoints'] as List? ?? []),
      status: _parseStatus(map['status'] as String?),
      days: daysList,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'fromCity': fromCity,
      'toCity': toCity,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'durationDays': durationDays,
      'preferences': preferences,
      'waypoints': waypoints,
      'status': status.name,
      'days': days
          .map((d) => TripDayModel(
                dayNumber: d.dayNumber,
                city: d.city,
                places: d.places,
              ).toMap())
          .toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static TripStatus _parseStatus(String? value) {
    switch (value) {
      case 'ready':
        return TripStatus.ready;
      case 'error':
        return TripStatus.error;
      default:
        return TripStatus.generating;
    }
  }
}
