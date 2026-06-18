import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/repositories/trip_repository.dart';
import 'trip_planner_state.dart';

class TripPlannerCubit extends Cubit<TripPlannerState> {
  final TripRepository _tripRepository;
  final FirebaseAuth _auth;

  TripPlannerCubit({
    required TripRepository tripRepository,
    required FirebaseAuth auth,
  })  : _tripRepository = tripRepository,
        _auth = auth,
        super(const TripPlannerState());

  // ── Adım navigasyonu ────────────────────────────────────────
  void goToStep(PlannerStep step) {
    emit(state.copyWith(currentStep: step));
  }

  void nextStep() {
    final steps = PlannerStep.values;
    final currentIndex = steps.indexOf(state.currentStep);
    if (currentIndex < steps.length - 1) {
      emit(state.copyWith(currentStep: steps[currentIndex + 1]));
    }
  }

  void previousStep() {
    final steps = PlannerStep.values;
    final currentIndex = steps.indexOf(state.currentStep);
    if (currentIndex > 0) {
      emit(state.copyWith(currentStep: steps[currentIndex - 1]));
    }
  }

  // ── Form güncelleme ─────────────────────────────────────────
  void setFromCity(String city) {
    emit(state.copyWith(fromCity: city));
  }

  void setToCity(String city) {
    emit(state.copyWith(toCity: city));
  }

  void setDateRange(DateTime start, DateTime end) {
    final days = end.difference(start).inDays + 1;
    emit(state.copyWith(
      startDate: start,
      endDate: end,
      durationDays: days.clamp(
        AppConstants.minTripDays,
        AppConstants.maxTripDays,
      ),
    ));
  }

  void togglePreference(String preference) {
    final current = List<String>.from(state.selectedPreferences);
    if (current.contains(preference)) {
      current.remove(preference);
    } else {
      current.add(preference);
    }
    emit(state.copyWith(selectedPreferences: current));
  }

  void addWaypoint(String city) {
    if (city.isEmpty || state.waypoints.contains(city)) return;
    final updated = [...state.waypoints, city];
    emit(state.copyWith(waypoints: updated));
  }

  void removeWaypoint(String city) {
    final updated = state.waypoints.where((w) => w != city).toList();
    emit(state.copyWith(waypoints: updated));
  }

  // ── Plan üretimi ─────────────────────────────────────────────
  Future<String?> generateTrip() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;
    if (state.startDate == null || state.endDate == null) return null;

    emit(state.copyWith(isGenerating: true, errorMessage: null));

    try {
      final trip = await _tripRepository.generateTrip(
        fromCity: state.fromCity,
        toCity: state.toCity,
        startDate: state.startDate!,
        endDate: state.endDate!,
        durationDays: state.durationDays,
        preferences: state.selectedPreferences,
        waypoints: state.waypoints,
        userId: userId,
      );

      emit(state.copyWith(
        isGenerating: false,
        generatingTripId: trip.id,
      ));

      return trip.id;
    } catch (e) {
      emit(state.copyWith(
        isGenerating: false,
        errorMessage: 'Plan oluşturulamadı. Lütfen tekrar deneyin.',
      ));
      return null;
    }
  }

  void reset() {
    emit(const TripPlannerState());
  }
}
