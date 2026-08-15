# Momo AI Mobile App - Flutter

Aplikasi mobile AI Companion yang dibangun dengan Flutter, terintegrasi dengan Momo AI Backend API.

## 🎯 Overview

**Momo** adalah aplikasi mobile yang memungkinkan pengguna berinteraksi dengan AI companion yang ramah, cerdas, dan personal. Aplikasi menggunakan:

- **Framework**: Flutter (Dart 3+)
- **State Management**: Riverpod
- **Architecture**: Feature-First + Clean Architecture
- **API**: Momo AI Backend (.NET 8+)
- **Design**: Bright Daytime Glassmorphism

## 📋 Table of Contents

1. [Project Structure](#project-structure)
2. [Setup & Installation](#setup--installation)
3. [Development](#development)
4. [Build & Deployment](#build--deployment)
5. [Architecture](#architecture)
6. [API Integration](#api-integration)
7. [Contributing](#contributing)

## 📁 Project Structure

```
lib/
├── app/                           # App configuration
│   ├── app.dart                  # Main app widget
│   ├── router.dart               # Go Router configuration
│   └── theme/
│       ├── momo_design_system.dart    # Colors, typography, spacing, radius, shadows
│       └── momo_theme.dart            # Material 3 theme configuration
│
├── core/                          # Core utilities shared across features
│   ├── config/
│   │   └── env_config.dart       # Environment configuration (.env)
│   ├── constants/
│   │   └── app_constants.dart    # App constants, endpoints, error messages
│   ├── errors/
│   │   ├── exceptions.dart       # Custom exception types
│   │   └── result.dart           # Result<T> type for error handling
│   ├── models/
│   │   └── base_models.dart      # Base models (User, ChatMessage, etc)
│   ├── network/
│   │   └── api_client.dart       # Dio-based API client with interceptors
│   ├── providers/
│   │   └── core_providers.dart   # Riverpod providers for core services
│   ├── storage/
│   │   └── secure_storage_service.dart  # JWT token & secure data storage
│   ├── utils/
│   │   └── responsive_helper.dart       # Responsive layout utilities
│   └── widgets/
│       └── momo_glass_widgets.dart      # Reusable glassmorphism widgets
│
├── features/
│   ├── home/                      # Home feature (Phase 1)
│   │   ├── data/                 # Data layer (Models, API, Repository impl)
│   │   ├── domain/               # Domain layer (Entities, Use cases)
│   │   └── presentation/
│   │       ├── pages/
│   │       │   └── momo_home_page.dart
│   │       ├── widgets/
│   │       │   ├── status_area.dart
│   │       │   ├── greeting_and_favorite.dart
│   │       │   ├── momo_robot.dart
│   │       │   ├── voice_controls.dart
│   │       │   └── feature_navigation.dart
│   │       └── providers/
│   │           └── home_providers.dart   # Riverpod providers
│   │
│   ├── chat/                      # Chat feature (Phase 2)
│   ├── voice/                     # Voice feature (Phase 4)
│   ├── mission/                   # Mission feature (Phase 3)
│   ├── mood/                      # Mood feature (Phase 3)
│   ├── music/                     # Music feature (Phase 4)
│   ├── profile/                   # Profile feature (Phase 3)
│   └── memory/                    # Memory feature (Phase 3)
│
└── main.dart                      # App entry point
```

## 🚀 Setup & Installation

### Prerequisites

- Flutter stable (latest version)
- Dart 3.0+
- Android Studio / Xcode
- Momo AI Backend API running

### Installation Steps

1. **Clone repository**
```bash
git clone <repository-url>
cd momo-mobile
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Setup environment files**
```bash
# Salinan dari template atau buat sendiri
cp .env.dev.example .env.dev
cp .env.staging.example .env.staging
cp .env.prod.example .env.prod
```

Edit `.env.dev`:
```env
API_BASE_URL=http://10.0.2.2:5000
LIVEKIT_URL=ws://10.0.2.2:7880
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=devsecret
ENVIRONMENT=development
LOG_LEVEL=debug
```

4. **Run code generation** (untuk freezed, json_serializable, dll)
```bash
flutter pub run build_runner build
```

5. **Run app**
```bash
# Development
flutter run

# Dengan specific device
flutter run -d <device-id>
```

## 💻 Development

### Project Phases

**Phase 1** ✅ - UI/Theme/Design System (COMPLETED)
- Flutter project setup
- Design system (colors, typography, spacing, radius, shadows)
- Glassmorphism components
- Home screen layout dan components
- Responsive design

**Phase 2** - API Layer & Authentication
- API client dengan Dio
- Authentication flow
- JWT token management
- User profile fetching
- Conversation API

**Phase 3** - Chat & State Management
- Riverpod providers setup
- Chat state machine
- Message repository & use cases
- Chat page UI
- Message streaming with SSE

**Phase 4** - Features Integration (Memory, Mood, Mission, XP, Relationship)
- User profile data
- Memory feature
- Mood tracking
- Mission system
- XP/Level system
- Relationship progress

**Phase 5** - Voice & Advanced Features
- LiveKit integration
- Voice recording & streaming
- Camera integration
- Music feature
- Analytics service
- Offline cache (Isar)
- Performance optimization

### Architecture Pattern

Menggunakan **Clean Architecture** dengan **Feature-First** approach:

```
Presentation (UI) 
    ↓
State Management (Riverpod)
    ↓
Use Case / Notifier
    ↓
Repository (Interface)
    ↓
Data Sources (API/Local)
```

### Adding New Feature

1. **Create feature folder**: `lib/features/new_feature/`
2. **Create layers**:
   - `presentation/pages/` - UI pages
   - `presentation/widgets/` - Reusable widgets
   - `presentation/providers/` - Riverpod providers
   - `data/datasources/` - API & local data access
   - `data/repositories/` - Repository implementation
   - `data/models/` - Data models
   - `domain/repositories/` - Abstract repository
   - `domain/entities/` - Domain entities
   - `domain/usecases/` - Business logic

3. **Follow naming conventions**:
   - Pages: `*_page.dart`
   - Widgets: `*_widget.dart`
   - Providers: `*_provider.dart`
   - Models: `*_model.dart`
   - Entities: `*_entity.dart`

### Widget Best Practices

- Gunakan **StatelessWidget** sebanyak mungkin
- Untuk state, gunakan **Riverpod** (StateNotifier, FutureProvider, etc)
- Hindari **setState()** untuk global state
- setState() hanya untuk local widget state yang simple
- Pisahkan UI dari business logic

### Theme & Design System

Semua warna, typography, spacing dideklarasikan di:
- `lib/core/theme/momo_design_system.dart`
- `lib/core/theme/momo_theme.dart`

**Jangan hardcode** warna atau spacing di widget.

### API Integration

1. **Define endpoint** di `AppEndpoints`
2. **Create API data source**:
```dart
abstract class UserDataSource {
  Future<User> getUser();
}

class UserDataSourceImpl implements UserDataSource {
  final ApiClient apiClient;
  
  @override
  Future<User> getUser() async {
    final response = await apiClient.get('/users/me');
    return User.fromJson(response);
  }
}
```

3. **Create repository**:
```dart
abstract class UserRepository {
  Future<Result<User>> getUser();
}

class UserRepositoryImpl implements UserRepository {
  final UserDataSource dataSource;
  
  @override
  Future<Result<User>> getUser() async {
    try {
      final user = await dataSource.getUser();
      return Success(user);
    } catch (e) {
      return Failure(exception: e, message: e.toString());
    }
  }
}
```

4. **Create provider** (di `presentation/providers/`):
```dart
final userProvider = FutureProvider<User>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUser();
});
```

5. **Use in widget**:
```dart
class UserWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    
    return userAsync.when(
      data: (user) => Text(user.name),
      loading: () => const CircularProgressIndicator(),
      error: (err, st) => Text('Error: $err'),
    );
  }
}
```

## 🏗️ Build & Deployment

### Build APK (Android)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-app.apk
```

### Build AAB (Android App Bundle)
```bash
flutter build appbundle --release
```

### Build IPA (iOS)
```bash
flutter build ipa --release
```

### Flavors (untuk multiple environments)

Konfigurasi di `pubspec.yaml` dan android/ios build files:

```bash
# Development
flutter run --flavor dev -t lib/main_dev.dart

# Staging
flutter run --flavor staging -t lib/main_staging.dart

# Production
flutter run --flavor prod -t lib/main_prod.dart
```

## 🔌 API Integration

### Environment Configuration

Edit `.env.dev`, `.env.staging`, `.env.prod`:

```env
API_BASE_URL=<your-api-url>
LIVEKIT_URL=<your-livekit-url>
LIVEKIT_API_KEY=<your-livekit-api-key>
LIVEKIT_API_SECRET=<your-livekit-api-secret>
```

### Chat Streaming (SSE)

```dart
final chatStreamProvider = StreamProvider<ChatEvent>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  return repository.sendMessage(
    message: 'Hello Momo',
    stream: true,
  );
});
```

### LiveKit Integration

```dart
final liveKitProvider = Provider<LiveKitClient>((ref) {
  return LiveKitClient(
    wsUrl: EnvConfig.liveKitUrl,
    token: 'livekit-token-from-backend',
  );
});
```

## 📱 Supported Platforms

- **Android**: 11+ (API level 30+)
- **iOS**: 16.0+

## 🔒 Security

### JWT Token Management
- Token disimpan di **Secure Storage** (tidak di SharedPreferences)
- Token otomatis attached ke setiap API request
- Token refresh implementation via interceptor

### Sensitive Data
- Jangan hardcode API keys, secrets di source code
- Gunakan `.env` files
- Never commit `.env` ke repository

### API Security
- HTTPS only di production
- Certificate pinning (optional)
- Request signing (optional)

## 📊 Performance Optimization

- Lazy loading images dengan `cached_network_image`
- Minimize rebuilds dengan `Consumer` / `ConsumerWidget`
- Use `const` constructors untuk immutable widgets
- Dispose resources (controllers, listeners)
- Avoid unnecessary BackdropFilter (expensive)
- 60 FPS target

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests
flutter drive --target=test_driver/app.dart
```

## 📚 Dependencies

Key dependencies:
- `flutter_riverpod` - State management
- `go_router` - Routing
- `dio` - HTTP client
- `flutter_secure_storage` - Secure token storage
- `isar` - Local database
- `livekit_client` - Voice/WebRTC
- `cached_network_image` - Image caching
- `freezed_annotation` - Code generation
- `json_annotation` - JSON serialization

## 🔗 Links

- [Momo AI Backend](../momo-api)
- [Flutter Documentation](https://flutter.dev)
- [Riverpod Documentation](https://riverpod.dev)
- [LiveKit Documentation](https://docs.livekit.io)

## 📝 License

Proprietary - Momo AI Project

## 👥 Contributors

See `CONTRIBUTORS.md`

## 📞 Support

Untuk pertanyaan dan issues, buka GitHub issue atau hubungi tim development.
