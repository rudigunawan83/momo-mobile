/// Memory Page — tampilkan memori Momo tentang user
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../../core/theme/momo_design_system.dart';
import '../../domain/models/memory_models.dart';
import '../providers/memory_providers.dart';
import '../widgets/memory_card.dart';

class MemoryPage extends ConsumerStatefulWidget {
  const MemoryPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends ConsumerState<MemoryPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(memoryNotifierProvider.notifier).loadMemories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MemoryModel> _filterSearch(List<MemoryModel> memories) {
    if (_searchQuery.isEmpty) return memories;
    final q = _searchQuery.toLowerCase();
    return memories
        .where(
          (m) =>
              m.summary.toLowerCase().contains(q) ||
              m.content.toLowerCase().contains(q) ||
              m.tags.any((t) => t.toLowerCase().contains(q)),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final memoryState = ref.watch(memoryNotifierProvider);
    final filtered = _filterSearch(memoryState.filteredMemories);

    return Scaffold(
      backgroundColor: MomoColors.backgroundLight,
      body: Stack(
        children: [
          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEEF4FF), Color(0xFFF7F5EF)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar
                _buildAppBar(context, memoryState.memories.length),

                // Filter chips
                _buildFilterChips(memoryState.selectedType),

                // Search bar
                _buildSearchBar(),

                // Content
                Expanded(
                  child: memoryState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: MomoColors.primaryBlue,
                          ),
                        )
                      : filtered.isEmpty
                          ? _buildEmptyState(memoryState.selectedType)
                          : _buildMemoryList(filtered),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar(BuildContext context, int totalCount) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(MomoSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.5),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: MomoColors.textBlack,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: MomoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🧠 Memori Momo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: MomoColors.textBlack,
                      ),
                    ),
                    Text(
                      '$totalCount kenangan tersimpan',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MomoColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(String selectedType) {
    final types = ['All', ...MemoryType.all];
    return Container(
      height: 44,
      color: Colors.white.withOpacity(0.5),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: MomoSpacing.lg,
          vertical: MomoSpacing.sm,
        ),
        itemCount: types.length,
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = selectedType == type;
          return GestureDetector(
            onTap: () {
              ref.read(memoryNotifierProvider.notifier).setFilter(type);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: MomoSpacing.sm),
              padding: const EdgeInsets.symmetric(
                horizontal: MomoSpacing.md,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? MomoColors.primaryBlue
                    : Colors.white,
                borderRadius: BorderRadius.circular(MomoRadius.pill),
                border: Border.all(
                  color: isSelected
                      ? MomoColors.primaryBlue
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Text(
                type == 'All'
                    ? '🌟 Semua'
                    : '${MemoryType.emoji(type)} ${MemoryType.label(type)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : MomoColors.textGray,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MomoSpacing.lg,
        MomoSpacing.md,
        MomoSpacing.lg,
        0,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MomoRadius.lg),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Cari kenangan...',
            hintStyle: const TextStyle(color: MomoColors.textGrayLight),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: MomoColors.textGrayLight,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: MomoColors.textGrayLight,
                      size: 18,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildMemoryList(List<MemoryModel> memories) {
    return ListView.builder(
      padding: const EdgeInsets.all(MomoSpacing.lg),
      itemCount: memories.length,
      itemBuilder: (context, index) {
        final memory = memories[index];
        return MemoryCard(
          memory: memory,
          onToggleFavorite: () {
            ref
                .read(memoryNotifierProvider.notifier)
                .toggleFavorite(memory.id, !memory.isFavorite);
          },
          onDelete: () => _confirmDelete(memory),
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    final isEmpty = type == 'All';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MomoSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    MomoColors.primaryBlue.withOpacity(0.15),
                    MomoColors.primaryBlue.withOpacity(0.05),
                  ],
                ),
              ),
              child: const Center(
                child: Text('🧠', style: TextStyle(fontSize: 36)),
              ),
            ),
            const SizedBox(height: MomoSpacing.xl),
            Text(
              isEmpty ? 'Belum ada kenangan' : 'Tidak ada kenangan di kategori ini',
              style: MomoTypography.headlineMedium,
            ),
            const SizedBox(height: MomoSpacing.sm),
            Text(
              isEmpty
                  ? 'Mulai ngobrol dengan Momo, dan\ndia akan mengingat hal-hal penting!'
                  : 'Coba kategori lain atau mulai percakapan baru',
              textAlign: TextAlign.center,
              style: MomoTypography.bodyMedium.copyWith(
                color: MomoColors.textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _showAddMemoryDialog,
      backgroundColor: MomoColors.primaryBlue,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text(
        'Tambah Memori',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _confirmDelete(MemoryModel memory) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MomoRadius.xl),
        ),
        title: const Text('Hapus Kenangan?'),
        content: Text(
          '"${memory.summary}" akan dihapus permanen.',
          style: MomoTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(memoryNotifierProvider.notifier)
                  .deleteMemory(memory.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MomoColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MomoRadius.md),
              ),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAddMemoryDialog() {
    final summaryCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedType = MemoryType.general;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(MomoRadius.xxl),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(MomoSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(MomoRadius.pill),
                    ),
                  ),
                ),
                const SizedBox(height: MomoSpacing.xl),
                const Text(
                  'Tambah Kenangan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: MomoColors.textBlack,
                  ),
                ),
                const SizedBox(height: MomoSpacing.lg),
                _buildTextField(summaryCtrl, 'Ringkasan singkat'),
                const SizedBox(height: MomoSpacing.md),
                _buildTextField(contentCtrl, 'Detail kenangan', maxLines: 3),
                const SizedBox(height: MomoSpacing.md),
                Wrap(
                  spacing: MomoSpacing.sm,
                  children: MemoryType.all.map((type) {
                    final selected = selectedType == type;
                    return FilterChip(
                      selected: selected,
                      label: Text(
                        '${MemoryType.emoji(type)} ${MemoryType.label(type)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: selected
                              ? Colors.white
                              : MomoColors.textGray,
                        ),
                      ),
                      selectedColor: MomoColors.primaryBlue,
                      checkmarkColor: Colors.white,
                      onSelected: (_) =>
                          setSheetState(() => selectedType = type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: MomoSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (summaryCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      await ref.read(memoryNotifierProvider.notifier).createMemory(
                        CreateMemoryRequest(
                          summary: summaryCtrl.text.trim(),
                          content: contentCtrl.text.trim(),
                          type: selectedType,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MomoColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: MomoSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MomoRadius.lg),
                      ),
                    ),
                    child: const Text(
                      'Simpan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: MomoColors.backgroundLight,
        borderRadius: BorderRadius.circular(MomoRadius.md),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: MomoColors.textGrayLight),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(MomoSpacing.md),
        ),
      ),
    );
  }
}
