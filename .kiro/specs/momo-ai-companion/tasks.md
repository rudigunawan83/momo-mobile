# Implementation Plan: Momo AI Companion

## Overview

This plan implements the Momo AI Companion system across Flutter (mobile) and .NET 8 (backend) using Clean Architecture. The implementation follows a bottom-up approach: core domain models and interfaces first, then engine implementations, service wiring, real-time communication, and finally integration/UI layer. Backend uses C# with xUnit/FsCheck for testing; Flutter uses Dart with flutter_test/glados.

## Tasks

- [x] 1. Set up project structure and core domain models
  - [x] 1.1 Create backend project structure with Clean Architecture layers
    - Create solution structure: Domain, Application, Infrastructure, API projects
    - Define shared value objects: EmotionType enum, MessageRole enum, XPSource enum, MemoryType enum, RoomType enum
    - Set up dependency injection configuration
    - _Requirements: 1.1, 11.1, 11.2_

  - [x] 1.2 Create backend domain entities and validation
    - Implement ChatMessage record with validation (non-empty content for User role, max 4000 chars, no future CreatedAt)
    - Implement EmotionState value object with bounds validation (intensity [0,1], valence [-1,1], arousal [0,1])
    - Implement FriendshipState record with invariants (Level >= 1, CurrentXP >= 0 and < XPToNextLevel)
    - Implement Memory record with validation (Summary max 500, Content max 2000, ImportanceScore [0,1], Embedding dim 1536)
    - Implement PersonalityProfile record with trait bounds [0,1] and tone validation
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 4.1, 5.4_

  - [x] 1.3 Create Flutter domain entities and core models
    - Implement EmotionState class with validation (intensity [0,1], valence [-1,1], arousal [0,1], primary required)
    - Implement EmotionType enum (happy, sad, angry, curious, shy, sleepy, neutral, excited)
    - Implement CharacterState enum (idle, thinking, happy, sad, angry, curious, shy, sleepy, neutral, excited)
    - Define repository interfaces (IChatRepository, ICompanionRepository)
    - _Requirements: 4.1, 3.5, 11.6_

  - [x] 1.4 Define backend service interfaces
    - Define IChatService interface with ProcessMessageAsync, ProcessVoiceMessageAsync, GetHistoryAsync
    - Define IMemoryEngine interface with GetRelevantMemoriesAsync, StoreMemoryAsync, SearchMemoriesAsync
    - Define IPersonalityEngine interface with GetProfile, ApplyPersonalityToPrompt, AdjustFromFeedback
    - Define IFriendshipService interface with GetStateAsync, AddXPAsync, ClaimDailyLoginAsync, CheckNewAchievementsAsync
    - Define IAIGateway interface for OpenAI communication
    - _Requirements: 1.1, 5.1, 6.1, 7.1_

- [x] 2. Implement Emotion Engine
  - [x] 2.1 Implement Emotion Engine core logic (Flutter)
    - Implement calculateEmotion method with sentiment-to-valence mapping and arousal derivation
    - Implement blendEmotions with exponential interpolation formula: new = current + (target - current) * (1 - e^(-2.0 * deltaTime))
    - Implement time-of-day sleepiness modifier (22:00-05:00 reduces arousal by 0.2, sets sleepy when intensity < 0.3)
    - Implement deltaTime <= 0 guard returning current state unchanged
    - Implement blending factor boundary cases (factor 0 → current, factor 1 → target)
    - Expose emotionStream for reactive updates
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

  - [ ]* 2.2 Write property test for Emotion Bounds (Property 2)
    - **Property 2: Emotion Bounds** — For all emotion states e: 0.0 ≤ e.intensity ≤ 1.0 ∧ -1.0 ≤ e.valence ≤ 1.0 ∧ 0.0 ≤ e.arousal ≤ 1.0
    - Use glados to generate arbitrary EmotionState inputs and verify bounds after blending
    - **Validates: Requirements 4.1, 4.2**

  - [ ]* 2.3 Write unit tests for Emotion Engine
    - Test blending with deltaTime = 0 returns current unchanged
    - Test blending with large deltaTime converges to target
    - Test sleepiness modifier at 23:00 and 03:00
    - Test normal behavior at 14:00 (no sleepiness)
    - Test sentiment score mapping to valence/arousal
    - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

