import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/storage/database_helper.dart';
import '../domain/auth_domain.dart';
import 'auth_dto.dart';

class AuthLocalDataSource {
  Future<void> _ensureDbReady() => DatabaseHelper.init();

  String normalizeEmail(String email) => email.trim().toLowerCase();

  AuthUser mapRowToUser(Map<String, dynamic> row) {
    final rawAnswers = row['security_answers'] as String?;
    List<String>? answers;
    if (rawAnswers != null && rawAnswers.isNotEmpty) {
      answers = List<String>.from(jsonDecode(rawAnswers));
    }

    return AuthUserDto.fromRow(row, securityAnswers: answers).toDomain();
  }

  Map<String, dynamic> mapUserToRow(AuthUser user) {
    final row = AuthUserDto.fromDomain(user).toRow();
    row['email'] = normalizeEmail(user.email);
    row['security_answers'] =
        user.securityAnswers != null ? jsonEncode(user.securityAnswers) : null;
    return row;
  }

  Future<void> seedAdminIfNeeded() async {
    await _ensureDbReady();
    const email = 'admin@chpa.org';
    const password = 'admin123';

    final existing = await db.getUserByEmail(email);
    if (existing == null) {
      final admin = AuthUser(
        uid: 'hardcoded_admin_01',
        email: email,
        role: AppConstants.roleAdmin,
        isVerified: true,
        displayName: 'Heritage Admin',
        createdAt: DateTime(2024, 1, 1),
      );
      await db.upsertUser(mapUserToRow(admin));
      await db.upsertPassword(email, password);
      debugPrint('SQLite: admin account created - $email');
      return;
    }

    final user = mapRowToUser(existing);
    if (user.role != AppConstants.roleAdmin || !user.isVerified) {
      await db.updateUser(user.uid, {
        'role': AppConstants.roleAdmin,
        'is_verified': 1,
      });
      debugPrint('SQLite: admin account repaired - $email');
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String role,
    String? displayName,
    List<String>? securityAnswers,
  }) async {
    await _ensureDbReady();
    final normalized = EmailAddress(email).value;
    final existing = await db.getUserByEmail(normalized);
    if (existing != null) {
      throw const DuplicateUserFailure();
    }

    final user = AuthUser(
      uid: 'local_${DateTime.now().millisecondsSinceEpoch}',
      email: normalized,
      role: role,
      isVerified: role == AppConstants.roleViewer,
      displayName: displayName,
      createdAt: DateTime.now(),
      verificationSubmitted: false,
      securityAnswers: securityAnswers,
    );

    await db.upsertUser(mapUserToRow(user));
    await db.upsertPassword(normalized, password);
    debugPrint('SQLite: signed up $normalized as $role');
  }

  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    await _ensureDbReady();
    final normalized = EmailAddress(email).value;
    final storedPassword = await db.getPassword(normalized);

    if (storedPassword == null || storedPassword != password) {
      throw const InvalidCredentialsFailure();
    }

    final row = await db.getUserByEmail(normalized);
    if (row == null) {
      return null;
    }

    final user = mapRowToUser(row);
    debugPrint('SQLite: signed in ${user.email} (${user.role})');
    return user;
  }

  Future<AuthUser?> getUserByUid(String uid) async {
    await _ensureDbReady();
    final row = await db.getUserByUid(uid);
    return row == null ? null : mapRowToUser(row);
  }

  Future<List<AuthUser>> getAllUsers() async {
    await _ensureDbReady();
    final rows = await db.getAllUsers();
    return rows.map(mapRowToUser).toList();
  }

  Future<List<AuthUser>> getPendingContributors() async {
    final all = await getAllUsers();
    return all.where((user) {
      return user.role == AppConstants.roleContributor &&
          user.verificationSubmitted &&
          !user.isRejected &&
          !user.isVerified;
    }).toList();
  }

  Future<void> submitContributorVerification(String uid) async {
    await _ensureDbReady();
    await db.updateUser(uid, {
      'verification_submitted': 1,
      'is_rejected': 0,
      'verification_comment': null,
    });
    debugPrint('SQLite: verification submitted for $uid');
  }

  Future<void> updateVerificationStatus(
    String uid,
    bool approved, {
    String? reason,
  }) async {
    await _ensureDbReady();
    await db.updateUser(uid, {
      'is_verified': approved ? 1 : 0,
      'is_rejected': approved ? 0 : 1,
      'verification_submitted': 0,
      'verification_comment': approved
          ? null
          : (reason ??
              'Your credentials could not be verified. Please ensure the documents are clear and valid.'),
    });
    debugPrint(
      'SQLite: verification ${approved ? 'approved' : 'rejected'} for $uid',
    );
  }

  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? institution,
    String? idNumber,
    String? bio,
    String? credentialFileId,
  }) async {
    await _ensureDbReady();
    final fields = <String, dynamic>{};
    if (displayName != null) fields['display_name'] = displayName;
    if (institution != null) fields['institution'] = institution;
    if (idNumber != null) fields['id_number'] = idNumber;
    if (bio != null) fields['bio'] = bio;
    if (credentialFileId != null) {
      fields['credential_file_id'] = credentialFileId;
    }

    if (fields.isEmpty) {
      return;
    }

    await db.updateUser(uid, fields);
    debugPrint('SQLite: profile updated for $uid');
  }

  Future<bool> verifyPassword(String email, String password) async {
    await _ensureDbReady();
    final stored = await db.getPassword(normalizeEmail(email));
    return stored == password;
  }

  Future<void> resetPassword(String email, String newPassword) async {
    await _ensureDbReady();
    final normalized = EmailAddress(email).value;
    final row = await db.getUserByEmail(normalized);
    if (row == null) {
      throw const UserNotFoundFailure();
    }
    await db.upsertPassword(normalized, newPassword);
    debugPrint('SQLite: password reset for $email');
  }

  Future<bool> verifySecurityAnswers(String email, List<String> answers) async {
    await _ensureDbReady();
    final normalized = normalizeEmail(email);
    final row = await db.getUserByEmail(normalized);
    if (row == null) {
      return false;
    }

    final user = mapRowToUser(row);
    final stored = user.securityAnswers;
    if (stored == null || stored.length != 3 || answers.length != 3) {
      return false;
    }

    for (var index = 0; index < 3; index++) {
      if (stored[index].trim().toLowerCase() !=
          answers[index].trim().toLowerCase()) {
        return false;
      }
    }
    return true;
  }

  Future<void> deleteAccount(String email) async {
    await _ensureDbReady();
    final normalized = normalizeEmail(email);
    await db.deleteUser(normalized);
    await db.deletePassword(normalized);
    debugPrint('SQLite: account deleted - $email');
  }
}

