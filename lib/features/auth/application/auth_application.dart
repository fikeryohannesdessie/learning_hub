import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../domain/auth_domain.dart';
import '../infrastructure/auth_infrastructure.dart';
import '../../content/application/content_application.dart';
import '../../content/domain/content_domain.dart';

final authLocalDataSourceProvider = Provider<AuthLocalDataSource>((ref) {
  return AuthLocalDataSource();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return const AuthRemoteDataSource();
});

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  return AuthRepositoryImpl(
    localDataSource: ref.watch(authLocalDataSourceProvider),
    remoteDataSource: ref.watch(authRemoteDataSourceProvider),
  );
});

final authStateProvider =
    NotifierProvider<AuthStateController, AuthUser?>(AuthStateController.new);

final userProvider = Provider<AuthUser?>((ref) {
  return ref.watch(authStateProvider);
});

final userByUidProvider = StreamProvider.family<AuthUser?, String>((ref, uid) {
  return ref.watch(authRepositoryProvider).getUserByUidStream(uid);
});

final pendingContributorsProvider = StreamProvider<List<AuthUser>>((ref) {
  return ref.watch(authRepositoryProvider).getPendingContributors();
});

final pendingVerificationsProvider =
    StreamProvider<List<LearningContent>>((ref) {
  return ref.watch(contentRepositoryProvider).getPendingContent().map((items) {
    return items
        .where((content) => content.subject == 'Contributor Verification')
        .toList();
  });
});

final allUsersProvider = StreamProvider<List<AuthUser>>((ref) {
  return ref.watch(authRepositoryProvider).getAllUsers();
});

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);

class AuthStateController extends Notifier<AuthUser?> {
  @override
  AuthUser? build() => null;

  void setUser(AuthUser? user) => state = user;
}

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  IAuthRepository get _repository => ref.read(authRepositoryProvider);

  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    String? displayName,
    List<String>? securityAnswers,
    bool signInAfterSignUp = true,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.signUp(
        email: email,
        password: password,
        role: role,
        displayName: displayName,
        securityAnswers: securityAnswers,
      );
      if (signInAfterSignUp) {
        await signIn(email: email, password: password);
      } else {
        state = const AsyncData(null);
      }
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repository.signIn(email: email, password: password);
      if (user != null) {
        ref.read(authStateProvider.notifier).setUser(user);
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> continueAsGuest(String role) async {
    state = const AsyncLoading();
    final guest = AuthUser(
      uid: 'guest_${role}_user',
      email: 'guest_$role@example.com',
      role: role,
      isVerified: true,
      displayName: 'Guest ${role[0].toUpperCase()}${role.substring(1)}',
      createdAt: DateTime.now(),
    );
    ref.read(authStateProvider.notifier).setUser(guest);
    state = const AsyncData(null);
  }

  Future<void> submitVerification(String uid) async {
    state = const AsyncLoading();
    try {
      await _repository.submitContributorVerification(uid);
      final current = ref.read(authStateProvider);
      if (current != null && current.uid == uid) {
        final updated = await _repository.getUserData(uid);
        if (updated != null) {
          ref.read(authStateProvider.notifier).setUser(updated);
        }
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProfile({
    String? displayName,
    String? institution,
    String? idNumber,
    String? credentialFileId,
    String? bio,
  }) async {
    final user = ref.read(authStateProvider);
    if (user == null) {
      return;
    }

    state = const AsyncLoading();
    try {
      await _repository.updateUserProfile(
        uid: user.uid,
        displayName: displayName,
        institution: institution,
        idNumber: idNumber,
        credentialFileId: credentialFileId,
        bio: bio,
      );
      final updated = await _repository.getUserData(user.uid);
      if (updated != null) {
        ref.read(authStateProvider.notifier).setUser(updated);
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    ref.read(authStateProvider.notifier).setUser(null);
  }

  Future<bool> verifyPassword(String password) async {
    final user = ref.read(authStateProvider);
    if (user == null) {
      return false;
    }
    return _repository.verifyPassword(user.email, password);
  }

  Future<void> resetPassword(String email, String newPassword) async {
    state = const AsyncLoading();
    try {
      await _repository.resetPassword(email, newPassword);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<bool> verifySecurityAnswers(
    String email,
    List<String> answers,
  ) {
    return _repository.verifySecurityAnswers(email, answers);
  }

  Future<void> deleteAccount() async {
    final user = ref.read(authStateProvider);
    if (user == null) {
      return;
    }

    state = const AsyncLoading();
    try {
      final email = user.email;
      await signOut();
      await _repository.deleteAccount(email);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> adminDeleteUser(String email) async {
    state = const AsyncLoading();
    try {
      final allUsers = await _repository.getAllUsers().first;
      final target = allUsers.firstWhere((user) => user.email == email);

      await ref
          .read(contentRepositoryProvider)
          .deleteContentByAuthorId(target.uid);

      await _repository.deleteAccount(email);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateVerificationStatus(
    String uid,
    bool approved, {
    String? reason,
  }) async {
    state = const AsyncLoading();
    try {
      await _repository.updateVerificationStatus(
        uid,
        approved,
        reason: reason,
      );
      final current = ref.read(authStateProvider);
      if (current != null && current.uid == uid) {
        final updated = await _repository.getUserData(uid);
        if (updated != null) {
          ref.read(authStateProvider.notifier).setUser(updated);
        }
      }
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

bool isContributorRole(String role) => role == AppConstants.roleContributor;
