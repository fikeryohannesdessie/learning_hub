import 'package:chpa/core/constants/app_constants.dart';
import 'package:chpa/features/auth/application/auth_application.dart';
import 'package:chpa/features/auth/domain/auth_domain.dart';
import 'package:chpa/features/auth/presentation/profile_screen.dart';
import 'package:chpa/features/auth/presentation/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements IAuthRepository {
  final Map<String, AuthUser> usersByEmail = {};
  final Map<String, String> passwordsByEmail = {};

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
      uid: 'uid_${usersByEmail.length + 1}',
      email: normalizedEmail,
      role: role,
      isVerified: role == AppConstants.roleViewer,
      displayName: displayName,
      createdAt: DateTime(2026, 1, 1),
      securityAnswers: securityAnswers,
    );
    usersByEmail[normalizedEmail] = user;
    passwordsByEmail[normalizedEmail] = password;
  }

  @override
  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = usersByEmail[normalizedEmail];
    if (user == null || passwordsByEmail[normalizedEmail] != password) {
      throw const InvalidCredentialsFailure();
    }
    return user;
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
  Stream<List<AuthUser>> getPendingContributors() => Stream.value(const []);

  @override
  Future<void> submitContributorVerification(String uid) async {}

  @override
  Future<void> updateVerificationStatus(
    String uid,
    bool approved, {
    String? reason,
  }) async {}

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? institution,
    String? idNumber,
    String? credentialFileId,
    String? bio,
  }) async {
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
  Future<bool> verifyPassword(String email, String password) async {
    return passwordsByEmail[email.trim().toLowerCase()] == password;
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    passwordsByEmail[email.trim().toLowerCase()] = newPassword;
  }

  @override
  Future<bool> verifySecurityAnswers(String email, List<String> answers) async =>
      true;

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

  Future<void> pumpWithProviders(
    WidgetTester tester,
    Widget child,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: child),
      ),
    );
    await tester.pump();
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

  testWidgets('SignupScreen creates a user through the auth controller', (
    WidgetTester tester,
  ) async {
    await pumpWithProviders(tester, const SignupScreen());

    final textFields = find.byType(TextFormField);
    expect(textFields, findsNWidgets(6));

    await tester.enterText(textFields.at(0), 'Ada Lovelace');
    await tester.enterText(textFields.at(1), 'ada@chpa.org');
    await tester.enterText(textFields.at(2), 'password123');
    await tester.enterText(textFields.at(3), 'Byron');
    await tester.enterText(textFields.at(4), 'Puff');
    await tester.enterText(textFields.at(5), 'London');

    await tester.tap(find.text('Create Account').last);
    await tester.pumpAndSettle();

    final createdUser = container.read(userProvider);
    expect(createdUser, isNotNull);
    expect(createdUser!.email, 'ada@chpa.org');
    expect(createdUser.displayName, 'Ada Lovelace');
    expect(fakeAuthRepository.usersByEmail.containsKey('ada@chpa.org'), isTrue);
    expect(
      find.text('Account created. Please submit your verification.'),
      findsOneWidget,
    );
  });

  testWidgets('ProfileScreen updates the signed-in user details', (
    WidgetTester tester,
  ) async {
    const email = 'profile@chpa.org';
    await fakeAuthRepository.signUp(
      email: email,
      password: 'password123',
      role: AppConstants.roleContributor,
      displayName: 'Original Name',
    );
    final user = fakeAuthRepository.usersByEmail[email]!;
    container.read(authStateProvider.notifier).setUser(user);

    await pumpWithProviders(tester, const ProfileScreen());

    expect(find.text('Original Name'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_note));
    await tester.pumpAndSettle();

    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Updated Name');
    await tester.enterText(textFields.at(1), 'CHPA Institute');
    await tester.enterText(textFields.at(2), 'Updated contributor bio');

    await tester.tap(find.text('SAVE CHANGES'));
    await tester.pumpAndSettle();

    final updatedUser = fakeAuthRepository.usersByEmail[email];
    expect(updatedUser, isNotNull);
    expect(updatedUser!.displayName, 'Updated Name');
    expect(updatedUser.institution, 'CHPA Institute');
    expect(updatedUser.bio, 'Updated contributor bio');
    expect(find.text('Profile updated successfully!'), findsOneWidget);
  });

  testWidgets('ProfileScreen deletes the signed-in account after password check', (
    WidgetTester tester,
  ) async {
    const email = 'delete@chpa.org';
    await fakeAuthRepository.signUp(
      email: email,
      password: 'password123',
      role: AppConstants.roleViewer,
      displayName: 'Delete Target',
    );
    final user = fakeAuthRepository.usersByEmail[email]!;
    container.read(authStateProvider.notifier).setUser(user);

    await pumpWithProviders(tester, const ProfileScreen());

    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete Account').last);
    await tester.pumpAndSettle();

    expect(container.read(userProvider), isNull);
    expect(fakeAuthRepository.usersByEmail.containsKey(email), isFalse);
    expect(fakeAuthRepository.passwordsByEmail.containsKey(email), isFalse);
  });
}
