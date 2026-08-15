/// User Use Cases

import '../repositories/user_repository.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/models/dto_models.dart';

/// Get Current User UseCase
class GetCurrentUserUseCase {
  final UserRepository repository;

  GetCurrentUserUseCase({required this.repository});

  Future<Result<UserProfileDto>> call() {
    return repository.getCurrentUser();
  }
}

/// Get XP Profile UseCase
class GetXpProfileUseCase {
  final UserRepository repository;

  GetXpProfileUseCase({required this.repository});

  Future<Result<XpProfileDto>> call() {
    return repository.getXpProfile();
  }
}

/// Get Relationship UseCase
class GetRelationshipUseCase {
  final UserRepository repository;

  GetRelationshipUseCase({required this.repository});

  Future<Result<RelationshipDto>> call() {
    return repository.getRelationship();
  }
}

/// Get Greeting UseCase
class GetGreetingUseCase {
  final UserRepository repository;

  GetGreetingUseCase({required this.repository});

  Future<String> call() {
    return repository.getGreeting();
  }
}

/// Update Profile UseCase
class UpdateProfileUseCase {
  final UserRepository repository;

  UpdateProfileUseCase({required this.repository});

  Future<Result<UserDto>> call(Map<String, dynamic> updates) {
    return repository.updateProfile(updates);
  }
}
