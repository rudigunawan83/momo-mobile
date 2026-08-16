/// Mood Page — tampilkan dan rekam mood harian
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../../core/theme/momo_design_system.dart';
import '../../domain/models/mood_models.dart';
import '../providers/mood_providers.dart';
import '../widgets/mood_selector.dart';

class MoodPage extends ConsumerStatefulWidget {
  const MoodPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends ConsumerState<MoodPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(moodNotifierProvider.notifier).loadCurrentMood();
      ref.read(moodNotifierProvider.notifier).loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodNotifierProvider);

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
                  colors: [Color(0xFFFFF0F6), Color(0xFFF7F5EF)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar
                _buildAppBar(context),

                // Scrollable content
                Expanded(
                  child: moodState.isLoading && moodState.history.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: MomoColors.primaryBlue,
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () async {
                            await ref
                                .read(moodNotifierProvider.notifier)
                                .loadCurrentMood();
                            await ref
                                .read(moodNotifierProvider.notifier)
                                .loadHistory();
                          },
                          child: ListView(
                            padding: const EdgeInsets.all(MomoSpacing.lg),
                            children: [
                              // Current mood card
                              _buildCurrentMoodCard(moodState),

                              const SizedBox(height: MomoSpacing.xl),

                              // Stats
                              if (moodState.history.isNotEmpty) ...[
                                _buildMoodStats(moodState.stats),
                                const SizedBox(height: MomoSpacing.xl),
                              ],

                              // History
                              _buildHistorySection(moodState.history),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
                    border: Border.all(color: Colors.white.withOpacity(0.5)),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: MomoColors.textBlack,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: MomoSpacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '😊 Mood Tracker',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: MomoColors.textBlack,
                      ),
                    ),
                    Text(
                      'Bagaimana perasaanmu hari ini?',
                      style: TextStyle(
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

  Widget _buildCurrentMoodCard(MoodState moodState) {
    final currentMood = moodState.currentMood;

    return Container(
      padding: const EdgeInsets.all(MomoSpacing.xl),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MomoRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current mood display
          if (currentMood != null) ...[
            Row(
              children: [
                Text(
                  MoodType.emoji(currentMood.mood),
                  style: const TextStyle(fontSize: 48),
                ),
                const SizedBox(width: MomoSpacing.lg),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      MoodType.label(currentMood.mood),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(MoodType.colorValue(currentMood.mood)),
                      ),
                    ),
                    Text(
                      'Terakhir diperbarui ${_formatTime(currentMood.recordedAt)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MomoColors.textGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: MomoSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(MomoRadius.pill),
              child: LinearProgressIndicator(
                value: currentMood.intensity,
                minHeight: 6,
                backgroundColor: Colors.grey.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color(MoodType.colorValue(currentMood.mood)),
                ),
              ),
            ),
            const SizedBox(height: MomoSpacing.xl),
            const Divider(),
            const SizedBox(height: MomoSpacing.md),
            const Text(
              'Perbarui Mood',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: MomoColors.textBlack,
              ),
            ),
            const SizedBox(height: MomoSpacing.md),
          ] else ...[
            const Text(
              'Gimana perasaanmu sekarang?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MomoColors.textBlack,
              ),
            ),
            const SizedBox(height: MomoSpacing.xl),
          ],

          // Mood selector + save button (stateful)
          _MoodInputSection(
            currentMood: currentMood?.mood,
            isRecording: moodState.isRecording,
            onSave: (mood, intensity) async {
              await ref
                  .read(moodNotifierProvider.notifier)
                  .recordMood(mood: mood, intensity: intensity);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMoodStats(MoodStats stats) {
    return Container(
      padding: const EdgeInsets.all(MomoSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MomoRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📊 Insight 7 Hari Terakhir',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: MomoColors.textBlack,
            ),
          ),
          const SizedBox(height: MomoSpacing.lg),
          Row(
            children: [
              _StatCard(
                label: 'Mood Dominan',
                value: MoodType.emoji(stats.dominantMood),
                sub: MoodType.label(stats.dominantMood),
                color: Color(MoodType.colorValue(stats.dominantMood)),
              ),
              const SizedBox(width: MomoSpacing.md),
              _StatCard(
                label: 'Total Rekaman',
                value: '${stats.totalRecords}',
                sub: 'rekaman mood',
                color: MomoColors.primaryBlue,
              ),
              const SizedBox(width: MomoSpacing.md),
              _StatCard(
                label: 'Rata-rata',
                value: '${(stats.averageIntensity * 100).round()}%',
                sub: 'intensitas',
                color: MomoColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(List<MoodRecord> history) {
    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(MomoSpacing.xl),
          child: Text(
            'Belum ada riwayat mood.\nCatat moodmu setiap hari!',
            textAlign: TextAlign.center,
            style: MomoTypography.bodyMedium.copyWith(
              color: MomoColors.textGray,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Mood',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: MomoColors.textBlack,
          ),
        ),
        const SizedBox(height: MomoSpacing.md),
        ...history.take(14).map((record) => _MoodHistoryItem(record: record)),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return DateFormat('d MMM').format(dt);
  }
}

// ===== Subwidgets =====

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(MomoSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(MomoRadius.lg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: MomoColors.textGray),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(fontSize: 10, color: MomoColors.textGray),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodHistoryItem extends StatelessWidget {
  final MoodRecord record;

  const _MoodHistoryItem({required this.record});

  @override
  Widget build(BuildContext context) {
    final color = Color(MoodType.colorValue(record.mood));
    return Container(
      margin: const EdgeInsets.only(bottom: MomoSpacing.sm),
      padding: const EdgeInsets.all(MomoSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MomoRadius.lg),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Text(
            MoodType.emoji(record.mood),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: MomoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MoodType.label(record.mood),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (record.note != null)
                  Text(
                    record.note!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MomoColors.textGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('HH:mm').format(record.recordedAt),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: MomoColors.textGray,
                ),
              ),
              Text(
                DateFormat('d MMM').format(record.recordedAt),
                style: const TextStyle(
                  fontSize: 11,
                  color: MomoColors.textGrayLight,
                ),
              ),
            ],
          ),
          const SizedBox(width: MomoSpacing.sm),
          // Intensity bar
          SizedBox(
            height: 32,
            width: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MomoRadius.pill),
              child: Column(
                children: [
                  Expanded(
                    flex: ((1 - record.intensity) * 10).round(),
                    child: Container(color: color.withOpacity(0.15)),
                  ),
                  Expanded(
                    flex: (record.intensity * 10).round(),
                    child: Container(color: color),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mood input section: selector + save button (stateful)
class _MoodInputSection extends StatefulWidget {
  final String? currentMood;
  final bool isRecording;
  final Future<void> Function(String mood, double intensity) onSave;

  const _MoodInputSection({
    required this.currentMood,
    required this.isRecording,
    required this.onSave,
  });

  @override
  State<_MoodInputSection> createState() => _MoodInputSectionState();
}

class _MoodInputSectionState extends State<_MoodInputSection> {
  String? _pendingMood;
  double _pendingIntensity = 0.5;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MoodSelectorWidget(
          selectedMood: widget.currentMood,
          onMoodSelected: (mood, intensity) {
            setState(() {
              _pendingMood = mood;
              _pendingIntensity = intensity;
            });
          },
        ),
        const SizedBox(height: MomoSpacing.lg),
        if (_pendingMood != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.isRecording
                  ? null
                  : () async {
                      final mood = _pendingMood!;
                      final intensity = _pendingIntensity;
                      setState(() => _pendingMood = null);
                      await widget.onSave(mood, intensity);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(MoodType.colorValue(_pendingMood!)),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: MomoSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MomoRadius.lg),
                ),
              ),
              child: widget.isRecording
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          MoodType.emoji(_pendingMood!),
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: MomoSpacing.sm),
                        Text(
                          'Simpan — ${MoodType.label(_pendingMood!)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
      ],
    );
  }
}