- [x] 3. Implement Character Engine
  - [x] 3.1 Implement Character Engine state machine (Flutter)
    - Create CharacterEngine class implementing ICharacterEngine interface
    - Implement state machine with valid transitions between CharacterStates
    - Implement setState with 500ms interpolation transition maintaining 60 FPS
    - Implement idle loop (blink, breathe, look-around) after 5 seconds of no interaction
    - Implement eye-tracking target update within 100ms of touch
    - Implement stateStream for state change events
    - Reject invalid transitions (emit error on stateStream, remain in current state)
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6_

  - [ ]* 3.2 Write unit tests for Character Engine
    - Test valid state transitions
    - Test invalid transition rejection and error emission
    - Test idle loop activation after 5-second inactivity
    - Test eye-tracking target update
    - _Requirements: 3.1, 3.4, 3.5, 3.6_

- [x] 4. Implement Memory Engine
  - [x] 4.1 Implement Memory Engine with vector search (Backend)
    - Implement GetRelevantMemoriesAsync with pgvector cosine similarity search
    - Implement relevance scoring: weighted combination of semantic similarity, recency decay, importance score, favorite boost
    - Ensure results ordered by relevance descending, limited to maxResults (1-20), no duplicates
    - Implement memory isolation (row-level security per userId)
    - Implement StoreMemoryAsync with embedding generation (1536 dim for ada-002)
    - Implement validation: summary max 500, content max 2000 chars
    - Return empty list when no memories meet threshold or none exist
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.8, 5.9_

  - [ ]* 4.2 Write property test for Memory Isolation (Property 5)
    - **Property 5: Memory Isolation** — For all users A ≠ B: GetRelevantMemories(A, _) ∩ GetRelevantMemories(B, _) = ∅
    - Use FsCheck to generate arbitrary userIds and verify no cross-user memory access
    - **Validates: Requirements 5.5, 13.3**

  - [ ]* 4.3 Write property test for Memory Ordering (Property 9)
    - **Property 9: Memory Ordering** — GetRelevantMemories results are always ordered by relevance score descending
    - Use FsCheck to generate memory sets and verify ordering invariant
    - **Validates: Requirements 5.1**

  - [ ]* 4.4 Write unit tests for Memory Engine
    - Test relevance score clamping to [0,1]
    - Test maxResults boundary (1 and 20)
    - Test rejection of oversized summary/content
    - Test embedding dimension validation
    - Test empty result for new user
    - _Requirements: 5.2, 5.3, 5.4, 5.6, 5.7, 5.9_

- [x] 5. Implement Personality Engine
  - [x] 5.1 Implement Personality Engine (Backend)
    - Implement GetProfile returning user's PersonalityProfile
    - Implement ApplyPersonalityToPrompt generating system prompt with tone/behavior instructions from trait weights
    - Implement AdjustFromFeedback capping adjustment at ±0.1 per trait per event, keeping all traits in [0,1]
    - Implement default profile initialization (all traits 0.5, tone "balanced") for new users
    - Validate tone preference (reject invalid, retain existing)
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

  - [ ]* 5.2 Write property test for Personality Normalization (Property 8)
    - **Property 8: Personality Normalization** — For all personality profiles: each trait value is in [0.0, 1.0]
    - Use FsCheck to generate arbitrary feedback sequences and verify trait bounds after each adjustment
    - **Validates: Requirements 6.1, 6.4**

  - [ ]* 5.3 Write unit tests for Personality Engine
    - Test default profile values for new user
    - Test feedback adjustment clamping
    - Test invalid tone preference rejection
    - Test system prompt contains personality instructions
    - _Requirements: 6.2, 6.3, 6.4, 6.5_

- [x] 6. Checkpoint - Core engines verified
  - Ensure all tests pass, ask the user if questions arise.

