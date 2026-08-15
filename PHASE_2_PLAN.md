# Phase 2: API Layer & Authentication Development Plan

Setelah Phase 1 (UI/Theme) selesai, Phase 2 fokus pada API layer dan authentication.

## Overview

Phase 2 bertujuan untuk:
1. Setup API Client dengan proper error handling dan retry logic
2. Implement authentication flow (login, token management)
3. Setup Riverpod providers untuk state management
4. Create repository pattern untuk data layer
5. Implement user profile fetching
6. Setup conversation API
7. Prepare chat streaming infrastructure

## Timeline

**Estimated**: 2-3 weeks

## Tasks

### 1. Complete API Client Setup ✅ (DONE in Phase 1)

- [x] Create `ApiClient` dengan Dio
- [x] Setup interceptors (auth, retry)
- [x] Error handling dan exception mapping
- [x] Environment configuration

**Next**: Enhance dengan SSE support untuk streaming

### 2. Authentication Service

```dart
// lib/features/auth/domain/repositories/auth_repository.dart
abstract class AuthRepository {
  Future<Result<AuthResponse>> login({
    required String email,
    required String password,
  });

  Future<Result<void>> logout();

  Future<Result<AuthResponse>> refreshToken();

  Stream<bool> get authStatusStream;
}
```

Tasks:
- [ ] Create login API endpoint integration
- [ ] Token refresh mechanism
- [ ] Handle token expiration
- [ ] Setup auto-refresh interceptor
- [ ] Create auth state provider

### 3. User Repository

```dart
// lib/features/profile/domain/repositories/user_repository.dart
abstract class UserRepository {
  Future<Result<User>> getCurrentUser();

  Future<Result<User>> updateProfile(Map<String, dynamic> updates);

  Future<Result<void>> logout();
}
```

Tasks:
- [ ] Create user data source (API)
- [ ] Create user repository implementation
- [ ] Setup Riverpod provider untuk current user
- [ ] Handle user profile updates
- [ ] Cache user data locally

### 4. Conversation & Chat API

```dart
// Already defined structure di:
// lib/features/chat/domain/repositories/chat_repository.dart
```

Tasks:
- [ ] Create chat data source untuk API calls
- [ ] Implement HTTP streaming untuk SSE
- [ ] Create chat repository implementation
- [ ] Setup message parsing dari streaming events
- [ ] Test streaming dengan real API

### 5. Riverpod Providers Setup

```dart
// lib/features/chat/presentation/providers/chat_providers.dart
final currentConversationProvider = StateNotifierProvider<...>(...);
final chatMessagesProvider = StateNotifierProvider<...>(...);
final isLoadingProvider = StateProvider<bool>(...);
final errorProvider = StateProvider<String?>(...);
```

Tasks:
- [ ] Create user provider
- [ ] Create auth status provider
- [ ] Create conversation provider
- [ ] Create chat messages provider
- [ ] Create loading/error state providers
- [ ] Setup provider dependencies

### 6. Test API Integration

```bash
flutter test test/features/chat/data/repositories/chat_repository_test.dart
flutter test test/features/auth/data/repositories/auth_repository_test.dart
flutter test test/features/profile/data/repositories/user_repository_test.dart
```

Tasks:
- [ ] Unit tests untuk repositories
- [ ] Integration tests dengan mock API
- [ ] Error handling tests
- [ ] Retry logic tests
- [ ] Token refresh tests

### 7. Update Home Screen

```dart
// Integrate real data dari API
StatusArea(
  relationshipTitle: ref.watch(relationshipProvider).value?.title,
  relationshipProgress: ref.watch(relationshipProvider).value?.progress,
  momoStatus: ref.watch(momoStatusProvider),
  xpLevel: ref.watch(xpProvider).value?.level,
  ...
)
```

Tasks:
- [ ] Fetch user greeting berdasarkan user data
- [ ] Fetch XP level dari API
- [ ] Fetch relationship status dari API
- [ ] Fetch mood dari API
- [ ] Handle loading & error states

## File Structure

Create these files during Phase 2:

