# Phase 3 - Chat UI & Features Implementation Plan

Setelah Phase 2 (API & Auth) selesai, Phase 3 fokus pada:
1. Chat interface dengan message streaming
2. Features: Memory, Mood, Mission, XP
3. Message persistence
4. Optimistic UI updates

## Timeline

**Estimated**: 3-4 weeks

## Tasks

### 1. Chat Message Components

```dart
// lib/features/chat/presentation/widgets/message_bubble.dart
// lib/features/chat/presentation/widgets/typing_indicator.dart
// lib/features/chat/presentation/widgets/message_input_with_actions.dart
```

- [ ] Message bubble untuk user messages
- [ ] Message bubble untuk AI responses
- [ ] Typing indicator animation
- [ ] Message timestamp display
- [ ] Message actions (copy, regenerate, delete)
- [ ] Loading state during streaming

### 2. Chat Page Implementation

```dart
// lib/features/chat/presentation/pages/chat_page.dart
// lib/features/chat/presentation/providers/chat_page_provider.dart
```

- [ ] Conversation list view
- [ ] Message list dengan scroll
- [ ] Message input area
- [ ] Voice input button integration
- [ ] Camera button integration
- [ ] Auto-scroll to latest message
- [ ] Empty state display

### 3. Message State Management

```dart
// lib/features/chat/presentation/providers/message_notifier.dart
```

- [ ] Load messages untuk conversation
- [ ] Add new message (optimistic)
- [ ] Stream incoming tokens
- [ ] Accumulate tokens menjadi full response
- [ ] Handle streaming errors
- [ ] Message pagination
- [ ] Clear messages

### 4. Database Layer (Isar)

```dart
// lib/features/chat/data/datasources/chat_local_data_source.dart
// lib/features/chat/data/models/chat_message_local.dart
```

- [ ] Setup Isar local database
- [ ] Save messages locally
- [ ] Load messages dari cache
- [ ] Sync dengan server
- [ ] Delete old messages
- [ ] Search messages

### 5. Memory Feature

```dart
// lib/features/memory/presentation/pages/memory_page.dart
// lib/features/memory/data/repositories/memory_repository.dart
```

- [ ] Display user memories
- [ ] Add new memory
- [ ] Edit existing memory
- [ ] Delete memory
- [ ] Memory timeline view
- [ ] Memory categories

### 6. Mood Feature

```dart
// lib/features/mood/presentation/pages/mood_page.dart
// lib/features/mood/data/repositories/mood_repository.dart
```

- [ ] Display current mood
- [ ] Mood history
- [ ] Set mood with emoji picker
- [ ] Mood insights
- [ ] Mood tracking chart
- [ ] Mood-based recommendations

### 7. Mission Feature

```dart
// lib/features/mission/presentation/pages/mission_page.dart
// lib/features/mission/data/repositories/mission_repository.dart
```

- [ ] Display active missions
- [ ] Mission list dengan progress
- [ ] Mission details
- [ ] Complete mission action
- [ ] Reward display
- [ ] Mission history

### 8. XP & Level System

```dart
// lib/features/profile/presentation/widgets/level_up_dialog.dart
// lib/features/profile/presentation/pages/profile_page.dart
```

- [ ] Level up dialog/animation
- [ ] Achievement badges
- [ ] XP breakdown
- [ ] Progress visualization
- [ ] Leaderboard (optional)

## File Structure

