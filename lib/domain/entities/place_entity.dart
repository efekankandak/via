import 'package:equatable/equatable.dart';

/// Gezi planındaki bir mekan
class PlaceEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String category;
  final String suggestedDuration; // "2-3 saat"
  final double? lat;
  final double? lng;
  final String? imageUrl;
  final String? address;
  /// Pexels/Wikipedia aramaşı için AI tarafından üretilen İngilizce sorgu
  final String? photoQuery;
  final String? city;

  const PlaceEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.suggestedDuration,
    this.lat,
    this.lng,
    this.imageUrl,
    this.address,
    this.photoQuery,
    this.city,
  });

  @override
  List<Object?> get props => [
        id, name, description, category,
        suggestedDuration, lat, lng, imageUrl, address, photoQuery, city,
      ];
}