- [x] 7. Implement Friendship Service
  - [x] 7.1 Implement Friendship XP and Level calculation (Backend)
    - Implement CalculateLevelFromXP using formula: XP_needed(level) = FLOOR(100 * level^1.5)
    - Implement AddXPAsync with monotonic totalXP (never subtract)
    - Enforce daily XP cap of 500 per source (Chat, Voice, DailyLogin) per UTC calendar day
    - Implement ClaimDailyLoginAsync with streak increment and 48-hour reset logic
    - Implement achievement checking after XP addition
    - Maintain invariants: currentXP >= 0 AND currentXP < xpToNextLevel; level >= 1; level never decreases
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7, 7.8, 7.9_

  - [ ]* 7.2 Write property test for XP Monotonicity (Property 3)
    - **Property 3: XP Monotonicity** — For all users, totalXP is monotonically non-decreasing over time. XP is never subtracted
    - Use FsCheck to generate arbitrary sequences of AddXP calls and verify totalXP only increases
    - **Validates: Requirements 7.2**

  - [ ]* 7.3 Write property test for Level Consistency (Property 4)
    - **Property 4: Level Consistency** — For all users, level = f(totalXP) where f is the level calculation function. Level is always derivable from totalXP alone
    - Use FsCheck to generate random totalXP values and verify deterministic level calculation
    - **Validates: Requirements 7.1, 7.4, 7.5**

  - [ ]* 7.4 Write property test for Friendship Progression (Property 6)
    - **Property 6: Friendship Progression** — For all XP additions: newLevel >= previousLevel. Levels never decrease
    - Use FsCheck to generate XP addition sequences and verify level monotonicity
    - **Validates: Requirements 7.3**

  - [ ]* 7.5 Write unit tests for Friendship Service
    - Test level calculation for known XP values
    - Test daily cap enforcement (reject after 500 XP from same source)
    - Test streak reset after 48 hours
    - Test streak increment on consecutive daily login
    - Test achievement unlock trigger
    - _Requirements: 7.1, 7.6, 7.7, 7.8, 7.9_

- [x] 8. Implement AI Chat Service
  - [x] 8.1 Implement Chat Service orchestration (Backend)
    - Implement ProcessMessageAsync: validate input, retrieve 5 memories, get 10 recent messages, apply personality, call AI Gateway, extract emotion, store memory, award 10 XP
    - Implement message validation (reject empty/whitespace, reject > 4000 chars)
    - Implement future timestamp rejection (> 5 seconds ahead of server time)
    - Handle AI Gateway unavailability (return error, do NOT store memory or award XP)
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 11.1, 11.2_

  - [x] 8.2 Implement AI Gateway integration (Backend)
    - Create AIGateway service wrapping OpenAI SDK
    - Implement 30-second timeout with cancellation
    - Implement retry with exponential backoff (3 attempts, starting 1 second)
    - Implement fallback response from personality profile on total failure
    - Set character emotion to "confused" on timeout
    - _Requirements: 10.1, 10.2_

  - [x] 8.3 Implement content filtering and security (Backend)
    - Implement prompt injection detection (system instruction override, role impersonation, delimiter escape)
    - Implement AI response content filtering (violence, explicit, hate speech, PII)
    - On filter trigger: discard blocked response, generate safe replacement, log event
    - Return generic refusal on injection detection without revealing logic
    - _Requirements: 13.4, 13.5, 13.6_

  - [ ]* 8.4 Write property test for Conversation Persistence (Property 10)
    - **Property 10: Conversation Persistence** — Every processed message results in exactly one memory entry created
    - Use FsCheck with mocked dependencies to verify memory store is called exactly once per successful chat
    - **Validates: Requirements 1.6**

  - [ ]* 8.5 Write unit tests for Chat Service
    - Test full chat pipeline with mocked dependencies
    - Test empty message rejection
    - Test oversized message rejection
    - Test AI Gateway failure handling (no memory stored, no XP awarded)
    - Test memory context degradation (Memory Engine unavailable)
    - _Requirements: 1.1, 1.2, 1.3, 1.8, 10.3_

