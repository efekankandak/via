import 'package:equatable/equatable.dart';

enum PlannerStep { citySelection, dateSelection, preferences, waypoints }

class TripPlannerState extends Equatable {
  final PlannerStep currentStep;
  final String fromCity;
  final String toCity;
  final DateTime? startDate;
  final DateTime? endDate;
  final int durationDays;
  final List<String> selectedPreferences;
  final List<String> waypoints;
  final bool isGenerating;
  final String? generatingTripId;
  final String? errorMessage;

  const TripPlannerState({
    this.currentStep = PlannerStep.citySelection,
    this.fromCity = '',
    this.toCity = '',
    this.startDate,
    this.endDate,
    this.durationDays = 3,
    this.selectedPreferences = const [],
    this.waypoints = const [],
    this.isGenerating = false,
    this.generatingTripId,
    this.errorMessage,
  });

  bool get canProceedStep1 => fromCity.isNotEmpty && toCity.isNotEmpty;
  bool get canProceedStep2 => startDate != null && endDate != null;
  bool get canProceedStep3 => selectedPreferences.isNotEmpty;

  TripPlannerState copyWith({
    PlannerStep? currentStep,
    String? fromCity,
    String? toCity,
    DateTime? startDate,
    DateTime? endDate,
    int? durationDays,
    List<String>? selectedPreferences,
    List<String>? waypoints,
    bool? isGenerating,
    String? generatingTripId,
    String? errorMessage,
  }) {
    return TripPlannerState(
      currentStep: currentStep ?? this.currentStep,
      fromCity: fromCity ?? this.fromCity,
      toCity: toCity ?? this.toCity,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      durationDays: durationDays ?? this.durationDays,
      selectedPreferences: selectedPreferences ?? this.selectedPreferences,
      waypoints: waypoints ?? this.waypoints,
      isGenerating: isGenerating ?? this.isGenerating,
      generatingTripId: generatingTripId ?? this.generatingTripId,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        currentStep, fromCity, toCity, startDate, endDate,
        durationDays, selectedPreferences, waypoints,
        isGenerating, generatingTripId, errorMessage,
      ];
}
