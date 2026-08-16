/// Mission Card Widget
import 'package:flutter/material.dart';
import '../../../../../core/theme/momo_design_system.dart';
import '../../domain/models/mission_models.dart';

class MissionCard extends StatelessWidget {
  final UserMission userMission;
  final bool isUpdating;
  final VoidCallback? onUpdateProgress;

  const MissionCard({
    Key? key,
    required this.userMission,
    this.isUpdating = false,
    this.onUpdateProgress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mission = userMission.mission;
    if (mission == null) return const SizedBox.shrink();

    final isCompleted = userMission.isCompleted;
    final progress = userMission.progressPercent;
    final categoryColor = Color(MissionCategory.colorValue(mission.category));

    return Container(
      margin: const EdgeInsets.only(bottom: MomoSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MomoRadius.xl),
        border: Border.all(
          color: isCompleted
              ? MomoColors.success.withOpacity(0.3)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(MomoSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(MomoRadius.md),
                  ),
                  child: Center(
                    child: Text(
                      mission.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: MomoSpacing.md),

                // Mission info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              mission.name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: MomoColors.textBlack,
                              ),
                            ),
                          ),
                          // XP badge
                          _XpBadge(xp: mission.xpReward),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: MomoColors.textGray,
                          height: 1.4,
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: MomoSpacing.md),

            // Progress section
            if (isCompleted) ...[
              // Completed state
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MomoSpacing.md,
                  vertical: MomoSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: MomoColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(MomoRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: MomoColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: MomoSpacing.sm),
                    Text(
                      'Selesai! +${mission.xpReward} XP',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: MomoColors.success,
                      ),
                    ),
                    const Spacer(),
                    if (userMission.completedAt != null)
                      Text(
                        _formatDate(userMission.completedAt!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: MomoColors.textGray,
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${userMission.progress} / ${mission.target}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: MomoColors.textGray,
                              ),
                            ),
                            Text(
                              '${(progress * 100).round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: categoryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(MomoRadius.pill),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6,
                            backgroundColor: categoryColor.withOpacity(0.15),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(categoryColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Category label chip
                  const SizedBox(width: MomoSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MomoSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(MomoRadius.pill),
                    ),
                    child: Text(
                      MissionCategory.label(mission.category),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Hari ini';
    if (diff.inDays == 1) return 'Kemarin';
    return '${date.day}/${date.month}';
  }
}

class _XpBadge extends StatelessWidget {
  final int xp;
  const _XpBadge({required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
        ),
        borderRadius: BorderRadius.circular(MomoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 2),
          Text(
            '+$xp XP',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
