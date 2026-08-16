/// Mood Providers — Riverpod state management
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/mood_models.dart';
import '../../data/datasources/mood_remote_data_source.dart';
import '../../data/repositories/mood_repository_impl.dart';
import '../../../../../core/providers/core_providers.dart';

// ===== Infrastructure Providers =====

final moodRemoteDataSourceProvider = Provider<MoodRemoteDataSource>((ref) {
  return MoodRemoteDataSourceImpl(apiClient: ref.watch(apiClientProvider));
});

final moodRepositoryProvider = Provider<MoodRepositoryImpl>((ref) {
  return MoodRepositoryImpl(
    remoteDataSource: ref.watch(moodRemoteDataSourceProvider),
  );
});

// ===== State =====

class MoodState {
  final MoodRecord? currentMood;
  final List<MoodRecord> history;
  final bool isLoading;
  final bool isRecording;
  final String? error;

  const MoodState({
    this.currentMood,
    this.history = const [],
    this.isLoading = false,
    this.isRecording = false,
    this.error,
  });

  MoodState copyWith({
    MoodRecord? currentMood,
    List<MoodRecord>? history,
    bool? isLoading,
    bool? isRecording,
    String? error,
    bool clearError = false,
    bool clearCurrentMood = false,
  }) {
    return MoodState(
      currentMood: clearCurrentMood ? null : (currentMood ?? this.currentMood),
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isRecording: isRecording ?? this.isRecording,
      error: clearError ? null : (error ?? this.error),
    );
  }

  MoodStats get stats => MoodStats.fromRecords(history);
}

// ===== Notifier =====

class MoodNotifier extends StateNotifier<MoodState> {
  final MoodRepositoryImpl _repository;

  MoodNotifier({required MoodRepositoryImpl repository})
      : _repository = repository,
        super(const MoodState());

  Future<void> loadCurrentMood() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getCurrentMood();
    result.map(
      (mood) => state = state.copyWith(
        currentMood: mood,
        isLoading: false,
        clearCurrentMood: mood == null,
      ),
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
    );
  }

  Future<void> loadHistory({int days = 7}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getMoodHistory(days: days);
    result.map(
      (history) {
        final sorted = [...history]
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
        state = state.copyWith(history: sorted, isLoading: false);
      },
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
    );
  }

  Future<bool> recordMood({
    required String mood,
    double intensity = 0.5,
    String? note,
  }) async {
    state = state.copyWith(isRecording: true, clearError: true);
    final result = await _repository.recordMood(
      mood: mood,
      intensity: intensity,
      note: note,
    );
    return result.map(
      (record) {
        state = state.copyWith(
          currentMood: record,
          history: [record, ...state.history],
          isRecording: false,
        );
        return true;
      },
      (failure) {
        state = state.copyWith(isRecording: false, error: failure.message);
        return false;
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final moodNotifierProvider =
    StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  return MoodNotifier(repository: ref.watch(moodRepositoryProvider));
});

final currentMoodProvider = Provider<MoodRecord?>((ref) {
  return ref.watch(moodNotifierProvider).currentMood;
});

final moodHistoryProvider = Provider<List<MoodRecord>>((ref) {
  return ref.watch(moodNotifierProvider).history;
});

final moodStatsProvider = Provider<MoodStats>((ref) {
  return ref.watch(moodNotifierProvider).stats;
});
