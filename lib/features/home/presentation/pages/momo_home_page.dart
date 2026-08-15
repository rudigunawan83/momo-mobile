import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/momo_design_system.dart';
import '../../../providers.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../voice/presentation/providers/voice_providers.dart';
import '../../../voice/domain/models/voice_models.dart';
import '../../../voice/presentation/widgets/voice_widgets.dart';
import '../widgets/status_area.dart';
import '../widgets/greeting_and_favorite.dart';
import '../widgets/momo_robot.dart';
import '../widgets/voice_controls.dart';
import '../widgets/feature_navigation.dart'; // includes MomoChatInput

/// Momo Home Page — halaman utama dengan data dari API
class MomoHomePage extends ConsumerStatefulWidget {
  const MomoHomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<MomoHomePage> createState() => _MomoHomePageState();
}

class _MomoHomePageState extends ConsumerState<MomoHomePage> {
  // Local UI state
  String _selectedFeature = 'mood';
  bool _isFavorited = false;
  String _robotMood = 'neutral';

  // Chat input controller
  final TextEditingController _chatController = TextEditingController();
  bool _isCreatingConversation = false;

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  /// Handle start/stop voice session
  Future<void> _handleMicrophoneTap() async {
    final voiceNotifier = ref.read(voiceNotifierProvider.notifier);
    final voiceState = ref.read(voiceNotifierProvider);

    if (voiceState.isActive) {
      await voiceNotifier.stopVoiceSession();
    } else {
      // Start voice session dengan current conversation (jika ada)
      final conversationId = ref.read(chatNotifierProvider).conversationId;
      await voiceNotifier.startVoiceSession(conversationId: conversationId);
    }
  }

  /// Handle mute toggle
  Future<void> _handleMuteTap() async {
    await ref.read(voiceNotifierProvider.notifier).toggleMicrophone();
  }

