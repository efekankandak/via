import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/trip_repository.dart';
import 'trip_detail_state.dart';

class TripDetailCubit extends Cubit<TripDetailState> {
  final TripRepository _tripRepository;
  StreamSubscription? _tripSubscription;

  TripDetailCubit({required TripRepository tripRepository})
      : _tripRepository = tripRepository,
        super(const TripDetailInitial());

  /// Tek seferlik gezi yükle
  Future<void> loadTrip(String tripId) async {
    emit(const TripDetailLoading());
    try {
      final trip = await _tripRepository.getTripById(tripId);
      if (trip == null) {
        emit(const TripDetailError('Gezi bulunamadı.'));
        return;
      }
      emit(TripDetailLoaded(trip));
    } catch (e) {
      emit(TripDetailError(e.toString()));
    }
  }

  /// Realtime izleme (generating ekranı için)
  void watchTrip(String tripId) {
    emit(const TripDetailLoading());
    _tripSubscription?.cancel();
    _tripSubscription = _tripRepository.watchTrip(tripId).listen(
      (trip) {
        if (trip == null) {
          emit(const TripDetailError('Gezi bulunamadı.'));
          return;
        }
        if (trip.hasError) {
          emit(const TripDetailError(
            'Plan oluşturulamadı. Lütfen tekrar deneyin.',
          ));
          return;
        }
        emit(TripDetailLoaded(trip));
      },
      onError: (e) {
        emit(TripDetailError(e.toString()));
      },
    );
  }

  @override
  Future<void> close() {
    _tripSubscription?.cancel();
    return super.close();
  }
}
