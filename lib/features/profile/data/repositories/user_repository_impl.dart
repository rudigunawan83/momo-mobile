/// User Repository Implementation
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_remote_data_source.dart';
import '../../../../core/models/dto_models.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/exceptions.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Result<UserProfileDto>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Success(user);
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal mengambil profil pengguna',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Gagal mengambil profil pengguna',
      );
    }
  }

  @override
  Future<Result<UserDto>> getUserById(String userId) async {
    try {
      final user = await remoteDataSource.getUserById(userId);
      return Success(user);
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal mengambil data pengguna',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Gagal mengambil data pengguna',
      );
    }
  }

  @override
  Future<Result<UserDto>> updateProfile(Map<String, dynamic> updates) async {
    try {
      final user = await remoteDataSource.updateProfile(updates);
      return Success(user);
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal update profil',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Gagal update profil',
      );
    }
  }

  @override
  Future<Result<XpProfileDto>> getXpProfile() async {
    try {
      final xp = await remoteDataSource.getXpProfile();
      return Success(xp);
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal mengambil data XP',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Gagal mengambil data XP',
      );
    }
  }

  @override
  Future<Result<RelationshipDto>> getRelationship() async {
    try {
      final relationship = await remoteDataSource.getRelationship();
      return Success(relationship);
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal mengambil data relationship',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Gagal mengambil data relationship',
      );
    }
  }

  @override
  Future<Result<String?>> getCurrentMood() async {
    try {
      final mood = await remoteDataSource.getCurrentMood();
      return Success(mood);
    } on MomoException catch (e) {
      return Failure(
        exception: e,
        message: 'Gagal mengambil mood',
      );
    } catch (e) {
      return Failure(
        exception: e is Exception ? e : Exception(e.toString()),
        message: 'Gagal mengambil mood',
      );
    }
  }

  @override
  Future<String> getGreeting() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      final hour = DateTime.now().hour;

      // Greeting tergantung waktu
      String timeGreeting;
      if (hour < 12) {
        timeGreeting = 'Selamat pagi, ${user.nickname}! ☀️\nSemoga harimu menyenangkan.';
      } else if (hour < 17) {
        timeGreeting = 'Hai ${user.nickname}! 👋\nLagi sibuk atau santai hari ini?';
      } else if (hour < 21) {
        timeGreeting = 'Malam, ${user.nickname}! 🌙\nGimana harimu?';
      } else {
        timeGreeting = 'Sudah malam, ${user.nickname}! 😴\nSaatnya istirahat?';
      }

      return timeGreeting;
    } catch (e) {
      return 'Hai! 👋\nSenang bertemu lagi!';
    }
  }
}
