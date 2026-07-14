import 'package:flutter/material.dart';

import '../../domain/entities/emotion_type.dart';
import 'momo_character_painter.dart';

/// Demo widget showcasing all Momo expressions.
///
/// Tap on Momo to cycle through emotions, or use the emotion buttons below.
/// This can be used as a standalone test screen during development.
class MomoCharacterDemo extends StatefulWidget {
  const MomoCharacterDemo({super.key});

  @override
  State<MomoCharacterDemo> createState() => _MomoCharacterDemoState();
}

class _MomoCharacterDemoState extends State<MomoCharacterDemo> {
  EmotionType _currentEmotion = EmotionType.neutral;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        title: const Text('Momo Character'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          const Spacer(),
          // Momo character
          GestureDetector(
            onTap: _cycleEmotion,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: MomoCharacterWidget(
                key: ValueKey(_currentEmotion),
                expression: MomoExpression.fromEmotion(_currentEmotion),
                size: 280,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Emotion label
          Text(
            _emotionLabel(_currentEmotion),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // Emotion buttons
          _buildEmotionButtons(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildEmotionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: EmotionType.values.map((emotion) {
          final isSelected = emotion == _currentEmotion;
          return GestureDetector(
            onTap: () => setState(() => _currentEmotion = emotion),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00E5FF).withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00E5FF).withOpacity(0.6)
                      : Colors.white.withOpacity(0.1),
                ),
              ),
              child: Text(
                _emotionLabel(emotion),
                style: TextStyle(
                  color: isSelected ? const Color(0xFF00E5FF) : Colors.white60,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _cycleEmotion() {
    final emotions = EmotionType.values;
    final nextIndex = (emotions.indexOf(_currentEmotion) + 1) % emotions.length;
    setState(() => _currentEmotion = emotions[nextIndex]);
  }

  String _emotionLabel(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.happy:
        return '😊 Senang';
      case EmotionType.excited:
        return '✨ Excited';
      case EmotionType.sad:
        return '😢 Sedih';
      case EmotionType.angry:
        return '😠 Marah';
      case EmotionType.curious:
        return '🤔 Penasaran';
      case EmotionType.shy:
        return '😳 Malu';
      case EmotionType.sleepy:
        return '😴 Mengantuk';
      case EmotionType.neutral:
        return '🙂 Netral';
    }
  }
}
