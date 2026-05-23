import '../domain/auth_domain.dart';

class AuthUserDto {
  final String uid;
  final String email;
  final String role;
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

  const AuthUserDto({
    required this.uid,
    required this.email,
    required this.role,
    required this.isVerified,
    this.displayName,
    required this.createdAt,
    required this.verificationSubmitted,
    this.institution,
    this.idNumber,
    this.credentialFileId,
    required this.isRejected,
    this.verificationComment,
    this.bio,
    this.securityAnswers,
  });

  factory AuthUserDto.fromJson(Map<String, dynamic> json) {
    return AuthUserDto(
      uid: (json['uid'] ?? json['Uid'] ?? '') as String,
      email: (json['email'] ?? json['Email'] ?? '') as String,
      role: (json['role'] ?? json['Role'] ?? 'viewer') as String,
      isVerified: (json['isVerified'] ?? json['IsVerified'] ?? false) as bool,
      displayName: (json['displayName'] ?? json['DisplayName']) as String?,
      createdAt: DateTime.tryParse((json['createdAt'] ?? json['CreatedAt'] ?? '') as String) ??
          DateTime.now(),
      verificationSubmitted:
          (json['verificationSubmitted'] ?? json['VerificationSubmitted'] ?? false) as bool,
      institution: (json['institution'] ?? json['Institution']) as String?,
      idNumber: (json['idNumber'] ?? json['IdNumber']) as String?,
      credentialFileId: (json['credentialFileId'] ?? json['CredentialFileId']) as String?,
      isRejected: (json['isRejected'] ?? json['IsRejected'] ?? false) as bool,
      verificationComment:
          (json['verificationComment'] ?? json['VerificationComment']) as String?,
      bio: (json['bio'] ?? json['Bio']) as String?,
      securityAnswers: json['securityAnswers'] != null
          ? List<String>.from(json['securityAnswers'])
          : json['SecurityAnswers'] != null
              ? List<String>.from(json['SecurityAnswers'])
              : null,
    );
  }

  factory AuthUserDto.fromRow(Map<String, dynamic> row, {List<String>? securityAnswers}) {
    return AuthUserDto(
      uid: row['uid'] as String,
      email: row['email'] as String,
      role: row['role'] as String,
      isVerified: (row['is_verified'] as int) == 1,
      displayName: row['display_name'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      verificationSubmitted: (row['verification_submitted'] as int) == 1,
      institution: row['institution'] as String?,
      idNumber: row['id_number'] as String?,
      credentialFileId: row['credential_file_id'] as String?,
      isRejected: (row['is_rejected'] as int) == 1,
      verificationComment: row['verification_comment'] as String?,
      bio: row['bio'] as String?,
      securityAnswers: securityAnswers,
    );
  }

  factory AuthUserDto.fromDomain(AuthUser user) {
    return AuthUserDto(
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

  AuthUser toDomain() {
    return AuthUser(
      uid: uid,
      email: email,
      role: role,
      isVerified: isVerified,
      displayName: displayName,
      createdAt: createdAt,
      verificationSubmitted: verificationSubmitted,
      institution: institution,
      idNumber: idNumber,
      credentialFileId: credentialFileId,
      isRejected: isRejected,
      verificationComment: verificationComment,
      bio: bio,
      securityAnswers: securityAnswers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'role': role,
      'isVerified': isVerified,
      'displayName': displayName,
      'createdAt': createdAt.toIso8601String(),
      'verificationSubmitted': verificationSubmitted,
      'institution': institution,
      'idNumber': idNumber,
      'credentialFileId': credentialFileId,
      'isRejected': isRejected,
      'verificationComment': verificationComment,
      'bio': bio,
      'securityAnswers': securityAnswers,
    };
  }

  Map<String, dynamic> toRow() {
    return {
      'uid': uid,
      'email': email,
      'display_name': displayName,
      'role': role,
      'is_verified': isVerified ? 1 : 0,
      'verification_submitted': verificationSubmitted ? 1 : 0,
      'institution': institution,
      'id_number': idNumber,
      'credential_file_id': credentialFileId,
      'is_rejected': isRejected ? 1 : 0,
      'verification_comment': verificationComment,
      'bio': bio,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
