# Requirements Document

## Introduction

Dokumen ini mendefinisikan requirements untuk Momo AI Companion — sebuah sistem AI companion yang mengintegrasikan multiple engine (Character, Emotion, Memory, Personality) menjadi satu pengalaman interaktif yang terasa hidup. Requirements diturunkan dari design document dan mencakup Phase 1 (AI Chat, Character Engine, Voice, Friendship) sebagai MVP foundation, dengan extensibility points untuk phase berikutnya.

Filosofi inti: "Momo bukan chatbot. Momo adalah sahabat AI yang hidup." (80% Robot, 20% UI — robot adalah UI).

## Glossary

- **Momo_System**: Keseluruhan sistem AI companion termasuk mobile app (Flutter) dan backend (.NET 8)
- **Chat_Service**: Backend service yang mengorkestrasi AI conversation flow termasuk context retrieval, response generation, dan post-processing
- **Character_Engine**: Flutter engine yang mengelola visual state Momo, animasi, dan transisi menggunakan Rive runtime
- **Emotion_Engine**: Engine (Flutter + Backend) yang menentukan emotional state Momo berdasarkan conversation context, waktu, dan interaction patterns
- **Memory_Engine**: Backend engine yang mengelola long-term memory storage, retrieval, dan relevance scoring untuk contextual conversations
- **Personality_Engine**: Backend engine yang mendefinisikan dan mengaplikasikan personality traits Momo ke AI responses
- **Friendship_Service**: Backend service yang melacak friendship progression, XP accumulation, achievements, dan daily engagement mechanics
- **Virtual_Room_Manager**: Flutter manager yang mengelola virtual room environment tempat Momo tinggal
- **AI_Gateway**: Backend component yang berkomunikasi dengan OpenAI API untuk response generation
- **SignalR_Hub**: Real-time communication layer untuk streaming responses dan state synchronization
- **EmotionState**: Value object yang merepresentasikan emotional state dengan properties: primary, intensity, valence, arousal
- **FriendshipState**: Value object yang merepresentasikan friendship progression dengan properties: level, currentXP, totalXP, loginStreak
- **Memory**: Data object yang merepresentasikan long-term memory entry dengan embedding vector untuk similarity search
- **PersonalityProfile**: Data object yang berisi trait weights (humor, caring, curious, calm) dan tone preference
- **XP**: Experience Points yang diakumulasi dari berbagai interaksi untuk menaikkan friendship level
- **ChatMessage**: Record yang merepresentasikan satu pesan dalam conversation (User, Assistant, atau System)

## Requirements

### Requirement 1: AI Chat Conversation Processing

**User Story:** As a user, I want to have context-aware conversations with Momo, so that Momo can respond in a personalized and contextually relevant manner.

#### Acceptance Criteria

1. WHEN a user sends a text message, THE Chat_Service SHALL retrieve up to 5 relevant memories, apply personality modifiers, generate an AI response, store the conversation as memory, and award friendship XP within 10 seconds
2. IF a user sends a message with content exceeding 4000 characters, THEN THE Chat_Service SHALL reject the message and return a validation error indicating the content length limit was exceeded
3. IF a user sends an empty message or a message containing only whitespace, THEN THE Chat_Service SHALL reject the message and return a validation error indicating the message content is required
4. THE Chat_Service SHALL include up to 5 relevant memories and the 10 most recent messages as context when generating AI responses
5. WHEN the AI_Gateway generates a response, THE Chat_Service SHALL extract the emotion from the response text and include it as a valid EmotionType value in the ChatResponse
6. WHEN a chat message is processed successfully, THE Chat_Service SHALL create exactly one memory entry of type Conversation containing a summary of both the user message and AI response
7. WHEN a chat message is processed successfully, THE Friendship_Service SHALL award 10 XP with source Chat to the user for the chat interaction
8. IF the AI_Gateway is unavailable or returns an error during message processing, THEN THE Chat_Service SHALL return an error response indicating the service is temporarily unavailable and SHALL NOT store a memory entry or award XP for that interaction

