import 'package:chpa/core/constants/app_constants.dart';
import 'package:chpa/features/auth/application/auth_application.dart';
import 'package:chpa/features/auth/domain/auth_domain.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements IAuthRepository {
  final Map<String, AuthUser> usersByEmail = {};
  final Map<String, String> passwordsByEmail = {};

  bool isVerifiedPassword = true;
  bool isSecurityAnswersCorrect = true;
  bool throwOnUpdateProfile = false;
  int _idCounter = 0;

  @override
  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail == 'error@chpa.org') {
      throw Exception('Invalid credentials');
    }

    final storedPassword = passwordsByEmail[normalizedEmail];
    final user = usersByEmail[normalizedEmail];
    if (storedPassword == null || storedPassword != password || user == null) {
      throw const InvalidCredentialsFailure();
    }

    return user;
  }

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    String? displayName,
    List<String>? securityAnswers,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = AuthUser(
      uid: 'fake_uid_${_idCounter++}',
      email: normalizedEmail,
      role: role,
      createdAt: DateTime(2026, 1, 1),
      isVerified: role == AppConstants.roleViewer,
      displayName: displayName,
      securityAnswers: securityAnswers,
    );

    usersByEmail[normalizedEmail] = user;
    passwordsByEmail[normalizedEmail] = password;
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<AuthUser?> getUserData(String uid) async {
    for (final user in usersByEmail.values) {
      if (user.uid == uid) {
        return user;
      }
    }
    return null;
  }

  @override
  Stream<List<AuthUser>> getAllUsers() => Stream.value(usersByEmail.values.toList());

  @override
  Stream<List<AuthUser>> getPendingContributors() => Stream.value(
        usersByEmail.values
            .where(
              (user) =>
                  user.role == AppConstants.roleContributor &&
                  user.verificationSubmitted &&
                  !user.isVerified &&
                  !user.isRejected,
            )
            .toList(),
      );

  @override
  Future<void> submitContributorVerification(String uid) async {
    final user = await getUserData(uid);
    if (user == null) {
      return;
    }
    usersByEmail[user.email] = user.copyWith(
      verificationSubmitted: true,
      isRejected: false,
      verificationComment: null,
    );
  }

  @override
  Future<void> updateVerificationStatus(
    String uid,
    bool approved, {
    String? reason,
  }) async {
    final user = await getUserData(uid);
    if (user == null) {
      return;
    }
    usersByEmail[user.email] = user.copyWith(
      isVerified: approved,
      isRejected: !approved,
      verificationSubmitted: false,
      verificationComment: approved ? null : reason,
    );
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? institution,
    String? idNumber,
    String? credentialFileId,
    String? bio,
  }) async {
    if (throwOnUpdateProfile) {
      throw Exception('Profile update failed');
    }

    final user = await getUserData(uid);
    if (user == null) {
      return;
    }

    usersByEmail[user.email] = user.copyWith(
      displayName: displayName,
      institution: institution,
      idNumber: idNumber,
      credentialFileId: credentialFileId,
      bio: bio,
    );
  }

  @override
  Future<bool> verifyPassword(String email, String password) async =>
      isVerifiedPassword;

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    passwordsByEmail[email.trim().toLowerCase()] = newPassword;
  }

  @override
  Future<bool> verifySecurityAnswers(String email, List<String> answers) async =>
      isSecurityAnswersCorrect;

  @override
  Stream<AuthUser?> getUserByUidStream(String uid) async* {
    yield await getUserData(uid);
  }

  @override
  Future<void> deleteAccount(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    usersByEmail.remove(normalizedEmail);
    passwordsByEmail.remove(normalizedEmail);
  }
}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late ProviderContainer container;

  List<AsyncValue<void>> listenToControllerStates() {
    final states = <AsyncValue<void>>[];
    container.listen<AsyncValue<void>>(
      authControllerProvider,
      (previous, next) => states.add(next),
      fireImmediately: true,
    );
    return states;
  }

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(fakeAuthRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('initial state should be null and idle', () {
    expect(container.read(userProvider), isNull);
    expect(
      container.read(authControllerProvider),
      equals(const AsyncData<void>(null)),
    );
  });

  test('signUp creates a user, signs in, and emits loading to data', () async {
    final controller = container.read(authControllerProvider.notifier);
    final states = listenToControllerStates();

    await controller.signUp(
      email: 'new-user@chpa.org',
      password: 'password123',
      role: AppConstants.roleViewer,
      displayName: 'New User',
      securityAnswers: const ['a', 'b', 'c'],
    );

    final user = container.read(userProvider);
    expect(states.first, const AsyncData<void>(null));
    expect(states.any((state) => state.isLoading), isTrue);
    expect(states.last, const AsyncData<void>(null));
    expect(user, isNotNull);
    expect(user!.email, 'new-user@chpa.org');
    expect(user.displayName, 'New User');
    expect(fakeAuthRepository.usersByEmail.containsKey('new-user@chpa.org'), isTrue);
  });

  test('signing in successfully reads the stored user and updates state', () async {
    final controller = container.read(authControllerProvider.notifier);
    await fakeAuthRepository.signUp(
      email: 'test@chpa.org',
      password: 'password123',
      role: AppConstants.roleViewer,
      displayName: 'Stored User',
    );

    final states = listenToControllerStates();
    await controller.signIn(email: 'test@chpa.org', password: 'password123');

    final user = container.read(userProvider);
    expect(states.any((state) => state.isLoading), isTrue);
    expect(states.last, const AsyncData<void>(null));
    expect(user, isNotNull);
    expect(user!.email, 'test@chpa.org');
    expect(user.displayName, 'Stored User');
  });

  test('updateProfile updates the signed-in user and returns to data state', () async {
    final controller = container.read(authControllerProvider.notifier);
    await fakeAuthRepository.signUp(
      email: 'profile@chpa.org',
      password: 'password123',
      role: AppConstants.roleContributor,
      displayName: 'Before Update',
    );
    await controller.signIn(email: 'profile@chpa.org', password: 'password123');

    final states = listenToControllerStates();
    await controller.updateProfile(
      displayName: 'After Update',
      institution: 'CHPA Lab',
      idNumber: 'ID-2026',
      bio: 'Protecting heritage',
    );

    final user = container.read(userProvider);
    expect(states.any((state) => state.isLoading), isTrue);
    expect(states.last, const AsyncData<void>(null));
    expect(user, isNotNull);
    expect(user!.displayName, 'After Update');
    expect(user.institution, 'CHPA Lab');
    expect(user.idNumber, 'ID-2026');
    expect(user.bio, 'Protecting heritage');
  });

  test('deleteAccount removes the stored user and clears auth state', () async {
    final controller = container.read(authControllerProvider.notifier);
    await fakeAuthRepository.signUp(
      email: 'delete-me@chpa.org',
      password: 'password123',
      role: AppConstants.roleViewer,
      displayName: 'Delete Me',
    );
    await controller.signIn(email: 'delete-me@chpa.org', password: 'password123');

    final states = listenToControllerStates();
    await controller.deleteAccount();

    expect(states.any((state) => state.isLoading), isTrue);
    expect(states.last, const AsyncData<void>(null));
    expect(container.read(userProvider), isNull);
    expect(fakeAuthRepository.usersByEmail.containsKey('delete-me@chpa.org'), isFalse);
    expect(fakeAuthRepository.passwordsByEmail.containsKey('delete-me@chpa.org'), isFalse);
  });

  test('signing in with error updates controller with error state', () async {
    final controller = container.read(authControllerProvider.notifier);

    await controller.signIn(email: 'error@chpa.org', password: 'password123');

    expect(container.read(authControllerProvider), isA<AsyncError<void>>());
    expect(container.read(userProvider), isNull);
  });

  test('updateProfile error puts controller into AsyncError', () async {
    final controller = container.read(authControllerProvider.notifier);
    await fakeAuthRepository.signUp(
      email: 'broken-profile@chpa.org',
      password: 'password123',
      role: AppConstants.roleViewer,
      displayName: 'Broken Profile',
    );
    await controller.signIn(
      email: 'broken-profile@chpa.org',
      password: 'password123',
    );
    fakeAuthRepository.throwOnUpdateProfile = true;

    await controller.updateProfile(displayName: 'Should Fail');

    expect(container.read(authControllerProvider), isA<AsyncError<void>>());
    expect(container.read(userProvider)?.displayName, 'Broken Profile');
  });

  test('signing out clears user state', () async {
    final controller = container.read(authControllerProvider.notifier);
    await fakeAuthRepository.signUp(
      email: 'test@chpa.org',
      password: 'password123',
      role: AppConstants.roleViewer,
      displayName: 'Stored User',
    );

    await controller.signIn(email: 'test@chpa.org', password: 'password123');
    expect(container.read(userProvider), isNotNull);

    await controller.signOut();
    expect(container.read(userProvider), isNull);
  });
}
