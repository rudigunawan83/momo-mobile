import 'package:flutter/material.dart';
import '../../../../core/theme/momo_design_system.dart';
import '../../../../core/widgets/momo_glass_widgets.dart';

/// Status Area Components
/// Menampilkan: Relationship Status | Momo Identity | XP Level

/// Relationship Card (Top Left)
class RelationshipCard extends StatelessWidget {
  final String? relationshipTitle;
  final double? progress;
  final VoidCallback? onTap;

  const RelationshipCard({
    Key? key,
    this.relationshipTitle = 'Sahabat Baik',
    this.progress = 0.85,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MomoGlassCard(
      padding: const EdgeInsets.all(MomoSpacing.md),
      borderRadius: MomoRadius.xl,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                '⭐',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: MomoSpacing.sm),
              Expanded(
                child: Text(
                  relationshipTitle ?? 'Sahabat Baik',
                  style: MomoTypography.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: MomoSpacing.sm),
          // Progress bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: MomoColors.primaryBlueLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              widthFactor: progress ?? 0.85,
              child: Container(
                decoration: BoxDecoration(
                  color: MomoColors.primaryBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: MomoSpacing.xs),
          Text(
            '${((progress ?? 0) * 100).toStringAsFixed(0)}%',
            style: MomoTypography.labelSmall,
          ),
        ],
      ),
    );
  }
}

/// Momo Identity Card (Top Center)
class MomoIdentity extends StatelessWidget {
  final String status;
  final VoidCallback? onTap;

  const MomoIdentity({
    Key? key,
    this.status = 'online',
    this.onTap,
  }) : super(key: key);

  Color get _statusColor {
    switch (status.toLowerCase()) {
      case 'online':
        return MomoColors.online;
      case 'offline':
        return MomoColors.offline;
      case 'thinking':
        return MomoColors.thinking;
      case 'speaking':
        return MomoColors.speaking;
      default:
        return MomoColors.online;
    }
  }

  String get _statusText {
    switch (status.toLowerCase()) {
      case 'online':
        return 'Online';
      case 'thinking':
        return 'Thinking...';
      case 'speaking':
        return 'Speaking...';
      case 'listening':
        return 'Listening...';
      case 'offline':
        return 'Offline';
      default:
        return 'Online';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Momo',
            style: MomoTypography.displaySmall,
          ),
          const SizedBox(height: MomoSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: _statusColor.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MomoSpacing.sm),
              Text(
                _statusText,
                style: MomoTypography.bodySmall.copyWith(
                  color: _statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// XP Level Card (Top Right)
class XpLevelCard extends StatelessWidget {
  final int? level;
  final int? xp;
  final int? nextLevelXp;
  final VoidCallback? onTap;

  const XpLevelCard({
    Key? key,
    this.level = 12,
    this.xp = 1250,
    this.nextLevelXp = 1500,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress =
        nextLevelXp != null && xp != null ? (xp! / nextLevelXp!).clamp(0.0, 1.0) : 0.85;

    return MomoGlassCard(
      padding: const EdgeInsets.all(MomoSpacing.md),
      borderRadius: MomoRadius.xl,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                '🏅',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: MomoSpacing.xs),
              Text(
                'Lv. ${level ?? 12}',
                style: MomoTypography.labelLarge,
              ),
            ],
          ),
          const SizedBox(height: MomoSpacing.sm),
          Text(
            '${xp ?? 1250} XP',
            style: MomoTypography.labelSmall,
          ),
          const SizedBox(height: MomoSpacing.xs),
          // Progress bar
          SizedBox(
            width: 60,
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: MomoColors.primaryBlueLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: MomoColors.primaryBlue,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status Area Container - menyatukan ketiga komponen
class StatusArea extends StatelessWidget {
  final String? relationshipTitle;
  final double? relationshipProgress;
  final String momoStatus;
  final int? xpLevel;
  final int? currentXp;
  final int? nextLevelXp;
  final VoidCallback? onRelationshipTap;
  final VoidCallback? onMomoTap;
  final VoidCallback? onXpTap;

  const StatusArea({
    Key? key,
    this.relationshipTitle,
    this.relationshipProgress,
    this.momoStatus = 'online',
    this.xpLevel,
    this.currentXp,
    this.nextLevelXp,
    this.onRelationshipTap,
    this.onMomoTap,
    this.onXpTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MomoSpacing.lg,
        vertical: MomoSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left - Relationship
          Expanded(
            child: RelationshipCard(
              relationshipTitle: relationshipTitle,
              progress: relationshipProgress,
              onTap: onRelationshipTap,
            ),
          ),
          // Center - Momo Identity
          Expanded(
            child: Center(
              child: MomoIdentity(
                status: momoStatus,
                onTap: onMomoTap,
              ),
            ),
          ),
          // Right - XP
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: XpLevelCard(
                level: xpLevel,
                xp: currentXp,
                nextLevelXp: nextLevelXp,
                onTap: onXpTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