### Requirement 2: Voice Conversation

**User Story:** As a user, I want to speak to Momo using voice, so that I can interact naturally without typing.

#### Acceptance Criteria

1. WHEN a user releases the microphone button after holding and speaking for at least 0.5 seconds and no more than 60 seconds, THE Momo_System SHALL transcribe the recorded speech to text using Speech-to-Text and submit it within 3 seconds of release
2. WHEN speech is transcribed, THE Chat_Service SHALL process the transcribed text as a voice message through the same AI pipeline used for text messages
3. WHEN the AI response is generated for a voice conversation, THE Momo_System SHALL synthesize the response text to audio using Text-to-Speech and begin playback within 3 seconds of response generation
4. WHILE audio is being played back, THE Character_Engine SHALL synchronize lip animations with the audio stream with no more than 100 milliseconds of visual-to-audio offset
5. IF speech transcription fails or produces no recognizable text, THEN THE Momo_System SHALL stop the recording, display a message indicating that speech was not recognized, and allow the user to retry without losing conversation context
6. IF Text-to-Speech synthesis fails, THEN THE Momo_System SHALL display the AI response as text in the chat and indicate that audio playback is unavailable

### Requirement 3: Character Engine Animation Management

**User Story:** As a user, I want to see Momo animate expressively, so that Momo feels alive and responsive to our interactions.

#### Acceptance Criteria

1. WHEN an emotional state change is received, THE Character_Engine SHALL transition from the current animation state to the target state within 500 milliseconds using interpolation, without dropping below 60 frames per second during the transition
2. WHILE the Character_Engine is rendering animations, THE Character_Engine SHALL maintain a minimum of 60 frames per second
3. WHILE no user interaction has occurred for 5 seconds or more, THE Character_Engine SHALL play an idle loop consisting of blinking, breathing, and look-around behaviors as defined in the Rive artboard idle state machine
4. WHEN a user touches the screen, THE Character_Engine SHALL update the eye-tracking target to the touch position within 100 milliseconds
5. THE Character_Engine SHALL follow valid state machine transition paths between defined CharacterStates (idle, thinking, happy, sad, angry, curious, shy, sleepy, neutral, excited) without skipping intermediate states
6. IF an invalid or undefined CharacterState transition is requested, THEN THE Character_Engine SHALL remain in the current state and emit an error on the stateStream

### Requirement 4: Emotion Engine State Management

**User Story:** As a user, I want Momo to express emotions naturally, so that interactions feel genuine and emotionally engaging.

#### Acceptance Criteria

1. THE Emotion_Engine SHALL produce EmotionState values where intensity is in [0.0, 1.0], valence is in [-1.0, 1.0], and arousal is in [0.0, 1.0]
2. WHEN blending between two emotion states, THE Emotion_Engine SHALL interpolate each emotional dimension (intensity, valence, arousal) using the formula: new_value = current + (target - current) * (1 - e^(-blendSpeed * deltaTime)), where blendSpeed is 2.0 and deltaTime is elapsed time in seconds
3. WHEN the blending factor is 0, THE Emotion_Engine SHALL return the current emotion state unchanged
4. WHEN the blending factor is 1, THE Emotion_Engine SHALL return the target emotion state
5. WHEN the time of day is between 22:00 and 05:00 local time, THE Emotion_Engine SHALL bias the arousal value toward 0.0 by applying a sleepiness modifier that reduces the calculated arousal by at least 0.2 (clamped to [0.0, 1.0]) and sets the primary emotion to sleepy when resulting intensity falls below 0.3
6. WHEN a conversation event occurs, THE Emotion_Engine SHALL map the AI response sentiment score (in [-1.0, 1.0]) to the valence dimension directly and derive arousal from the absolute value of the sentiment score, then determine the primary emotion from the resulting valence-arousal coordinates
7. IF deltaTime is less than or equal to 0 when blending emotions, THEN THE Emotion_Engine SHALL return the current emotion state unchanged without applying interpolation

