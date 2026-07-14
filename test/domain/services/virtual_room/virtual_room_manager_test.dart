import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:momo_app/domain/services/virtual_room/ambient_state.dart';
import 'package:momo_app/domain/services/virtual_room/room_state.dart';
import 'package:momo_app/domain/services/virtual_room/room_type.dart';
import 'package:momo_app/domain/services/virtual_room/time_period.dart';
import 'package:momo_app/domain/services/virtual_room/virtual_room_manager.dart';

void main() {
  late VirtualRoomManager manager;

  setUp(() {
    manager = VirtualRoomManager(friendshipLevel: 1);
  });

  tearDown(() {
    manager.dispose();
  });

  group('RoomType', () {
    test('cozy room is always accessible regardless of level', () {
      expect(RoomType.cozy.isUnlockedAt(1), isTrue);
      expect(RoomType.cozy.isUnlockedAt(0), isTrue);
      expect(RoomType.cozy.requiredLevel, 0);
    });

    test('rooms have correct required levels', () {
      expect(RoomType.study.requiredLevel, 5);
      expect(RoomType.forest.requiredLevel, 10);
      expect(RoomType.japan.requiredLevel, 15);
      expect(RoomType.ocean.requiredLevel, 20);
      expect(RoomType.space.requiredLevel, 25);
      expect(RoomType.sky.requiredLevel, 30);
      expect(RoomType.gaming.requiredLevel, 35);
      expect(RoomType.fantasy.requiredLevel, 40);
      expect(RoomType.aiLab.requiredLevel, 45);
    });

    test('isUnlockedAt boundary cases', () {
      expect(RoomType.study.isUnlockedAt(5), isTrue);
      expect(RoomType.study.isUnlockedAt(4), isFalse);
      expect(RoomType.forest.isUnlockedAt(10), isTrue);
      expect(RoomType.forest.isUnlockedAt(9), isFalse);
    });
  });

  group('TimePeriod', () {
    test('morning period is 06:00-11:59', () {
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 6, 0)), TimePeriod.morning);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 11, 59)), TimePeriod.morning);
    });

    test('afternoon period is 12:00-16:59', () {
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 12, 0)), TimePeriod.afternoon);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 16, 59)), TimePeriod.afternoon);
    });

    test('evening period is 17:00-20:59', () {
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 17, 0)), TimePeriod.evening);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 20, 59)), TimePeriod.evening);
    });

    test('night period is 21:00-05:59', () {
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 21, 0)), TimePeriod.night);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 0, 0)), TimePeriod.night);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 5, 59)), TimePeriod.night);
    });

    test('boundary transitions are correct', () {
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 5, 59)), TimePeriod.night);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 6, 0)), TimePeriod.morning);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 11, 59)), TimePeriod.morning);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 12, 0)), TimePeriod.afternoon);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 16, 59)), TimePeriod.afternoon);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 17, 0)), TimePeriod.evening);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 20, 59)), TimePeriod.evening);
      expect(TimePeriod.fromDateTime(DateTime(2024, 1, 1, 21, 0)), TimePeriod.night);
    });
  });

  group('AmbientState', () {
    test('validates lightIntensity bounds', () {
      expect(
        () => AmbientState(timePeriod: TimePeriod.morning, lightIntensity: -0.1, colorTemperature: 0.5),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AmbientState(timePeriod: TimePeriod.morning, lightIntensity: 1.1, colorTemperature: 0.5),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates colorTemperature bounds', () {
      expect(
        () => AmbientState(timePeriod: TimePeriod.morning, lightIntensity: 0.5, colorTemperature: -0.1),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => AmbientState(timePeriod: TimePeriod.morning, lightIntensity: 0.5, colorTemperature: 1.1),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('forTimePeriod creates appropriate ambient for morning', () {
      final ambient = AmbientState.forTimePeriod(TimePeriod.morning);
      expect(ambient.timePeriod, TimePeriod.morning);
      expect(ambient.colorTemperature, greaterThan(0.5));
      expect(ambient.lightIntensity, greaterThan(0.5));
    });

    test('forTimePeriod creates appropriate ambient for night', () {
      final ambient = AmbientState.forTimePeriod(TimePeriod.night);
      expect(ambient.timePeriod, TimePeriod.night);
      expect(ambient.colorTemperature, lessThan(0.5));
      expect(ambient.lightIntensity, lessThan(0.5));
    });
  });

  group('VirtualRoomManager - initialization', () {
    test('starts with Cozy room as default', () {
      expect(manager.currentState.currentRoom, RoomType.cozy);
    });

    test('starts with no loading or transitioning', () {
      expect(manager.currentState.isLoading, isFalse);
      expect(manager.currentState.isTransitioning, isFalse);
    });

    test('starts with no error', () {
      expect(manager.currentState.error, isNull);
    });
  });

  group('VirtualRoomManager - availableRooms', () {
    test('only cozy room available at level 1', () {
      expect(manager.availableRooms, [RoomType.cozy]);
    });

    test('cozy and study available at level 5', () {
      manager.friendshipLevel = 5;
      expect(manager.availableRooms, contains(RoomType.cozy));
      expect(manager.availableRooms, contains(RoomType.study));
    });

    test('all rooms available at level 45', () {
      manager.friendshipLevel = 45;
      expect(manager.availableRooms.length, RoomType.values.length);
    });

    test('friendship level cannot be less than 1', () {
      expect(() => manager.friendshipLevel = 0, throwsA(isA<ArgumentError>()));
    });
  });

  group('VirtualRoomManager - loadRoom access control', () {
    test('locked room shows required level and retains current room', () {
      fakeAsync((async) {
        final states = <RoomState>[];
        manager.roomStateStream.listen(states.add);

        manager.loadRoom(RoomType.study); // requires level 5
        async.elapse(Duration.zero);

        final lastState = states.last;
        expect(lastState.lockedRoomInfo, isNotNull);
        expect(lastState.lockedRoomInfo!.attemptedRoom, RoomType.study);
        expect(lastState.lockedRoomInfo!.requiredLevel, 5);
        expect(lastState.lockedRoomInfo!.currentLevel, 1);
        expect(lastState.currentRoom, RoomType.cozy);
      });
    });

    test('unlocked room loads successfully', () {
      fakeAsync((async) {
        manager.friendshipLevel = 10;
        final states = <RoomState>[];
        manager.roomStateStream.listen(states.add);

        manager.loadRoom(RoomType.forest);
        async.elapse(const Duration(seconds: 2));

        final lastState = states.last;
        expect(lastState.currentRoom, RoomType.forest);
        expect(lastState.lockedRoomInfo, isNull);
        expect(lastState.error, isNull);
      });
    });

    test('cozy room always accessible regardless of level', () {
      fakeAsync((async) {
        final states = <RoomState>[];
        manager.roomStateStream.listen(states.add);

        manager.loadRoom(RoomType.cozy);
        async.elapse(const Duration(seconds: 2));

        // Should not emit locked room info
        expect(states.any((s) => s.lockedRoomInfo != null), isFalse);
      });
    });
  });

  group('VirtualRoomManager - room loading', () {
    test('emits loading state during room load', () {
      fakeAsync((async) {
        manager.friendshipLevel = 10;
        final states = <RoomState>[];
        manager.roomStateStream.listen(states.add);

        manager.loadRoom(RoomType.study);
        async.elapse(const Duration(seconds: 2));

        expect(states.any((s) => s.isLoading), isTrue);
      });
    });

    test('emits transitioning state during room transition', () {
      fakeAsync((async) {
        manager.friendshipLevel = 10;
        final states = <RoomState>[];
        manager.roomStateStream.listen(states.add);

        manager.loadRoom(RoomType.study);
        async.elapse(const Duration(seconds: 2));

        expect(states.any((s) => s.isTransitioning), isTrue);
      });
    });

    test('transition duration is between 300ms and 800ms', () {
      fakeAsync((async) {
        manager.friendshipLevel = 45;
        final states = <RoomState>[];
        manager.roomStateStream.listen(states.add);

        manager.loadRoom(RoomType.aiLab);
        async.elapse(const Duration(seconds: 2));

        final transitionState = states.firstWhere((s) => s.isTransitioning);
        final duration = transitionState.transitionDuration!;
        expect(duration.inMilliseconds, greaterThanOrEqualTo(300));
        expect(duration.inMilliseconds, lessThanOrEqualTo(800));
      });
    });

    test('loading failure retains previous room and shows error', () {
      fakeAsync((async) {
        final failingManager = VirtualRoomManager(
          friendshipLevel: 10,
          resourceLoader: (_) async => throw Exception('Network error'),
        );

        final states = <RoomState>[];
        failingManager.roomStateStream.listen(states.add);

        failingManager.loadRoom(RoomType.study);
        async.elapse(const Duration(seconds: 1));

        final lastState = states.last;
        expect(lastState.currentRoom, RoomType.cozy);
        expect(lastState.error, isNotNull);
        expect(lastState.error, contains('Network error'));
        expect(lastState.failedRoom, RoomType.study);
        expect(lastState.isLoading, isFalse);

        failingManager.dispose();
      });
    });

    test('loading timeout retains previous room and shows error', () {
      fakeAsync((async) {
        final slowManager = VirtualRoomManager(
          friendshipLevel: 10,
          resourceLoader: (_) =>
              Future.delayed(const Duration(seconds: 5), () => true),
        );

        final states = <RoomState>[];
        slowManager.roomStateStream.listen(states.add);

        slowManager.loadRoom(RoomType.study);
        async.elapse(const Duration(seconds: 4));

        final lastState = states.last;
        expect(lastState.currentRoom, RoomType.cozy);
        expect(lastState.error, isNotNull);
        expect(lastState.error, contains('timed out'));
        expect(lastState.failedRoom, RoomType.study);

        slowManager.dispose();
      });
    });
  });

  group('VirtualRoomManager - time of day effects', () {
    test('applyTimeOfDayEffect sets morning ambient at 08:00', () {
      manager.applyTimeOfDayEffect(DateTime(2024, 1, 1, 8, 0));
      expect(manager.currentState.ambientState.timePeriod, TimePeriod.morning);
    });

    test('applyTimeOfDayEffect sets afternoon ambient at 14:00', () {
      manager.applyTimeOfDayEffect(DateTime(2024, 1, 1, 14, 0));
      expect(manager.currentState.ambientState.timePeriod, TimePeriod.afternoon);
    });

    test('applyTimeOfDayEffect sets evening ambient at 19:00', () {
      manager.applyTimeOfDayEffect(DateTime(2024, 1, 1, 19, 0));
      expect(manager.currentState.ambientState.timePeriod, TimePeriod.evening);
    });

    test('applyTimeOfDayEffect sets night ambient at 23:00', () {
      manager.applyTimeOfDayEffect(DateTime(2024, 1, 1, 23, 0));
      expect(manager.currentState.ambientState.timePeriod, TimePeriod.night);
    });

    test('applyTimeOfDayEffect emits on stream', () {
      fakeAsync((async) {
        final states = <RoomState>[];
        manager.roomStateStream.listen(states.add);

        manager.applyTimeOfDayEffect(DateTime(2024, 1, 1, 19, 0));
        async.elapse(Duration.zero);

        expect(states.length, 1);
        expect(states.first.ambientState.timePeriod, TimePeriod.evening);
      });
    });
  });

  group('VirtualRoomManager - setAmbientState', () {
    test('overrides ambient state directly', () {
      final customAmbient = AmbientState(
        timePeriod: TimePeriod.night,
        lightIntensity: 0.1,
        colorTemperature: 0.05,
        particlesEnabled: false,
        particleDensity: 0.0,
        animatedObjectsEnabled: false,
      );
      manager.setAmbientState(customAmbient);
      expect(manager.currentState.ambientState, customAmbient);
    });

    test('emits updated state on stream', () {
      fakeAsync((async) {
        final states = <RoomState>[];
        manager.roomStateStream.listen(states.add);

        final customAmbient = AmbientState.forTimePeriod(TimePeriod.evening);
        manager.setAmbientState(customAmbient);
        async.elapse(Duration.zero);

        expect(states.length, 1);
        expect(states.first.ambientState, customAmbient);
      });
    });
  });

  group('VirtualRoomManager - room state stream', () {
    test('stream emits on locked room attempt', () {
      fakeAsync((async) {
        final states = <RoomState>[];
        manager.roomStateStream.listen(states.add);

        manager.loadRoom(RoomType.aiLab);
        async.elapse(Duration.zero);

        expect(states.length, 1);
        expect(states.first.lockedRoomInfo, isNotNull);
      });
    });
  });
}
