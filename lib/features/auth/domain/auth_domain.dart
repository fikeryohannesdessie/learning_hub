class AuthUser {
  final String uid;
  final String email;
  final String role; // viewer, contributor, admin
  final bool isVerified;
  final String? displayName;
  final DateTime createdAt;
  final bool verificationSubmitted;
  final String? institution;
  final String? idNumber;
  final String? credentialFileId;
  final bool isRejected;
  final String? verificationComment;
  final String? bio;
  final List<String>? securityAnswers;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.role,
    this.isVerified = false,
    this.displayName,
    required this.createdAt,
    this.verificationSubmitted = false,
    this.institution,
    this.idNumber,
    this.credentialFileId,
    this.isRejected = false,
    this.verificationComment,
    this.bio,
    this.securityAnswers,
  });

  AuthUser copyWith({
    String? uid,
    String? email,
    String? role,
    bool? isVerified,
    String? displayName,
    DateTime? createdAt,
    bool? verificationSubmitted,
    String? institution,
    String? idNumber,
    String? credentialFileId,
    bool? isRejected,
    String? verificationComment,
    String? bio,
    List<String>? securityAnswers,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
      verificationSubmitted:
          verificationSubmitted ?? this.verificationSubmitted,
      institution: institution ?? this.institution,
      idNumber: idNumber ?? this.idNumber,
      credentialFileId: credentialFileId ?? this.credentialFileId,
      isRejected: isRejected ?? this.isRejected,
      verificationComment: verificationComment ?? this.verificationComment,
      bio: bio ?? this.bio,
      securityAnswers: securityAnswers ?? this.securityAnswers,
    );
  }
}

class EmailAddress {
  EmailAddress._(this.value);

  final String value;

  static final RegExp _pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValid(String input) {
    return _pattern.hasMatch(input.trim().toLowerCase());
  }

  factory EmailAddress(String input) {
    final normalized = input.trim().toLowerCase();
    if (!isValid(normalized)) {
      throw const InvalidEmailFailure();
    }
    return EmailAddress._(normalized);
  }

  @override
  String toString() => value;
}

class Password {
  Password._(this.value);

  final String value;

  static const int minLength = 6;

  static bool isValid(String input) {
    return input.trim().length >= minLength;
  }

  factory Password(String input) {
    final normalized = input.trim();
    if (!isValid(normalized)) {
      throw const InvalidPasswordFailure();
    }
    return Password._(normalized);
  }

  @override
  String toString() => value;
}

sealed class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class InvalidEmailFailure extends AuthFailure {
  const InvalidEmailFailure() : super('Please enter a valid email address.');
}

class InvalidPasswordFailure extends AuthFailure {
  const InvalidPasswordFailure()
      : super('Password must be at least 6 characters long.');
}

class DuplicateUserFailure extends AuthFailure {
  const DuplicateUserFailure()
      : super('A user with this email already exists.');
}

class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure()
      : super('Invalid email or password.');
}

class UserNotFoundFailure extends AuthFailure {
  const UserNotFoundFailure() : super('User not found.');
}

abstract class IAuthRepository {
  Future<void> signUp({
    required String email,
    required String password,
    required String role,
    String? displayName,
    List<String>? securityAnswers,
  });

  Future<AuthUser?> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<AuthUser?> getUserData(String uid);

  Stream<List<AuthUser>> getAllUsers();

  Stream<List<AuthUser>> getPendingContributors();

  Future<void> submitContributorVerification(String uid);

  Future<void> updateVerificationStatus(
    String uid,
    bool approved, {
    String? reason,
  });

  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? institution,
    String? idNumber,
    String? credentialFileId,
    String? bio,
  });

  Future<bool> verifyPassword(String email, String password);

  Future<void> resetPassword(String email, String newPassword);

  Future<bool> verifySecurityAnswers(String email, List<String> answers);

  Stream<AuthUser?> getUserByUidStream(String uid);

  Future<void> deleteAccount(String email);
}