### Requirement 5: Memory Engine Context Retrieval

**User Story:** As a user, I want Momo to remember our conversations and important details, so that interactions build over time and feel personal.

#### Acceptance Criteria

1. WHEN retrieving relevant memories, THE Memory_Engine SHALL return results ordered by relevance score descending
2. WHEN retrieving relevant memories, THE Memory_Engine SHALL return no more than the requested maxResults count, where maxResults is a positive integer between 1 and 20 inclusive
3. THE Memory_Engine SHALL calculate relevance score using weighted combination of semantic similarity, recency decay, importance score, and favorite boost, where all weight constants are positive and their sum does not exceed 1.0
4. THE Memory_Engine SHALL ensure relevance scores are clamped within [0.0, 1.0]
5. THE Memory_Engine SHALL enforce memory isolation such that no user can access memories belonging to another user
6. IF the summary length exceeds 500 characters or the content length exceeds 2000 characters when storing a memory, THEN THE Memory_Engine SHALL reject the request and return an error indicating which field exceeded its maximum length
7. WHEN storing a memory, THE Memory_Engine SHALL generate an embedding vector of the correct dimension (1536 for ada-002) for similarity search
8. WHEN retrieving relevant memories, THE Memory_Engine SHALL return no duplicate memories in the result set
9. IF no memories meet a minimum relevance threshold or no memories exist for the user when retrieving relevant memories, THEN THE Memory_Engine SHALL return an empty list

### Requirement 6: Personality Engine Consistency

**User Story:** As a user, I want Momo to have a consistent personality, so that interactions feel like talking to the same character every time.

#### Acceptance Criteria

1. THE Personality_Engine SHALL maintain all personality trait values (humor, caring, curious, calm) within [0.0, 1.0]
2. WHEN generating an AI response, THE Personality_Engine SHALL include personality trait values in the system prompt such that the resulting prompt text contains tone and behavior instructions corresponding to the current profile's trait weights and tone preference
3. IF an invalid tone preference value is provided (not one of "playful", "supportive", "intellectual", or "balanced"), THEN THE Personality_Engine SHALL reject the input and retain the existing tone preference unchanged
4. WHEN user feedback is received, THE Personality_Engine SHALL adjust the personality profile by no more than 0.1 per trait per feedback event while keeping all trait values within [0.0, 1.0]
5. WHEN a new user profile is created, THE Personality_Engine SHALL initialize the personality profile with default trait values of 0.5 for each trait (humor, caring, curious, calm) and a tone preference of "balanced"

### Requirement 7: Friendship Progression System

**User Story:** As a user, I want my friendship with Momo to grow over time, so that I feel rewarded for consistent interaction and see progression.

#### Acceptance Criteria

1. THE Friendship_Service SHALL calculate level deterministically from totalXP using the formula: XP_needed(level) = FLOOR(100 * level^1.5), starting at level 1 with 0 totalXP for new users
2. THE Friendship_Service SHALL ensure that totalXP is monotonically non-decreasing — XP is never subtracted
3. THE Friendship_Service SHALL ensure that level never decreases — newLevel is always greater than or equal to previousLevel
4. THE Friendship_Service SHALL maintain the invariant: currentXP >= 0 AND currentXP < xpToNextLevel
5. THE Friendship_Service SHALL maintain the invariant: sum of XPRequiredForLevel(1..level-1) + currentXP = totalXP
6. WHEN a user claims daily login, THE Friendship_Service SHALL award XP for the DailyLogin source and increment the login streak by 1
7. IF a user does not claim daily login within 48 hours of their last login claim, THEN THE Friendship_Service SHALL reset the login streak to 0
8. WHEN new achievements criteria are met after an XP addition, THE Friendship_Service SHALL unlock and award those achievements
9. IF a user exceeds the daily XP cap of 500 XP for a given source (Chat, Voice, or DailyLogin), THEN THE Friendship_Service SHALL reject additional XP from that source for the remainder of the calendar day (UTC) and return an indication that the cap has been reached