  /// Handle send dari Home chat input
  Future<void> _handleHomeChatSend() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isCreatingConversation) return;

    setState(() {
      _isCreatingConversation = true;
    });

    try {
      // Buat conversation baru
      final repo = ref.read(chatRepositoryProvider);
      final result = await repo.createConversation();

      result.map(
        (conversation) {
          // Set conversation ID di ChatNotifier
          ref.read(chatNotifierProvider.notifier).setConversationId(conversation.id);

          // Navigate ke ChatPage dan kirim message
          final message = text;
          _chatController.clear();

          context.push('/chat?id=${conversation.id}').then((_) {
            // Ketika kembali dari chat
            if (mounted) {
              setState(() {});
            }
          });

          // Kirim message setelah navigasi
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(chatNotifierProvider.notifier).sendMessage(message);
          });
        },
        (failure) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Gagal menghubungkan ke Momo. Coba lagi ya.',
                ),
                backgroundColor: MomoColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MomoRadius.md),
                ),
              ),
            );
          }
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingConversation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers
    final currentRelationshipAsync = ref.watch(currentRelationshipProvider);
    final currentXpAsync = ref.watch(currentXpProvider);
    final currentGreetingAsync = ref.watch(currentGreetingProvider);
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // Voice state
    final voiceState = ref.watch(voiceNotifierProvider);
    final isVoiceActive = ref.watch(isVoiceActiveProvider);
    final voiceMode = ref.watch(voiceSessionModeProvider);
    final isMicEnabled = ref.watch(isMicEnabledProvider);

    // Sync robot state dengan voice mode
    final robotState = switch (voiceMode) {
      VoiceSessionMode.listening => 'listening',
      VoiceSessionMode.processing => 'thinking',
      VoiceSessionMode.speaking => 'speaking',
      VoiceSessionMode.idle => 'idle',
    };

    // Jika tidak authenticated, show loading (router akan redirect)
    if (!isAuthenticated) {
      return const Scaffold(
        backgroundColor: MomoColors.backgroundLight,
        body: Center(
          child: CircularProgressIndicator(
            color: MomoColors.primaryBlue,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: MomoColors.backgroundLight,
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            _buildBackground(),

            // Main content
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // ── Status Area (Top) ──────────────────────────
                  currentRelationshipAsync.when(
                    data: (relationship) => currentXpAsync.when(
                      data: (xp) => StatusArea(
                        relationshipTitle: relationship.title,
                        relationshipProgress: relationship.progress,
                        momoStatus: robotState == 'listening'
                            ? 'listening'
                            : robotState == 'thinking'
                                ? 'thinking'
                                : 'online',
                        xpLevel: xp.level,
                        currentXp: xp.xp,
                        nextLevelXp: xp.nextLevelXp,
                      ),
                      loading: () => const _StatusAreaSkeleton(),
                      error: (err, st) => const StatusArea(),
                    ),
                    loading: () => const _StatusAreaSkeleton(),
                    error: (err, st) => const StatusArea(),
                  ),

                  const SizedBox(height: MomoSpacing.lg),

                  // ── Greeting Bubble + Favorite Button ─────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MomoSpacing.lg,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: currentGreetingAsync.when(
                            data: (greeting) => MomoGreetingBubble(
                              greeting: greeting,
                              onTap: () {},
                            ),
                            loading: () => const MomoGreetingBubble(
                              greeting: 'Hai! 👋\nSenang bertemu lagi!',
                            ),
                            error: (err, st) => const MomoGreetingBubble(
                              greeting: 'Hai! 👋\nSenang bertemu lagi!',
                            ),
                          ),
                        ),
                        const SizedBox(width: MomoSpacing.lg),
                        FavoriteButton(
                          isFavorited: _isFavorited,
                          onToggle: () {
                            setState(() => _isFavorited = !_isFavorited);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: MomoSpacing.xxxl),

                  // ── Momo Robot (Focal Point) ──────────────────
                  // Saat voice aktif: tampilkan Voice Orb, sinon: Robot
                  isVoiceActive
                      ? MomoVoiceOrb(
                          mode: voiceMode,
                          connectionState: voiceState.connectionState,
                          audioLevel: voiceState.inputLevel,
                          size: MediaQuery.of(context).size.width * 0.4,
                          onTap: _handleMicrophoneTap,
                        )
                      : MomoRobotWithMood(
                          state: robotState,
                          mood: _robotMood,
                          size: MediaQuery.of(context).size.width * 0.4,
                        ),

                  const SizedBox(height: MomoSpacing.xxxl),

                  // ── Voice Session Panel (saat voice aktif) ────
                  if (isVoiceActive)
                    VoiceSessionPanel(
                      mode: voiceMode,
                      connectionState: voiceState.connectionState,
                      audioLevel: voiceState.inputLevel,
                      isMicEnabled: isMicEnabled,
                      isSpeakerEnabled: voiceState.isSpeakerEnabled,
                      onMicToggle: _handleMuteTap,
                      onSpeakerToggle: () => ref
                          .read(voiceNotifierProvider.notifier)
                          .toggleSpeaker(),
                      onEndSession: () => ref
                          .read(voiceNotifierProvider.notifier)
                          .stopVoiceSession(),
                    ),

                  // ── Voice Controls ────────────────────────────
                  if (!isVoiceActive)
                    VoiceControlBar(
                      isMuted: !isMicEnabled,
                      isRecording: false,
                      onMuteTap: _handleMuteTap,
                      onRecordTap: null, // Rekaman belum diimplementasi
                      onMicrophoneTap: _handleMicrophoneTap,
                      onCameraTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fitur kamera akan hadir segera 📸'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onMusicTap: () => context.push('/music'),
                    ),

                  const SizedBox(height: MomoSpacing.lg),

                  // ── Feature Navigation Bar ────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MomoSpacing.lg,
                    ),
                    child: MomoFeatureBar(
                      selectedFeature: _selectedFeature,
                      onChatTap: () {
                        setState(() => _selectedFeature = 'chat');
                        context.push('/chat');
                      },
                      onMissionTap: () {
                        setState(() => _selectedFeature = 'mission');
                        context.push('/missions');
                      },
                      onMoodTap: () {
                        setState(() => _selectedFeature = 'mood');
                        context.push('/mood');
                      },
                      onMusicTap: () {
                        setState(() => _selectedFeature = 'music');
                        context.push('/music');
                      },
                    ),
                  ),

                  const SizedBox(height: MomoSpacing.lg),

                  // ── Chat Input (Home) ─────────────────────────
                  MomoChatInput(
                    controller: _chatController,
                    hintText: _isCreatingConversation
                        ? 'Menghubungkan ke Momo...'
                        : 'Ketik pesan...',
                    isLoading: _isCreatingConversation,
                    onSend: _handleHomeChatSend,
                  ),

                  const SizedBox(height: MomoSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEEF4FF),
              Color(0xFFF7F5EF),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MomoColors.primaryBlueLight.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              left: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: MomoColors.primaryBlueLight.withOpacity(0.04),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




/// Skeleton loading untuk status area
class _StatusAreaSkeleton extends StatelessWidget {
  const _StatusAreaSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MomoSpacing.lg,
        vertical: MomoSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SkeletonBox(width: 90, height: 60),
          _SkeletonBox(width: 80, height: 40),
          _SkeletonBox(width: 90, height: 60),
        ],
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(MomoRadius.xl),
      ),
    );
  }
}
