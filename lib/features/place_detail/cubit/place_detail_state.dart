import 'package:equatable/equatable.dart';

enum TtsStatus { idle, loading, playing, paused, stopped, error }

class PlaceDetailState extends Equatable {
  final TtsStatus ttsStatus;
  final double ttsProgress;   // 0.0 – 1.0
  final String? ttsError;

  const PlaceDetailState({
    this.ttsStatus = TtsStatus.idle,
    this.ttsProgress = 0.0,
    this.ttsError,
  });

  bool get isPlaying => ttsStatus == TtsStatus.playing;
  bool get isPaused => ttsStatus == TtsStatus.paused;

  PlaceDetailState copyWith({
    TtsStatus? ttsStatus,
    double? ttsProgress,
    String? ttsError,
  }) {
    return PlaceDetailState(
      ttsStatus: ttsStatus ?? this.ttsStatus,
      ttsProgress: ttsProgress ?? this.ttsProgress,
      ttsError: ttsError,
    );
  }

  @override
  List<Object?> get props => [ttsStatus, ttsProgress, ttsError];
}
