# Development Guidelines

## Code Style & Conventions

### Dart Code Style

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `const` untuk immutable values dan constructors
- Prefer `final` over `var` untuk variable declarations
- Use meaningful variable names (camelCase untuk variables)
- Use UPPER_CASE untuk constants

```dart
// ✅ Good
final String userName = 'Rudi';
const double maxRetries = 3;

// ❌ Avoid
var userName = 'Rudi';
String user_name = 'Rudi';
final maxRetries = 3;
```

### File Organization

1. **Imports** - urutan:
   - dart imports
   - flutter imports
   - package imports
   - relative imports

2. **Class definition**:
   - Fields
   - Constructor
   - Methods (public)
   - Private methods

3. **Widget structure**:
   - StatelessWidget / StatefulWidget
   - build method
   - Helper methods (private)

```dart
import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/momo_design_system.dart';

class MyWidget extends StatelessWidget {
  final String title;
  
  const MyWidget({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    // Implementation
    return Container();
  }
}
```

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Class | PascalCase | `ChatMessage`, `UserProfile` |
| Function | camelCase | `getUserData()`, `sendMessage()` |
| Variable | camelCase | `userName`, `messageCount` |
| Constant | UPPER_CASE | `MAX_RETRIES`, `API_TIMEOUT` |
| File (class) | snake_case | `chat_message.dart`, `user_profile.dart` |
| File (service) | snake_case | `api_client.dart`, `secure_storage.dart` |
| Private | leading underscore | `_privateMethod()`, `_internalState` |

### Comments

- Use `///` untuk dokumentasi publik
- Use `//` untuk comment regular
- Hindari comment yang obvious

```dart
/// Kirim pesan ke Momo AI
/// 
/// Returns [Result<ChatMessage>] dengan message yang berhasil dikirim
/// Throws [NetworkException] jika koneksi gagal
Future<Result<ChatMessage>> sendMessage(String content) async {
  // Validate message
  if (content.isEmpty) {
    return Failure(...);
  }

  // Send to API
  return await repository.sendMessage(content);
}
```

## Git Workflow

### Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

Types:
- `feat`: Feature baru
- `fix`: Bug fix
- `refactor`: Refactoring code
- `style`: Code style changes
- `docs`: Documentation
- `test`: Adding tests
- `chore`: Build process, dependencies

```bash
# Example
git commit -m "feat: add chat message streaming support"
git commit -m "fix: resolve memory leak in robot animation"
git commit -m "docs: update API integration guide"
```

### Branch Naming

```
feature/feature-name
bugfix/bug-description
refactor/refactor-description
docs/documentation-update
```

### PR Guidelines

- Setiap PR harus untuk satu feature/fix saja
- Minimal 1 reviewer sebelum merge
- Pastikan CI/CD passed
- Update documentation jika diperlukan

## Testing

### Unit Tests

```dart
// test/features/chat/domain/usecases/send_message_test.dart
void main() {
  group('SendMessage UseCase', () {
    late SendMessageUseCase useCase;
    late MockChatRepository mockRepository;

    setUp(() {
      mockRepository = MockChatRepository();
      useCase = SendMessageUseCase(mockRepository);
    });

    test('should return ChatMessage on success', () async {
      // Arrange
      final message = ChatMessage(...);
      when(mockRepository.sendMessage(...))
          .thenAnswer((_) async => Success(message));

      // Act
      final result = await useCase.call(...);

      // Assert
      expect(result, isA<Success<ChatMessage>>());
    });

    test('should return NetworkException on network error', () async {
      // Arrange
      when(mockRepository.sendMessage(...))
          .thenThrow(NetworkException(...));

      // Act
      final result = await useCase.call(...);

      // Assert
      expect(result, isA<Failure>());
    });
  });
}
```

### Widget Tests

```dart
// test/features/home/presentation/pages/momo_home_page_test.dart
void main() {
  group('MomoHomePage', () {
    testWidgets('should display greeting bubble', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const ProviderScope(child: MomoApp()));

      // Assert
      expect(find.byType(MomoGreetingBubble), findsOneWidget);
      expect(find.text('Hai Rudi! 👋'), findsOneWidget);
    });
  });
}
```

## Performance Tips

1. **Avoid rebuilds**:
   - Use `const` constructors
   - Use `Consumer` / `ConsumerWidget` untuk listen specific providers
   - Use `select()` untuk select specific state

2. **Image optimization**:
   - Use `cached_network_image` untuk network images
   - Resize images sesuai screen size
   - Use lazy loading untuk images list

3. **Animation optimization**:
   - Hindari transform pada animation, gunakan offset/position
   - Use `SingleTickerProviderStateMixin` untuk single animation
   - Dispose controller di `dispose()`

4. **Memory management**:
   - Dispose stream subscriptions
   - Dispose controllers
   - Cancel pending API requests saat widget disposed

## Debugging

### Logger Setup

```dart
import 'package:logger/logger.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    colors: true,
    printEmojis: true,
  ),
);

// Usage
logger.d('Debug message');
logger.i('Info message');
logger.w('Warning message');
logger.e('Error message', error: e, stackTrace: st);
```

### Riverpod DevTools

```bash
flutter pub add flutter_riverpod
# Running dengan devtools:
flutter run --enable-software-vsync
```

### Flutter DevTools

```bash
flutter pub global activate devtools
devtools

# Or di VSCode, tekan `Ctrl+Shift+D` dan run "Dart: Open DevTools"
```

## Documentation

### API Documentation

Selalu dokumentasikan:
- Endpoint URL
- Request/Response format
- Error cases
- Authentication requirements

```dart
/// GET /api/v1/users/me
/// 
/// Get current authenticated user profile
/// 
/// Requires: Bearer token di Authorization header
/// 
/// Returns: User object dengan profile data
/// 
/// Throws:
/// - UnauthorizedException: Token invalid atau expired
/// - NetworkException: Koneksi error
/// 
/// Example:
/// ```dart
/// final user = await userRepository.getCurrentUser();
/// print(user.name);
/// ```
Future<User> getCurrentUser() async {
  return await apiClient.get<User>('/users/me');
}
```

### Readme untuk Feature

Setiap feature folder harus punya `README.md`:

```markdown
# Chat Feature

## Overview
Describe what this feature does

## Architecture
Explain the structure

## API Integration
List endpoints digunakan

## State Management
Explain Riverpod setup

## Usage
Contoh penggunaan
```

## Code Review Checklist

Sebelum merge PR, pastikan:

- [ ] Code mengikuti style guide
- [ ] Tidak ada hardcoded values
- [ ] Error handling proper
- [ ] Performance considerations
- [ ] Documentation updated
- [ ] Tests included
- [ ] No breaking changes
- [ ] No unused imports/variables
- [ ] Security check (sensitive data)
- [ ] API contracts sesuai backend
