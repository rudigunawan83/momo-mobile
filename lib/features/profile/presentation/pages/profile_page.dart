/// Profile Page — tampilkan profil pengguna dengan XP, relationship, dan settings
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../../core/theme/momo_design_system.dart';
import '../../../../core/models/dto_models.dart';
import '../../../providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final xpAsync = ref.watch(currentXpProvider);
    final relationshipAsync = ref.watch(currentRelationshipProvider);

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
                  colors: [Color(0xFFF0F4FF), Color(0xFFF7F5EF)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // AppBar
                ClipRect(
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
                          const Text(
                            'Profil Saya',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: MomoColors.textBlack,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(currentUserProvider);
                      ref.invalidate(currentXpProvider);
                      ref.invalidate(currentRelationshipProvider);
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(MomoSpacing.lg),
                      children: [
                        // User card
                        userAsync.when(
                          data: (user) => _buildUserCard(user),
                          loading: () => _buildSkeletonCard(height: 160),
                          error: (_, __) => _buildErrorCard('Gagal memuat profil'),
                        ),

                        const SizedBox(height: MomoSpacing.lg),

                        // XP & Level card
                        xpAsync.when(
                          data: (xp) => _buildXpCard(xp),
                          loading: () => _buildSkeletonCard(height: 120),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: MomoSpacing.lg),

                        // Relationship card
                        relationshipAsync.when(
                          data: (rel) => _buildRelationshipCard(rel),
                          loading: () => _buildSkeletonCard(height: 120),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: MomoSpacing.xl),

                        // Settings section
                        _buildSettingsSection(context, ref),

                        const SizedBox(height: MomoSpacing.xxxl),
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

  Widget _buildUserCard(UserProfileDto user) {
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
      child: Row(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF4FA3FF), Color(0xFF1683FF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: MomoColors.primaryBlue.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: MomoSpacing.lg),

          // Name & info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: MomoTypography.headlineLarge,
                ),
                if (user.nickname.isNotEmpty && user.nickname != user.name)
                  Text(
                    '@${user.nickname}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: MomoColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                if (user.email != null)
                  Text(
                    user.email!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: MomoColors.textGray,
                    ),
                  ),
                const SizedBox(height: MomoSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MomoSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: MomoColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(MomoRadius.pill),
                  ),
                  child: Text(
                    '🌏 ${user.timezone.split('/').last}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: MomoColors.primaryBlue,
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

  Widget _buildXpCard(XpProfileDto xp) {
    return Container(
      padding: const EdgeInsets.all(MomoSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1683FF), Color(0xFF0056CC)],
        ),
        borderRadius: BorderRadius.circular(MomoRadius.xl),
        boxShadow: [
          BoxShadow(
            color: MomoColors.primaryBlue.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '⭐ Level & XP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MomoSpacing.md,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(MomoRadius.pill),
                ),
                child: Text(
                  'Level ${xp.level}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MomoSpacing.md),
          Text(
            '${xp.xp} XP',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: MomoSpacing.sm),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(MomoRadius.pill),
            child: LinearProgressIndicator(
              value: xp.progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: MomoSpacing.xs),
          Text(
            '${xp.xp} / ${xp.nextLevelXp} XP menuju Level ${xp.level + 1}',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipCard(RelationshipDto rel) {
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
          Row(
            children: [
              const Text(
                '❤️ Hubungan dengan Momo',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MomoColors.textBlack,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MomoSpacing.md,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE91E63).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(MomoRadius.pill),
                ),
                child: Text(
                  'Lv. ${rel.level}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE91E63),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: MomoSpacing.sm),
          Text(
            rel.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE91E63),
            ),
          ),
          if (rel.description != null) ...[
            const SizedBox(height: MomoSpacing.xs),
            Text(
              rel.description!,
              style: const TextStyle(
                fontSize: 13,
                color: MomoColors.textGray,
              ),
            ),
          ],
          const SizedBox(height: MomoSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(MomoRadius.pill),
            child: LinearProgressIndicator(
              value: rel.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE91E63).withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
            ),
          ),
          const SizedBox(height: MomoSpacing.xs),
          Text(
            '${(rel.progress * 100).round()}% menuju level berikutnya',
            style: const TextStyle(
              fontSize: 11,
              color: MomoColors.textGray,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pengaturan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: MomoColors.textBlack,
          ),
        ),
        const SizedBox(height: MomoSpacing.md),
        Container(
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
            children: [
              _SettingsItem(
                icon: Icons.notifications_rounded,
                iconColor: const Color(0xFFFF6D00),
                label: 'Notifikasi',
                onTap: () {},
              ),
              _Divider(),
              _SettingsItem(
                icon: Icons.language_rounded,
                iconColor: MomoColors.primaryBlue,
                label: 'Bahasa',
                trailing: const Text(
                  'Indonesia',
                  style: TextStyle(color: MomoColors.textGray, fontSize: 13),
                ),
                onTap: () {},
              ),
              _Divider(),
              _SettingsItem(
                icon: Icons.dark_mode_rounded,
                iconColor: const Color(0xFF9C27B0),
                label: 'Tema',
                trailing: const Text(
                  'Light',
                  style: TextStyle(color: MomoColors.textGray, fontSize: 13),
                ),
                onTap: () {},
              ),
              _Divider(),
              _SettingsItem(
                icon: Icons.privacy_tip_rounded,
                iconColor: MomoColors.success,
                label: 'Privasi & Data',
                onTap: () {},
              ),
              _Divider(),
              _SettingsItem(
                icon: Icons.help_outline_rounded,
                iconColor: MomoColors.textGray,
                label: 'Bantuan & FAQ',
                onTap: () {},
              ),
              _Divider(),
              _SettingsItem(
                icon: Icons.logout_rounded,
                iconColor: MomoColors.error,
                label: 'Keluar',
                labelColor: MomoColors.error,
                onTap: () => _confirmLogout(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MomoRadius.xl),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: MomoColors.primaryBlue,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(MomoSpacing.xl),
      decoration: BoxDecoration(
        color: MomoColors.error.withOpacity(0.05),
        borderRadius: BorderRadius.circular(MomoRadius.xl),
        border: Border.all(color: MomoColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: MomoColors.error, size: 20),
          const SizedBox(width: MomoSpacing.sm),
          Text(
            message,
            style: const TextStyle(color: MomoColors.error, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MomoRadius.xl),
        ),
        title: const Text('Keluar?'),
        content: const Text(
          'Kamu akan keluar dari akun Momo kamu.',
          style: TextStyle(color: MomoColors.textGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authStateProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MomoColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MomoRadius.md),
              ),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ===== Sub-widgets =====

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MomoRadius.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MomoSpacing.lg,
          vertical: MomoSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(MomoRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: MomoSpacing.md),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? MomoColors.textBlack,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            const SizedBox(width: MomoSpacing.sm),
            const Icon(
              Icons.chevron_right_rounded,
              color: MomoColors.textGrayLight,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: MomoSpacing.lg + 36 + MomoSpacing.md,
      color: Colors.grey.withOpacity(0.1),
    );
  }
}
