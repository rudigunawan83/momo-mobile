/// Mission Page — tampilkan misi aktif dan selesai
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../../core/theme/momo_design_system.dart';
import '../providers/mission_providers.dart';
import '../widgets/mission_card.dart';

class MissionPage extends ConsumerStatefulWidget {
  const MissionPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MissionPage> createState() => _MissionPageState();
}

class _MissionPageState extends ConsumerState<MissionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(missionNotifierProvider.notifier).loadMissions();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final missionState = ref.watch(missionNotifierProvider);

    return Scaffold(
      backgroundColor: MomoColors.backgroundLight,
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFEFF8FF), Color(0xFFF7F5EF)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar
                _buildAppBar(context, missionState),

                // TabBar
                _buildTabBar(),

                // Content
                Expanded(
                  child: missionState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: MomoColors.primaryBlue,
                          ),
                        )
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildActiveMissions(missionState),
                            _buildCompletedMissions(missionState),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MissionState state) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            MomoSpacing.lg,
            MomoSpacing.lg,
            MomoSpacing.lg,
            MomoSpacing.md,
          ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🎯 Misi Momo',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: MomoColors.textBlack,
                      ),
                    ),
                    Text(
                      '${state.activeMissions.length} aktif · ${state.completedMissions.length} selesai',
                      style: const TextStyle(
                        fontSize: 12,
                        color: MomoColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              // Total XP earned badge
              if (state.totalXpEarned > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MomoSpacing.md,
                    vertical: MomoSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                    ),
                    borderRadius: BorderRadius.circular(MomoRadius.pill),
                  ),
                  child: Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 4),
                      Text(
                        '${state.totalXpEarned} XP',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: MomoColors.primaryBlue,
        unselectedLabelColor: MomoColors.textGray,
        indicatorColor: MomoColors.primaryBlue,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flag_rounded, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Aktif (${ref.watch(activeMissionsProvider).length})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Selesai (${ref.watch(completedMissionsProvider).length})',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveMissions(MissionState state) {
    if (state.activeMissions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(MomoSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: MomoSpacing.xl),
              const Text(
                'Semua misi selesai!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: MomoColors.textBlack,
                ),
              ),
              const SizedBox(height: MomoSpacing.sm),
              Text(
                'Kamu luar biasa! Terus ngobrol\ndengan Momo untuk misi baru.',
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

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(missionNotifierProvider.notifier).loadMissions(),
      child: ListView.builder(
        padding: const EdgeInsets.all(MomoSpacing.lg),
        itemCount: state.activeMissions.length,
        itemBuilder: (ctx, i) {
          final mission = state.activeMissions[i];
          return MissionCard(
            userMission: mission,
            isUpdating: state.updatingId == mission.id,
          );
        },
      ),
    );
  }

  Widget _buildCompletedMissions(MissionState state) {
    if (state.completedMissions.isEmpty) {
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
                  color: MomoColors.primaryBlue.withOpacity(0.1),
                ),
                child: const Center(
                  child: Text('🏆', style: TextStyle(fontSize: 36)),
                ),
              ),
              const SizedBox(height: MomoSpacing.xl),
              const Text(
                'Belum ada misi selesai',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MomoColors.textBlack,
                ),
              ),
              const SizedBox(height: MomoSpacing.sm),
              Text(
                'Selesaikan misi aktifmu dan\nkumpulkan XP untuk naik level!',
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

    return ListView.builder(
      padding: const EdgeInsets.all(MomoSpacing.lg),
      itemCount: state.completedMissions.length,
      itemBuilder: (ctx, i) {
        return MissionCard(userMission: state.completedMissions[i]);
      },
    );
  }
}