class AuthRemoteDataSource {
  const AuthRemoteDataSource();

  Future<void> syncAuthState(AuthUser? user) async {
    // Placeholder for Firebase/Auth API integration. Keeping it a no-op
    // preserves current offline-first behaviour while aligning with DDD.
    return;
  }
}

class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl({
    required AuthLocalDataSource localDataSource,
    required AuthRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource {
    unawaited(_localDataSource.seedAdminIfNeeded());
  }

  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;
  final StreamController<void> _controller = StreamController<void>.broadcast();

  void _notify() => _controller.add(null);

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    String? displayName,
    List<String>? securityAnswers,
  }) async {
    await _localDataSource.createUser(
      email: email,
      password: password,
      role: role,
      displayName: displayName,
      securityAnswers: securityAnswers,
    );
    _notify();
  }

  @override
  Future<AuthUser?> signIn({
    required String email,
    required String password,
  }) async {
    final user = await _localDataSource.signIn(email: email, password: password);
    await _remoteDataSource.syncAuthState(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await _remoteDataSource.syncAuthState(null);
  }

  @override
  Future<AuthUser?> getUserData(String uid) {
    return _localDataSource.getUserByUid(uid);
  }

  @override
  Stream<List<AuthUser>> getAllUsers() async* {
    yield await _localDataSource.getAllUsers();
    await for (final _ in _controller.stream) {
      yield await _localDataSource.getAllUsers();
    }
  }

  @override
  Stream<List<AuthUser>> getPendingContributors() async* {
    yield await _localDataSource.getPendingContributors();
    await for (final _ in _controller.stream) {
      yield await _localDataSource.getPendingContributors();
    }
  }

  @override
  Future<void> submitContributorVerification(String uid) async {
    await _localDataSource.submitContributorVerification(uid);
    _notify();
  }

  @override
  Future<void> updateVerificationStatus(
    String uid,
    bool approved, {
    String? reason,
  }) async {
    await _localDataSource.updateVerificationStatus(
      uid,
      approved,
      reason: reason,
    );
    _notify();
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
    await _localDataSource.updateUserProfile(
      uid: uid,
      displayName: displayName,
      institution: institution,
      idNumber: idNumber,
      credentialFileId: credentialFileId,
      bio: bio,
    );
    _notify();
  }

  @override
  Future<bool> verifyPassword(String email, String password) {
    return _localDataSource.verifyPassword(email, password);
  }

  @override
  Future<void> resetPassword(String email, String newPassword) {
    return _localDataSource.resetPassword(email, newPassword);
  }

  @override
  Future<bool> verifySecurityAnswers(String email, List<String> answers) {
    return _localDataSource.verifySecurityAnswers(email, answers);
  }

  @override
  Stream<AuthUser?> getUserByUidStream(String uid) async* {
    yield await _localDataSource.getUserByUid(uid);
    await for (final _ in _controller.stream) {
      yield await _localDataSource.getUserByUid(uid);
    }
  }

  @override
  Future<void> deleteAccount(String email) async {
    await _localDataSource.deleteAccount(email);
    _notify();
  }
}