```
lib/features/
├── chat/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── chat_remote_data_source.dart ✅ (from Phase 2)
│   │   │   └── chat_local_data_source.dart (NEW)
│   │   ├── models/
│   │   │   └── chat_message_local.dart (NEW)
│   │   └── repositories/
│   │       └── chat_repository_impl.dart ✅ (updated)
│   ├── domain/
│   │   └── repositories/
│   │       └── chat_repository.dart ✅ (from Phase 1)
│   └── presentation/
│       ├── pages/
│       │   └── chat_page.dart (NEW)
│       ├── widgets/
│       │   ├── message_bubble.dart (NEW)
│       │   ├── typing_indicator.dart (NEW)
│       │   ├── message_input.dart (NEW)
│       │   └── conversation_list_item.dart (NEW)
│       └── providers/
│           ├── chat_providers.dart (NEW)
│           └── message_notifier.dart (NEW)
│
├── memory/
│   ├── data/
│   │   ├── datasources/
│   │   │   ├── memory_remote_data_source.dart (NEW)
│   │   │   └── memory_local_data_source.dart (NEW)
│   │   ├── models/
│   │   │   └── memory_model.dart (NEW)
│   │   └── repositories/
│   │       └── memory_repository_impl.dart (NEW)
│   ├── domain/
│   │   ├── repositories/
│   │   │   └── memory_repository.dart (NEW)
│   │   └── usecases/ (NEW)
│   └── presentation/
│       ├── pages/
│       │   └── memory_page.dart (NEW)
│       ├── widgets/
│       │   ├── memory_card.dart (NEW)
│       │   └── memory_form.dart (NEW)
│       └── providers/
│           └── memory_providers.dart (NEW)
│
├── mood/
│   ├── data/
│   │   ├── datasources/
│   │   │   └── mood_remote_data_source.dart (NEW)
│   │   ├── models/
│   │   │   └── mood_model.dart (NEW)
│   │   └── repositories/
│   │       └── mood_repository_impl.dart (NEW)
│   ├── domain/
│   │   ├── repositories/
│   │   │   └── mood_repository.dart (NEW)
│   │   └── usecases/ (NEW)
│   └── presentation/
│       ├── pages/
│       │   └── mood_page.dart (NEW)
│       ├── widgets/
│       │   ├── mood_selector.dart (NEW)
│       │   ├── mood_history.dart (NEW)
│       │   └── mood_chart.dart (NEW)
│       └── providers/
│           └── mood_providers.dart (NEW)
│
├── mission/
│   ├── data/
│   │   ├── datasources/
│   │   │   └── mission_remote_data_source.dart (NEW)
│   │   ├── models/
│   │   │   └── mission_model.dart (NEW)
│   │   └── repositories/
│   │       └── mission_repository_impl.dart (NEW)
│   ├── domain/
│   │   ├── repositories/
│   │   │   └── mission_repository.dart (NEW)
│   │   └── usecases/ (NEW)
│   └── presentation/
│       ├── pages/
│       │   └── mission_page.dart (NEW)
│       ├── widgets/
│       │   ├── mission_card.dart (NEW)
│       │   ├── mission_progress.dart (NEW)
│       │   └── mission_details.dart (NEW)
│       └── providers/
│           └── mission_providers.dart (NEW)
│
└── profile/
    └── presentation/
        ├── pages/
        │   └── profile_page.dart (NEW)
        ├── widgets/
        │   ├── level_up_dialog.dart (NEW)
        │   ├── achievement_badge.dart (NEW)
        │   └── stats_section.dart (NEW)
        └── providers/
            └── profile_providers.dart (NEW)
```

## Implementation Strategy

### Week 1-2: Chat UI & Streaming

1. **Message Components**
   - Create message bubble widget dengan animation
   - Implement typing indicator
   - Message input dengan send button

2. **Chat Page**
   - Message list dengan scroll controller
   - Auto-scroll to latest
   - Load messages dari provider
   - Handle streaming responses

3. **State Management**
   - Message notifier untuk accumulate tokens
   - Pagination logic
   - Error handling

### Week 2-3: Feature Pages

1. **Memory Feature**
   - Display memories dalam timeline
   - Add/edit/delete memory
   - Tags support

2. **Mood Feature**
   - Mood selector dengan emojis
   - History dengan dates
   - Simple chart visualization

3. **Mission Feature**
   - Active missions list
   - Progress bars
   - Reward display

### Week 3-4: Polish & Optimization

1. **Database**
   - Isar integration untuk local cache
   - Sync logic

2. **Animations**
   - Message slide-in animation
   - Level-up celebration
   - Typing animation

3. **Error Handling**
   - Network error recovery
   - Retry logic
   - Offline support

## API Endpoints Reference

```
Chat:
  - POST /chat/messages (streaming) ✅ (from Phase 2)
  - GET /conversations/{id}/messages ✅ (from Phase 2)

Memory:
  - GET /memory
  - POST /memory
  - PUT /memory/{id}
  - DELETE /memory/{id}

Mood:
  - GET /mood
  - POST /mood
  - GET /mood/history

Mission:
  - GET /missions
  - GET /missions/active
  - POST /missions/{id}/progress
  - GET /missions/completed
```

## Testing Strategy

- [ ] Unit tests untuk message notifier
- [ ] Widget tests untuk message bubble
- [ ] Integration tests untuk chat flow
- [ ] Test SSE streaming dengan mock
- [ ] Test database operations
- [ ] Performance test dengan large message lists

## Success Criteria

- ✅ Real-time message streaming working
- ✅ Messages saved locally
- ✅ All feature pages functional
- ✅ Smooth animations dan transitions
- ✅ No performance issues dengan large lists
- ✅ Proper error handling & user feedback

## Notes

- Memory feature mungkin akan di-delay ke Phase 4 jika timeline ketat
- Mission feature bisa simplified di Phase 3 dan enhanced di Phase 4
- Consider using `flutter_animate` package untuk animations
- Consider using `fl_chart` package untuk mood/XP charts

---

**Phase 3 Status: READY TO START** 

Mari dimulai setelah Phase 2 testing selesai!
