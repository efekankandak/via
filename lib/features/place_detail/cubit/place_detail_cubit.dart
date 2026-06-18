import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'place_detail_state.dart';

class PlaceDetailCubit extends Cubit<PlaceDetailState> {
  final FlutterTts _tts;
  String? _currentText;

  PlaceDetailCubit({FlutterTts? tts})
      : _tts = tts ?? FlutterTts(),
        super(const PlaceDetailState()) {
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setStartHandler(() {
      if (!isClosed) emit(state.copyWith(ttsStatus: TtsStatus.playing));
    });

    _tts.setCompletionHandler(() {
      if (!isClosed) {
        emit(state.copyWith(
          ttsStatus: TtsStatus.stopped,
          ttsProgress: 1.0,
        ));
      }
    });

    _tts.setErrorHandler((msg) {
      if (!isClosed) {
        emit(state.copyWith(
          ttsStatus: TtsStatus.error,
          ttsError: 'Sesli anlatım başlatılamadı.',
        ));
      }
    });

    _tts.setProgressHandler((text, start, end, word) {
      if (!isClosed && _currentText != null && _currentText!.isNotEmpty) {
        final progress = end / _currentText!.length;
        emit(state.copyWith(ttsProgress: progress.clamp(0.0, 1.0)));
      }
    });
  }

  Future<void> speak(String text) async {
    _currentText = text;
    emit(state.copyWith(
      ttsStatus: TtsStatus.loading,
      ttsProgress: 0.0,
    ));
    await _tts.speak(text);
  }

  Future<void> pause() async {
    await _tts.pause();
    emit(state.copyWith(ttsStatus: TtsStatus.paused));
  }

  Future<void> resume() async {
    await _tts.speak(_currentText ?? '');
  }

  Future<void> stop() async {
    await _tts.stop();
    emit(state.copyWith(
      ttsStatus: TtsStatus.stopped,
      ttsProgress: 0.0,
    ));
  }

  Future<void> togglePlayPause(String text) async {
    if (state.isPlaying) {
      await pause();
    } else if (state.isPaused) {
      await resume();
    } else {
      await speak(text);
    }
  }

  @override
  Future<void> close() async {
    await _tts.stop();
    return super.close();
  }
}