```
lib/
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── auth_response_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       ├── logout_usecase.dart
│   │   │       └── refresh_token_usecase.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── login_page.dart
│   │       └── providers/
│   │           └── auth_providers.dart
│   │
│   ├── profile/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── user_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── user_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── repositories/
│   │   │   │   └── user_repository.dart
│   │   │   └── usecases/
│   │   │       └── get_current_user_usecase.dart
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── profile_page.dart
│   │       └── providers/
│   │           └── user_providers.dart
│   │
│   └── chat/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── chat_remote_data_source.dart
│       │   │   └── chat_local_data_source.dart (Phase 5)
│       │   ├── models/
│       │   │   ├── chat_message_model.dart
│       │   │   └── conversation_model.dart
│       │   └── repositories/
│       │       └── chat_repository_impl.dart
│       ├── domain/
│       │   ├── repositories/
│       │   │   └── chat_repository.dart ✅ (Already created)
│       │   └── usecases/
│       │       ├── send_message_usecase.dart
│       │       ├── get_conversation_usecase.dart
│       │       └── create_conversation_usecase.dart
│       └── presentation/
│           ├── pages/
│           │   └── chat_page.dart
│           ├── widgets/
│           │   ├── message_bubble.dart
│           │   ├── typing_indicator.dart
│           │   └── chat_input_field.dart
│           └── providers/
│               ├── chat_providers.dart
│               └── message_providers.dart
│
└── core/
    └── network/
        └── streaming_client.dart (untuk SSE)
```

## API Endpoints Reference

```
Auth:
POST   /auth/login
POST   /auth/logout
POST   /auth/refresh
GET    /auth/me

User:
GET    /users/me
PUT    /users/me
GET    /users/{id}

Chat:
POST   /conversations
GET    /conversations
GET    /conversations/{id}
GET    /conversations/{id}/messages
DELETE /conversations/{id}
POST   /chat/messages (streaming)

Profile:
GET    /profile/xp
GET    /profile/relationship

Mood:
GET    /mood

Memory:
GET    /memory
POST   /memory
DELETE /memory/{id}

Mission:
GET    /missions
GET    /missions/active
POST   /missions/{id}/progress
```

## Key Implementation Details

### Token Lifecycle

```
1. Login -> Get token
2. Store token di SecureStorage
3. Attach token ke setiap request
4. Token expires -> Refresh token
5. New token obtained -> Update storage
6. Logout -> Clear token
```

### Error Handling Chain

```
API Exception
    ↓
DioException mapping
    ↓
MomoException (UnauthorizedException, NetworkException, etc)
    ↓
Result<T> (Success/Failure)
    ↓
Riverpod Provider (state, AsyncValue)
    ↓
UI (error widget/snackbar)
```

### Streaming Events Parsing

```
Raw SSE Response:
event: token
data: {"text": "Hello"}

event: token
data: {"text": " World"}

event: message_complete
data: {"messageId": "123", "content": "Hello World"}

↓ Parser

ChatToken("Hello")
ChatToken(" World")
ChatMessageComplete(...)
```

## Testing Strategy

1. **Mock API Responses**: Use Mockito/Mocktail
2. **Mock Riverpod Providers**: Use ProviderContainer
3. **Integration Tests**: Use test fixtures
4. **Real API Tests**: Dengan staging environment

Example:

```dart
// test/features/chat/data/repositories/chat_repository_test.dart
void main() {
  group('ChatRepository', () {
    late ChatRepository repository;
    late MockChatRemoteDataSource mockDataSource;

    setUp(() {
      mockDataSource = MockChatRemoteDataSource();
      repository = ChatRepositoryImpl(mockDataSource);
    });

    test('sendMessage returns ChatMessage on success', () async {
      // Arrange
      final message = ChatMessage(...);
      when(mockDataSource.sendMessage(...))
          .thenAnswer((_) => Stream.value(ChatToken('Hello')));

      // Act
      final stream = repository.sendMessage(
        conversationId: 'conv-123',
        message: 'Hello',
      );

      // Assert
      expect(stream, emits(isA<ChatToken>()));
    });
  });
}
```

## Deployment Checklist

Sebelum push ke production:

- [ ] All unit tests passing
- [ ] All integration tests passing
- [ ] Error messages user-friendly (tidak technical)
- [ ] Token refresh tested dengan real API
- [ ] Network error handling tested
- [ ] No sensitive data in logs
- [ ] Performance acceptable (API response time < 3s)
- [ ] Offline handling implemented
- [ ] Rate limiting handled

## Notes for Phase 3

Phase 3 akan fokus pada:
- Chat UI (MessageBubble, ChatInput, ConversationList)
- State management untuk chat
- Optimistic UI updates
- Message pagination
- Local cache dengan Isar

Phase 3 akan build on top of Phase 2 foundation ini.
