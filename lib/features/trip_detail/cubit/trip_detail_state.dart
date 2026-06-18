import 'package:equatable/equatable.dart';
import '../../../domain/entities/trip_entity.dart';

abstract class TripDetailState extends Equatable {
  const TripDetailState();
  @override
  List<Object?> get props => [];
}

class TripDetailInitial extends TripDetailState {
  const TripDetailInitial();
}

class TripDetailLoading extends TripDetailState {
  const TripDetailLoading();
}

class TripDetailLoaded extends TripDetailState {
  final TripEntity trip;
  const TripDetailLoaded(this.trip);
  @override
  List<Object?> get props => [trip];
}

class TripDetailError extends TripDetailState {
  final String message;
  const TripDetailError(this.message);
  @override
  List<Object?> get props => [message];
}
