/// Mission Providers — Riverpod state management
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/mission_models.dart';
import '../../data/datasources/mission_remote_data_source.dart';
import '../../data/repositories/mission_repository_impl.dart';
import '../../../../../core/providers/core_providers.dart';

// ===== Infrastructure Providers =====

final missionRemoteDataSourceProvider =
    Provider<MissionRemoteDataSource>((ref) {
  return MissionRemoteDataSourceImpl(apiClient: ref.watch(apiClientProvider));
});

final missionRepositoryProvider = Provider<MissionRepositoryImpl>((ref) {
  return MissionRepositoryImpl(
    remoteDataSource: ref.watch(missionRemoteDataSourceProvider),
  );
});

// ===== State =====

class MissionState {
  final List<UserMission> activeMissions;
  final List<UserMission> completedMissions;
  final bool isLoading;
  final String? error;
  final String? updatingId; // mission being updated

  const MissionState({
    this.activeMissions = const [],
    this.completedMissions = const [],
    this.isLoading = false,
    this.error,
    this.updatingId,
  });

  MissionState copyWith({
    List<UserMission>? activeMissions,
    List<UserMission>? completedMissions,
    bool? isLoading,
    String? error,
    String? updatingId,
    bool clearError = false,
    bool clearUpdating = false,
  }) {
    return MissionState(
      activeMissions: activeMissions ?? this.activeMissions,
      completedMissions: completedMissions ?? this.completedMissions,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      updatingId: clearUpdating ? null : (updatingId ?? this.updatingId),
    );
  }

  int get totalXpEarned {
    return completedMissions.fold<int>(
      0,
      (sum, m) => sum + (m.mission?.xpReward ?? 0),
    );
  }
}

// ===== Notifier =====

class MissionNotifier extends StateNotifier<MissionState> {
  final MissionRepositoryImpl _repository;

  MissionNotifier({required MissionRepositoryImpl repository})
      : _repository = repository,
        super(const MissionState());

  Future<void> loadMissions() async {
    state = state.copyWith(isLoading: true, clearError: true);

    // Load active and completed in parallel
    final results = await Future.wait([
      _repository.getActiveMissions(),
      _repository.getCompletedMissions(),
    ]);

    final activeResult = results[0];
    final completedResult = results[1];

    List<UserMission> active = [];
    List<UserMission> completed = [];
    String? error;

    activeResult.map(
      (m) => active = m,
      (f) => error = f.message,
    );
    completedResult.map(
      (m) => completed = m,
      (f) => error ??= f.message,
    );

    state = state.copyWith(
      activeMissions: active,
      completedMissions: completed,
      isLoading: false,
      error: error,
    );
  }

  Future<bool> updateProgress(String userMissionId, int newProgress) async {
    state = state.copyWith(updatingId: userMissionId, clearError: true);

    final result = await _repository.updateProgress(userMissionId, newProgress);
    return result.map(
      (updated) {
        if (updated.isCompleted) {
          // Move from active to completed
          state = state.copyWith(
            activeMissions: state.activeMissions
                .where((m) => m.id != userMissionId)
                .toList(),
            completedMissions: [updated, ...state.completedMissions],
            clearUpdating: true,
          );
        } else {
          // Update in active list
          state = state.copyWith(
            activeMissions: state.activeMissions
                .map((m) => m.id == userMissionId ? updated : m)
                .toList(),
            clearUpdating: true,
          );
        }
        return true;
      },
      (failure) {
        state = state.copyWith(
          error: failure.message,
          clearUpdating: true,
        );
        return false;
      },
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final missionNotifierProvider =
    StateNotifierProvider<MissionNotifier, MissionState>((ref) {
  return MissionNotifier(repository: ref.watch(missionRepositoryProvider));
});

final activeMissionsProvider = Provider<List<UserMission>>((ref) {
  return ref.watch(missionNotifierProvider).activeMissions;
});

final completedMissionsProvider = Provider<List<UserMission>>((ref) {
  return ref.watch(missionNotifierProvider).completedMissions;
});
