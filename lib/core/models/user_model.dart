import '../../features/auth/domain/auth_domain.dart';

class UserModel extends AuthUser {
  UserModel({
    required super.uid,
    required super.email,
    required super.role,
    super.isVerified,
    super.displayName,
    required super.createdAt,
    super.verificationSubmitted,
    super.institution,
    super.idNumber,
    super.credentialFileId,
    super.isRejected,
    super.verificationComment,
    super.bio,
    super.securityAnswers,
  });

  factory UserModel.fromDomain(AuthUser user) {
    return UserModel(
      uid: user.uid,
      email: user.email,
      role: user.role,
      isVerified: user.isVerified,
      displayName: user.displayName,
      createdAt: user.createdAt,
      verificationSubmitted: user.verificationSubmitted,
      institution: user.institution,
      idNumber: user.idNumber,
      credentialFileId: user.credentialFileId,
      isRejected: user.isRejected,
      verificationComment: user.verificationComment,
      bio: user.bio,
      securityAnswers: user.securityAnswers,
    );
  }

  @override
  UserModel copyWith({
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
    return UserModel(
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
