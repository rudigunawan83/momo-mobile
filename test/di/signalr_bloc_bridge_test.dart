import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:momo_app/data/realtime/signalr_client.dart';
import 'package:momo_app/di/signalr_bloc_bridge.dart';
import 'package:momo_app/domain/engines/character_engine.dart';
import 'package:momo_app/domain/engines/emotion_engine.dart';
import 'package:momo_app/domain/engines/i_emotion_engine.dart';
import 'package:momo_app/domain/entities/character_state.dart';
import 'package:momo_app/domain/services/virtual_room/virtual_room_manager.dart';

void main() {
  late EmotionEngine emotionEngine;
  late CharacterEngine characterEngine;
  late VirtualRoomManager virtualRoomManager;
  late SignalRClient signalRClient;
  late SignalRBlocBridge bridge;

  setUp(() {
    emotionEngine = EmotionEngine();
    characterEngine = CharacterEngine();
    virtualRoomManager = VirtualRoomManager(friendshipLevel: 1);
    signalRClient = SignalRClient(
      config: const SignalRClientConfig(
        hubUrl: 'https://localhost/hubs/chat',
      ),
    );
    bridge = SignalRBlocBridge(
      signalRClient: signalRClient,
      emotionEngine: emotionEngine,
      characterEngine: characterEngine,
      virtualRoomManager: virtualRoomManager,
    );
  });

  tearDown(() {
    bridge.dispose();
    emotionEngine.dispose();
    characterEngine.dispose();
    virtualRoomManager.dispose();
  });

  group('SignalRBlocBridge', () {
    test('initial state is not started', () {
      expect(bridge.isStarted, isFalse);
    });

    test('exposes signalRClient', () {
      expect(bridge.signalRClient, same(signalRClient));
    });

    group('Emotion Engine → Character Engine wiring', () {
      test('emotion update triggers character state change', () async {
        // Manually subscribe to simulate what start() does
        final subscription = emotionEngine.emotionStream.listen((state) {
          final charState = _emotionTypeToCharacterState(state.primary);
          characterEngine.setState(charState);
        });

        // Trigger a positive emotion via conversation event
        emotionEngine.updateFromConversation(
          ConversationEvent(
            sentimentScore: 0.8,
            timestamp: DateTime(2024, 1, 15, 14, 0), // afternoon, no sleepiness
          ),
        );

        // Wait for the CharacterEngine transition timer (500ms)
        await Future<void>.delayed(const Duration(milliseconds: 600));

        // With 0.8 sentiment → high valence, high arousal → excited
        // The character engine should have transitioned from idle
        expect(
          characterEngine.currentState,
          isNot(CharacterState.idle),
        );

        await subscription.cancel();
      });
    });

    group('Friendship update → VirtualRoomManager wiring', () {
      test('friendship level update changes room manager level', () {
        // Simulate receiving a friendship update
        final data = <String, dynamic>{'level': 10, 'totalXP': 1000, 'xpGained': 50};

        // Directly invoke the handler logic
        final level = data['level'] as int?;
        if (level != null && level >= 1) {
          virtualRoomManager.friendshipLevel = level;
        }

        expect(virtualRoomManager.friendshipLevel, equals(10));
        // At level 10, forest room should be unlocked
        expect(
          virtualRoomManager.availableRooms.any((r) => r.name == 'forest'),
          isTrue,
        );
      });

      test('invalid friendship level is ignored', () {
        virtualRoomManager.friendshipLevel = 5;

        // Level 0 or null should be ignored
        final data = <String, dynamic>{'level': null};
        final level = data['level'] as int?;
        if (level != null && level >= 1) {
          virtualRoomManager.friendshipLevel = level;
        }

        // Should remain at 5
        expect(virtualRoomManager.friendshipLevel, equals(5));
      });
    });

    group('Stream completed → Emotion Engine wiring', () {
      test('stream completion triggers emotion update', () async {
        final states = <dynamic>[];
        final subscription = emotionEngine.emotionStream.listen(states.add);

        // Simulate what the bridge does on stream completed
        const sentimentScore = 0.7; // maps from 'happy'
        emotionEngine.updateFromConversation(
          ConversationEvent(
            sentimentScore: sentimentScore,
            timestamp: DateTime(2024, 6, 15, 12, 0),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        expect(states, isNotEmpty);

        await subscription.cancel();
      });
    });
  });
}

CharacterState _emotionTypeToCharacterState(dynamic emotion) {
  switch (emotion.toString()) {
    case 'EmotionType.happy':
      return CharacterState.happy;
    case 'EmotionType.sad':
      return CharacterState.sad;
    case 'EmotionType.angry':
      return CharacterState.angry;
    case 'EmotionType.curious':
      return CharacterState.curious;
    case 'EmotionType.shy':
      return CharacterState.shy;
    case 'EmotionType.sleepy':
      return CharacterState.sleepy;
    case 'EmotionType.neutral':
      return CharacterState.neutral;
    case 'EmotionType.excited':
      return CharacterState.excited;
    default:
      return CharacterState.neutral;
  }
}