- [x] 9. Implement Voice Conversation
  - [x] 9.1 Implement Voice conversation flow (Flutter + Backend)
    - Implement microphone recording with 0.5s minimum, 60s maximum duration
    - Integrate Speech-to-Text for transcription (submit within 3 seconds of release)
    - Implement ProcessVoiceMessageAsync routing transcribed text through same AI pipeline
    - Integrate Text-to-Speech synthesis (begin playback within 3 seconds of response)
    - Implement lip sync animation coordination with audio stream (< 100ms offset)
    - Handle STT failure: stop recording, show "speech not recognized" message, allow retry
    - Handle TTS failure: display response as text, indicate audio unavailable
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

  - [ ]* 9.2 Write unit tests for Voice flow
    - Test minimum/maximum recording duration enforcement
    - Test transcription failure graceful handling
    - Test TTS failure fallback to text display
    - _Requirements: 2.1, 2.5, 2.6_

- [x] 10. Implement Virtual Room Manager
  - [x] 10.1 Implement Virtual Room Manager (Flutter)
    - Implement loadRoom with ambient elements (lighting, particles, animated objects) loading within 3 seconds
    - Implement time-of-day effects: morning (06:00-11:59), afternoon (12:00-16:59), evening (17:00-20:59), night (21:00-05:59)
    - Implement room access control based on friendship level (Cozy Room always accessible)
    - Implement room transitions with 300-800ms animation at 30+ FPS
    - Handle locked room access attempt: show required level, retain current room
    - Handle room loading failure: show error, retain previous room
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [ ]* 10.2 Write unit tests for Virtual Room Manager
    - Test Cozy Room always accessible regardless of level
    - Test locked room rejection with level info
    - Test time-of-day period detection
    - Test loading failure fallback
    - _Requirements: 8.2, 8.3, 8.5, 8.6_

- [x] 11. Checkpoint - All engines and services verified
  - Ensure all tests pass, ask the user if questions arise.

- [x] 12. Implement Real-Time Communication (SignalR)
  - [x] 12.1 Implement SignalR Hub for streaming and state sync (Backend)
    - Create ChatHub with streaming response delivery (each chunk within 300ms, completion signal)
    - Implement friendship state push on XP gain, level up, achievement (within 500ms)
    - Implement connection management and authentication
    - _Requirements: 9.1, 9.2_

  - [x] 12.2 Implement SignalR client with reconnection (Flutter)
    - Integrate SignalR client for real-time message and state reception
    - Implement automatic reconnection with exponential backoff (1s start, doubling, cap 30s, max 10 attempts)
    - Display connection failure indicator after all attempts exhausted, provide manual retry
    - Queue outbound actions during disconnection, deliver on reconnect
    - _Requirements: 9.3, 9.4, 9.5_

  - [ ]* 12.3 Write unit tests for SignalR reconnection logic
    - Test exponential backoff timing (1, 2, 4, 8, 16, 30, 30...)
    - Test max 10 reconnection attempts
    - Test action queuing during disconnection
    - _Requirements: 9.3, 9.4, 9.5_

- [x] 13. Implement Error Handling and Resilience
  - [x] 13.1 Implement error handling and offline mode (Flutter)
    - Implement offline mode: display 50 most recent messages from local cache
    - Implement offline message queue (max 20 messages, auto-sync on reconnect)
    - Disable message input when queue reaches capacity, inform user
    - Implement token refresh flow (silent refresh without interrupting session)
    - Redirect to login on refresh failure, preserve unsent drafts in local storage
    - _Requirements: 10.4, 10.5, 10.7, 10.8, 10.9_

  - [x] 13.2 Implement rate limiting and degradation handling (Backend)
    - Implement rate limit: 60 messages/minute per user, return remaining wait time
    - Set character emotion to "sleepy" on rate limit
    - Implement Memory Engine unavailability handling: proceed without context, set metadata flag
    - _Requirements: 10.3, 10.6_

  - [x] 13.3 Implement Rive animation fallback (Flutter)
    - Catch Rive runtime exceptions, fall back to static character image
    - Attempt artboard reload up to 2 times with 3-second delay
    - Remain on static image if all reload attempts fail
    - _Requirements: 10.8_

  - [ ]* 13.4 Write unit tests for error handling
    - Test offline queue capacity enforcement
    - Test token refresh flow
    - Test rate limit response format
    - Test Rive fallback sequence
    - _Requirements: 10.4, 10.6, 10.8, 10.9_

