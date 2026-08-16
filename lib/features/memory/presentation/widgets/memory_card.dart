/// Memory Card Widget
import 'package:flutter/material.dart';
import '../../../../../core/theme/momo_design_system.dart';
import '../../domain/models/memory_models.dart';

class MemoryCard extends StatelessWidget {
  final MemoryModel memory;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;

  const MemoryCard({
    Key? key,
    required this.memory,
    this.onTap,
    this.onDelete,
    this.onToggleFavorite,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: MomoSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MomoRadius.lg),
          border: Border.all(
            color: memory.isFavorite
                ? MomoColors.primaryBlue.withOpacity(0.3)
                : Colors.grey.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: type badge + favorite + date
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MomoSpacing.lg,
                MomoSpacing.md,
                MomoSpacing.sm,
                0,
              ),
              child: Row(
                children: [
                  _TypeBadge(type: memory.type),
                  const Spacer(),
                  // Importance dots
                  _ImportanceIndicator(score: memory.importanceScore),
                  const SizedBox(width: MomoSpacing.sm),
                  // Favorite button
                  GestureDetector(
                    onTap: onToggleFavorite,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        memory.isFavorite
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        key: ValueKey(memory.isFavorite),
                        color: memory.isFavorite
                            ? MomoColors.primaryBlue
                            : MomoColors.textGrayLight,
                        size: 20,
                      ),
                    ),
                  ),
                  // Delete button
                  if (onDelete != null)
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: MomoColors.textGrayLight,
                        size: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(MomoRadius.md),
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.delete_outline_rounded,
                                color: MomoColors.error,
                                size: 18,
                              ),
                              const SizedBox(width: MomoSpacing.sm),
                              Text(
                                'Hapus',
                                style: MomoTypography.bodyMedium.copyWith(
                                  color: MomoColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'delete') onDelete?.call();
                      },
                    ),
                ],
              ),
            ),

            // Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MomoSpacing.lg,
                MomoSpacing.sm,
                MomoSpacing.lg,
                0,
              ),
              child: Text(
                memory.summary,
                style: MomoTypography.headlineSmall.copyWith(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Content preview
            if (memory.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MomoSpacing.lg,
                  MomoSpacing.xs,
                  MomoSpacing.lg,
                  0,
                ),
                child: Text(
                  memory.content,
                  style: MomoTypography.bodyMedium.copyWith(
                    color: MomoColors.textGray,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Tags + date
            Padding(
              padding: const EdgeInsets.all(MomoSpacing.md),
              child: Row(
                children: [
                  if (memory.tags.isNotEmpty) ...[
                    ...memory.tags.take(2).map((tag) => _TagChip(tag: tag)),
                    if (memory.tags.length > 2)
                      _TagChip(tag: '+${memory.tags.length - 2}'),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(memory.occurredAt),
                    style: MomoTypography.labelSmall,
                  ),
                ],
              ),
            ),
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
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bulan lalu';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MomoSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: MomoColors.primaryBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(MomoRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(MemoryType.emoji(type), style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 3),
          Text(
            MemoryType.label(type),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: MomoColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportanceIndicator extends StatelessWidget {
  final double score;
  const _ImportanceIndicator({required this.score});

  @override
  Widget build(BuildContext context) {
    final filled = (score * 3).round().clamp(0, 3);
    return Row(
      children: List.generate(3, (i) {
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < filled
                ? MomoColors.primaryBlue
                : MomoColors.primaryBlue.withOpacity(0.2),
          ),
        );
      }),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  const _TagChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: MomoSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: MomoSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: MomoColors.backgroundLight,
        borderRadius: BorderRadius.circular(MomoRadius.pill),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 10,
          color: MomoColors.textGray,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