### Requirement 8: Virtual Room Environment

**User Story:** As a user, I want Momo to live in a virtual room environment, so that the experience feels immersive and the world feels alive.

#### Acceptance Criteria

1. WHEN a user selects an unlocked room, THE Virtual_Room_Manager SHALL load and render the room environment including its associated ambient elements (lighting, particles, animated objects) within 3 seconds
2. WHILE a room is active, THE Virtual_Room_Manager SHALL update the room lighting and ambient effects to reflect the current time of day, applying at minimum four distinct periods: morning (06:00–11:59), afternoon (12:00–16:59), evening (17:00–20:59), and night (21:00–05:59)
3. THE Virtual_Room_Manager SHALL grant access only to rooms that are unlocked based on the user's friendship level, with the Cozy Room always accessible as the default room regardless of friendship level
4. WHEN transitioning between rooms, THE Virtual_Room_Manager SHALL animate the transition with a duration between 300 milliseconds and 800 milliseconds while maintaining a minimum of 30 frames per second
5. IF a user attempts to access a locked room, THEN THE Virtual_Room_Manager SHALL display an indication of the friendship level required to unlock that room and retain the user in the current room
6. IF room loading fails due to a resource or network error, THEN THE Virtual_Room_Manager SHALL display an error message indicating the failure reason and retain the previously active room

### Requirement 9: Real-Time State Synchronization

**User Story:** As a user, I want to see Momo's responses and state changes in real-time, so that the interaction feels immediate and alive.

#### Acceptance Criteria

1. WHEN the backend generates a streaming AI response, THE SignalR_Hub SHALL deliver each response chunk to the connected client within 300 milliseconds of chunk generation and SHALL send a completion signal when the full response has been transmitted
2. WHEN a friendship state update occurs (XP gain, level up, achievement), THE SignalR_Hub SHALL push the update containing the updated friendship state data to the connected client within 500 milliseconds of the event occurring
3. IF the SignalR connection is lost, THEN THE Momo_System SHALL attempt automatic reconnection with exponential backoff starting at 1 second, doubling on each attempt, capped at 30 seconds, for a maximum of 10 attempts
4. IF all reconnection attempts are exhausted without success, THEN THE Momo_System SHALL display a connection failure indicator to the user and provide a manual retry option
5. WHILE the SignalR connection is disconnected, THE Momo_System SHALL queue outbound user actions locally and deliver them upon successful reconnection

### Requirement 10: Error Handling and Resilience

**User Story:** As a user, I want Momo to handle errors gracefully, so that the experience remains consistent even when things go wrong.

#### Acceptance Criteria

1. IF the AI_Gateway does not respond within 30 seconds, THEN THE Chat_Service SHALL cancel the pending request, return a pre-defined fallback response selected from the active personality profile's fallback set, and set the character emotion to "confused"
2. IF the AI_Gateway fails after 3 retry attempts with exponential backoff starting at 1 second, THEN THE Chat_Service SHALL respond with a fallback message derived from the active personality profile and notify the user that the response is a fallback
3. IF the Memory_Engine is unavailable during chat processing, THEN THE Chat_Service SHALL proceed without memory context and include a metadata flag in the response indicating that memory context was not applied
4. IF the user's authentication token expires during an active session, THEN THE Momo_System SHALL attempt to refresh the token using the stored refresh token without interrupting the user's current interaction
5. IF the silent token refresh fails due to an expired or invalid refresh token, THEN THE Momo_System SHALL redirect the user to the login screen and preserve any unsent message drafts in local storage
6. IF the user exceeds the message rate limit of 60 messages per minute, THEN THE Chat_Service SHALL reject the message, indicate that the rate limit has been exceeded, display the remaining wait time in seconds, and set the character emotion to "sleepy"
7. IF the device loses network connectivity, THEN THE Momo_System SHALL switch to offline mode, display up to the 50 most recent messages from local cache, and queue up to 20 outgoing messages for automatic sync when connectivity is restored
8. IF the Rive animation engine throws an exception, THEN THE Character_Engine SHALL fall back to a static character image, attempt to reload the Rive artboard up to 2 times with a 3-second delay between attempts, and remain on the static image if all reload attempts fail
9. IF the offline message queue reaches its maximum capacity of 20 messages, THEN THE Momo_System SHALL inform the user that new messages cannot be sent until connectivity is restored and disable the message input

