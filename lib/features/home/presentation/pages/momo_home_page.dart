import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';

/// Momo Home Page — redesigned sesuai mockup
class MomoHomePage extends ConsumerStatefulWidget {
  const MomoHomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<MomoHomePage> createState() => _MomoHomePageState();
}

class _MomoHomePageState extends ConsumerState<MomoHomePage>
    with TickerProviderStateMixin {
  int _selectedTab = 2; // Mood default
  bool _isFavorited = false;
  bool _isMuted = false;
  final TextEditingController _chatController = TextEditingController();
  bool _isCreatingConversation = false;

  // Floating animation for robot
  late AnimationController _floatController;
  late Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _handleChatSend() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isCreatingConversation) return;

    setState(() => _isCreatingConversation = true);

    try {
      final repo = ref.read(chatRepositoryProvider);
      final result = await repo.createConversation();
      result.map(
        (conversation) {
          ref
              .read(chatNotifierProvider.notifier)
              .setConversationId(conversation.id);
          final message = text;
          _chatController.clear();
          context.push('/chat?id=${conversation.id}').then((_) {
            if (mounted) setState(() {});
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(chatNotifierProvider.notifier).sendMessage(message);
          });
        },
        (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gagal menghubungkan ke Momo. Coba lagi ya.'),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
        },
      );
    } finally {
      if (mounted) setState(() => _isCreatingConversation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final xpAsync = ref.watch(currentXpProvider);
    final relationshipAsync = ref.watch(currentRelationshipProvider);
    final greetingAsync = ref.watch(currentGreetingProvider);

    final userName = userAsync.whenOrNull(data: (u) => u?.nickname) ?? 'Kamu';
    final greeting = greetingAsync.whenOrNull(data: (g) => g) ??
        'Hai $userName! 👋\nSenang bertemu lagi!';
    final relTitle =
        relationshipAsync.whenOrNull(data: (r) => r?.title) ?? 'Sahabat Baik';
    final relProgress =
        relationshipAsync.whenOrNull(data: (r) => r?.progress) ?? 0.85;
    final xpLevel = xpAsync.whenOrNull(data: (x) => x?.level) ?? 12;
    final xpAmount = xpAsync.whenOrNull(data: (x) => x?.xp) ?? 1250;

    return Scaffold(
      backgroundColor: const Color(0xFFF0EBE0),
      body: Stack(
        children: [
          // ── Background: room photo ──────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/momo_room_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // Light overlay agar UI tetap readable
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.18),
            ),
          ),

          // ── Main content ────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Status bar
                _buildStatusBar(relTitle, relProgress, xpLevel, xpAmount),

                // Greeting bubble + favorite
                _buildGreetingRow(greeting),

                // Robot (floating)
                Expanded(
                  child: AnimatedBuilder(
                    animation: _floatAnim,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _floatAnim.value),
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Image.asset(
                        'assets/images/momo_head.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                // Voice controls
                _buildVoiceControls(),

                const SizedBox(height: 12),

                // Bottom card: tabs + chat input
                _buildBottomCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Keluar dari Momo?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1A1A2E),
          ),
        ),
        content: const Text(
          'Kamu akan keluar dari sesi ini. Sampai jumpa lagi ya! 👋',
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal',
                style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authStateProvider.notifier).logout();
      // Router akan otomatis redirect ke /login via RouterNotifier
    }
  }


  Widget _buildStatusBar(
      String relTitle, double relProgress, int level, int xp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // Left: relationship card
          Expanded(
            child: _glassCard(
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          relTitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: relProgress.clamp(0.0, 1.0),
                            backgroundColor: const Color(0xFFE5E7EB),
                            color: const Color(0xFF2563EB),
                            minHeight: 5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${(relProgress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Center: Momo identity
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Momo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.verified_rounded,
                      color: Color(0xFF2563EB), size: 18),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF22C55E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Right: logout button
          GestureDetector(
            onTap: () => _handleLogout(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.65),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.5)),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFF6B7280),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Greeting Row ──────────────────────────────────────────────────────────

  Widget _buildGreetingRow(String greeting) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting bubble
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                greeting,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Favorite heart button
          GestureDetector(
            onTap: () => setState(() => _isFavorited = !_isFavorited),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withOpacity(0.4)),
                  ),
                  child: Icon(
                    _isFavorited ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: _isFavorited
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF9CA3AF),
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Voice Controls ────────────────────────────────────────────────────────

  Widget _buildVoiceControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _voiceBtn(
                icon: _isMuted ? Icons.volume_off_rounded : Icons.volume_mute_rounded,
                label: 'Mute',
                onTap: () => setState(() => _isMuted = !_isMuted),
                isActive: _isMuted,
              ),
              _voiceBtn(
                icon: Icons.radio_button_checked_rounded,
                label: 'Rekam',
                onTap: () {},
              ),
              // Center mic button (prominent)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                        border: Border.all(
                          color: const Color(0xFF2563EB),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withOpacity(0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: Color(0xFF2563EB),
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tahan untuk bicara',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              _voiceBtn(
                icon: Icons.camera_alt_outlined,
                label: 'Kamera',
                onTap: () {},
              ),
              _voiceBtn(
                icon: Icons.music_note_rounded,
                label: 'Musik',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _voiceBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF2563EB).withOpacity(0.15)
                      : Colors.white.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF2563EB).withOpacity(0.4)
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF6B7280),
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Bottom Card ───────────────────────────────────────────────────────────

  Widget _buildBottomCard() {
    final tabs = [
      (_TabItem(icon: Icons.chat_bubble_outline_rounded, label: 'Chat')),
      (_TabItem(icon: Icons.track_changes_rounded, label: 'Misi')),
      (_TabItem(icon: Icons.sentiment_satisfied_alt_rounded, label: 'Mood')),
      (_TabItem(icon: Icons.music_note_rounded, label: 'Musik')),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Feature tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isSelected = _selectedTab == i;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedTab = i);
                  if (i == 0) context.push('/chat');
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 18,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF9CA3AF),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isSelected ? 6 : 0,
                      height: isSelected ? 6 : 0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),

          const SizedBox(height: 12),

          // Chat input
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _chatController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1A1A2E),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ketik pesan...',
                      hintStyle: TextStyle(
                        color: Color(0xFFBCC0C8),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    onSubmitted: (_) => _handleChatSend(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isCreatingConversation ? null : _handleChatSend,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF2563EB),
                  ),
                  child: _isCreatingConversation
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _ambientBlob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  String _formatXp(int xp) {
    if (xp >= 1000) {
      return '${(xp / 1000).toStringAsFixed(xp % 1000 == 0 ? 0 : 1)}.${(xp % 1000).toString().padLeft(3, '0')}';
    }
    return xp.toString();
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}
