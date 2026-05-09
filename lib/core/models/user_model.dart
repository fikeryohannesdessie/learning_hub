class UserModel {
  final String uid;
  final String email;
  final String role; // viewer, contributor, admin
  final bool? isVerified;
  final String? displayName;
  final DateTime createdAt;
  final bool? verificationSubmitted;
  final String? institution;
  final String? idNumber;
  final String? credentialFileId;
  final bool? isRejected;
  final String? verificationComment;
  final String? bio;
  final List<String>? securityAnswers;

  UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: (json['uid'] ?? json['Uid'] ?? '') as String,
      email: (json['email'] ?? json['Email'] ?? '') as String,
      role: (json['role'] ?? json['Role'] ?? 'viewer') as String,
      isVerified: (json['isVerified'] ?? json['IsVerified'] ?? false) as bool,
      displayName: (json['displayName'] ?? json['DisplayName']) as String?,
      createdAt: DateTime.tryParse((json['createdAt'] ?? json['CreatedAt'] ?? '') as String) ?? DateTime.now(),
      verificationSubmitted: (json['verificationSubmitted'] ?? json['VerificationSubmitted'] ?? false) as bool,
      institution: (json['institution'] ?? json['Institution']) as String?,
      idNumber: (json['idNumber'] ?? json['IdNumber']) as String?,
      credentialFileId: (json['credentialFileId'] ?? json['CredentialFileId']) as String?,
      isRejected: (json['isRejected'] ?? json['IsRejected'] ?? false) as bool,
      verificationComment: (json['verificationComment'] ?? json['VerificationComment']) as String?,
      bio: (json['bio'] ?? json['Bio']) as String?,
      securityAnswers: json['securityAnswers'] != null ? List<String>.from(json['securityAnswers']) : (json['SecurityAnswers'] != null ? List<String>.from(json['SecurityAnswers']) : null),
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
      'isRejected': isRejected ?? false,
      'verificationComment': verificationComment,
      'bio': bio,
      'securityAnswers': securityAnswers,
    };
  }

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
      verificationSubmitted: verificationSubmitted ?? this.verificationSubmitted,
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