### Requirement 11: Data Validation and Integrity

**User Story:** As a developer, I want all data models to enforce strict validation rules, so that the system maintains data integrity at all times.

#### Acceptance Criteria

1. IF a ChatMessage has Role set to User and Content is empty or contains only whitespace, THEN THE Chat_Service SHALL reject the message and return a validation error
2. IF a ChatMessage has CreatedAt set to a time in the future (more than 5 seconds ahead of server time), THEN THE Chat_Service SHALL reject the message and return a validation error
3. IF a Memory entry has ImportanceScore outside the range [0.0, 1.0], THEN THE Memory_Engine SHALL reject the entry and return a validation error
4. IF a Memory entry has an Embedding with dimension not equal to the configured model dimension (1536 for ada-002), THEN THE Memory_Engine SHALL reject the entry and return a validation error
5. IF a FriendshipState has Level less than 1, THEN THE Friendship_Service SHALL reject the state and return a validation error
6. IF an EmotionState has primary emotion set to null or undefined, THEN THE Emotion_Engine SHALL reject the state and return a validation error

### Requirement 12: App Startup and Wake Sequence

**User Story:** As a user, I want Momo to greet me contextually when I open the app, so that every session start feels personal and alive.

#### Acceptance Criteria

1. WHEN the user opens the app, THE Momo_System SHALL validate the session, retrieve companion state, calculate current emotion, and play a wake-up animation within 3 seconds of app launch
2. WHEN the companion state is retrieved, THE Emotion_Engine SHALL calculate the current emotion factoring in the last known emotional state, time since last session (categorized as: less than 1 hour, 1–24 hours, more than 24 hours, or more than 7 days), and current friendship level
3. WHEN the wake animation completes, THE Character_Engine SHALL deliver a greeting that reflects the current emotional state through matching animation, expression, and greeting text
4. IF session validation fails during app startup, THEN THE Momo_System SHALL redirect the user to the authentication flow without playing the wake animation
5. IF companion state retrieval fails during app startup, THEN THE Momo_System SHALL use a default neutral emotional state with friendship level 1 and proceed with the wake animation sequence
6. IF the wake animation does not complete within 5 seconds, THEN THE Character_Engine SHALL skip to the greeting delivery using a static pose matching the calculated emotion

### Requirement 13: Security and Privacy

**User Story:** As a user, I want my conversations and memories to be secure and private, so that I can trust Momo with personal information.

#### Acceptance Criteria

1. THE Momo_System SHALL encrypt all data in transit using TLS 1.3
2. THE Momo_System SHALL encrypt memories at rest using AES-256
3. THE Memory_Engine SHALL enforce row-level security ensuring each user can only access their own memories
4. IF user input contains patterns indicative of prompt injection (such as attempts to override system instructions, role impersonation, or delimiter escape sequences), THEN THE Chat_Service SHALL reject the input, discard the injected content from AI processing, and return a generic refusal message to the user without revealing filtering logic
5. THE Chat_Service SHALL apply content filtering on AI responses to detect and block content in the following categories: violence or self-harm encouragement, sexually explicit material, hate speech, and personally identifiable information of third parties
6. IF the content filter blocks an AI response, THEN THE Chat_Service SHALL discard the blocked response, generate a safe replacement response acknowledging inability to answer, and log the filtering event for review
7. WHEN a user session token expires or is invalidated, THE Momo_System SHALL terminate the active connection, require re-authentication before processing further requests, and discard any in-flight unsaved data from the expired session