- [x] 14. Implement App Startup and Wake Sequence
  - [x] 14.1 Implement app startup flow (Flutter)
    - Validate session via Supabase Auth
    - Retrieve companion state from backend
    - Calculate current emotion based on last state, time since last session, and friendship level
    - Play wake-up animation with contextual greeting within 3 seconds
    - Handle session validation failure: redirect to auth flow without wake animation
    - Handle companion state retrieval failure: use default neutral state, friendship level 1
    - Handle wake animation timeout (5 seconds): skip to greeting with static pose
    - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 12.6_

  - [ ]* 14.2 Write unit tests for startup sequence
    - Test successful startup within 3 seconds
    - Test session failure redirect
    - Test fallback to default state on retrieval failure
    - Test animation timeout handling
    - _Requirements: 12.1, 12.4, 12.5, 12.6_

- [x] 15. Implement Security Layer
  - [x] 15.1 Implement security infrastructure (Backend)
    - Configure TLS 1.3 for all data in transit
    - Implement AES-256 encryption for memories at rest
    - Implement row-level security for memory isolation in PostgreSQL
    - Implement session token expiration handling: terminate connection, require re-auth, discard in-flight data
    - _Requirements: 13.1, 13.2, 13.3, 13.7_

  - [ ]* 15.2 Write unit tests for security
    - Test row-level security enforcement
    - Test session expiration handling
    - Test prompt injection detection patterns
    - Test content filter categories
    - _Requirements: 13.3, 13.4, 13.5, 13.7_

- [x] 16. Implement Chat UI with BLoC integration (Flutter)
  - [x] 16.1 Implement ChatBloc and Chat UI screen
    - Create ChatBloc handling ChatMessageSent, VoiceMessageSent events
    - Wire ChatBloc to Character Engine (thinking state on send, emotion on response)
    - Wire ChatBloc to Emotion Engine (update from response sentiment)
    - Implement chat message list with streaming response display
    - Implement voice recording button with hold-to-talk interaction
    - Display XP gain and level-up notifications from SignalR updates
    - _Requirements: 1.1, 2.1, 2.3, 9.1, 9.2_

  - [x] 16.2 Wire all engines together in DI and app initialization
    - Configure Flutter dependency injection (get_it/injectable) for all engines and repositories
    - Configure backend DI for all services, engines, and infrastructure
    - Wire SignalR events to BLoC state updates
    - Wire Emotion Engine output to Character Engine input
    - Wire Friendship state updates to Virtual Room Manager (room unlocks)
    - _Requirements: 1.1, 3.1, 4.6, 7.1, 8.3, 9.1_
<!-- 
- [ ] 17. Final checkpoint - Full integration verified
  - Ensure all tests pass, ask the user if questions arise. -->

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- Backend uses C#/.NET 8 with xUnit + FsCheck for property-based testing
- Flutter uses Dart with flutter_test + glados for property-based testing
- All engines are designed with interface-first approach for testability and mocking

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.3"] },
    { "id": 1, "tasks": ["1.2", "1.4"] },
    { "id": 2, "tasks": ["2.1", "3.1", "4.1", "5.1"] },
    { "id": 3, "tasks": ["2.2", "2.3", "3.2", "4.2", "4.3", "4.4", "5.2", "5.3"] },
    { "id": 4, "tasks": ["7.1"] },
    { "id": 5, "tasks": ["7.2", "7.3", "7.4", "7.5"] },
    { "id": 6, "tasks": ["8.1", "8.2"] },
    { "id": 7, "tasks": ["8.3", "8.4", "8.5", "9.1"] },
    { "id": 8, "tasks": ["9.2", "10.1"] },
    { "id": 9, "tasks": ["10.2", "12.1"] },
    { "id": 10, "tasks": ["12.2", "13.1", "13.2", "13.3"] },
    { "id": 11, "tasks": ["12.3", "13.4", "14.1", "15.1"] },
    { "id": 12, "tasks": ["14.2", "15.2", "16.1"] },
    { "id": 13, "tasks": ["16.2"] }
  ]
}
```
