/// Memory Providers — Riverpod state management
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/memory_models.dart';
import '../../data/datasources/memory_remote_data_source.dart';
import '../../data/repositories/memory_repository_impl.dart';
import '../../../../../core/providers/core_providers.dart';

// ===== Infrastructure Providers =====

final memoryRemoteDataSourceProvider = Provider<MemoryRemoteDataSource>((ref) {
  return MemoryRemoteDataSourceImpl(apiClient: ref.watch(apiClientProvider));
});

final memoryRepositoryProvider = Provider<MemoryRepositoryImpl>((ref) {
  return MemoryRepositoryImpl(
    remoteDataSource: ref.watch(memoryRemoteDataSourceProvider),
  );
});

// ===== State =====

class MemoryState {
  final List<MemoryModel> memories;
  final bool isLoading;
  final String? error;
  final String selectedType; // 'All' or specific type

  const MemoryState({
    this.memories = const [],
    this.isLoading = false,
    this.error,
    this.selectedType = 'All',
  });

  MemoryState copyWith({
    List<MemoryModel>? memories,
    bool? isLoading,
    String? error,
    String? selectedType,
    bool clearError = false,
  }) {
    return MemoryState(
      memories: memories ?? this.memories,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      selectedType: selectedType ?? this.selectedType,
    );
  }

  List<MemoryModel> get filteredMemories {
    if (selectedType == 'All') return memories;
    return memories.where((m) => m.type == selectedType).toList();
  }

  List<MemoryModel> get favoriteMemories {
    return memories.where((m) => m.isFavorite).toList();
  }
}

// ===== Notifier =====

class MemoryNotifier extends StateNotifier<MemoryState> {
  final MemoryRepositoryImpl _repository;

  MemoryNotifier({required MemoryRepositoryImpl repository})
      : _repository = repository,
        super(const MemoryState());

  Future<void> loadMemories() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final result = await _repository.getMemories();
    result.map(
      (memories) {
        // Sort: newest first
        final sorted = [...memories]
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = state.copyWith(memories: sorted, isLoading: false);
      },
      (failure) => state = state.copyWith(
        isLoading: false,
        error: failure.message,
      ),
    );
  }

  Future<bool> createMemory(CreateMemoryRequest request) async {
    final result = await _repository.createMemory(request);
    return result.map(
      (memory) {
        state = state.copyWith(memories: [memory, ...state.memories]);
        return true;
      },
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
    );
  }

  Future<bool> deleteMemory(String id) async {
    final result = await _repository.deleteMemory(id);
    return result.map(
      (_) {
        state = state.copyWith(
          memories: state.memories.where((m) => m.id != id).toList(),
        );
        return true;
      },
      (failure) {
        state = state.copyWith(error: failure.message);
        return false;
      },
    );
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    // Optimistic update
    state = state.copyWith(
      memories: state.memories
          .map((m) => m.id == id ? m.copyWith(isFavorite: isFavorite) : m)
          .toList(),
    );

    final result = await _repository.toggleFavorite(id, isFavorite);
    result.map(
      (updated) {
        state = state.copyWith(
          memories: state.memories
              .map((m) => m.id == id ? updated : m)
              .toList(),
        );
      },
      (failure) {
        // Revert optimistic update
        state = state.copyWith(
          memories: state.memories
              .map((m) => m.id == id ? m.copyWith(isFavorite: !isFavorite) : m)
              .toList(),
          error: failure.message,
        );
      },
    );
  }

  void setFilter(String type) {
    state = state.copyWith(selectedType: type);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

final memoryNotifierProvider =
    StateNotifierProvider<MemoryNotifier, MemoryState>((ref) {
  return MemoryNotifier(repository: ref.watch(memoryRepositoryProvider));
});

final memoriesProvider = Provider<List<MemoryModel>>((ref) {
  return ref.watch(memoryNotifierProvider).filteredMemories;
});
