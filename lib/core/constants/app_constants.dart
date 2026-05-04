class AppConstants {
  // App Info
  static const String appName = 'CHPA';
  static const String appVersion = '1.0.0';

  // User Roles
  static const String roleViewer = 'viewer';
  static const String roleContributor = 'contributor';
  static const String roleAdmin = 'admin';

  // Content Types
  static const String contentTypeArtifact = 'artifact';
  static const String contentTypeDocument = 'document';
  static const String contentTypeMedia = 'media';
  static const String contentTypeAnalysis = 'analysis';
  static const String contentTypeVideo = 'video';
  static const String contentTypeAudio = 'audio';
  static const String contentTypeText = 'text';
  static const String contentTypeImage = 'image';
  
  // Legacy Content Type Aliases
  static const String contentTypePDF = 'pdf';
  static const String contentTypeWorksheet = 'worksheet';

  // Content Status
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';

  // Heritage Classifications (replacing Grade Levels)
  static const String classTangible = 'tangible';
  static const String classIntangible = 'intangible';
  
  // Legacy Grade Level Aliases
  static const String gradeLevelHighSchool = 'tangible';
  static const String gradeLevelCollege = 'intangible';
  static const String gradeLevelUniversity = 'intangible';
  
  // Legacy Classification Aliases
  static const String classificationTangible = 'tangible';
  static const String classificationIntangible = 'intangible';

  // Collections (Firestore)
  static const String usersCollection = 'users';
  static const String artifactsCollection = 'artifacts';
  static const String analysesCollection = 'analyses';
  static const String bookmarksCollection = 'bookmarks';

  // Storage Paths (Firebase Storage)
  static const String artifactStoragePath = 'artifacts';
  static const String docStoragePath = 'documents';
  static const String profilePicsPath = 'profile_pics';
  
  // Native heritage simulations
  static const String defaultHeritageSimulationId = 'lalibela';

  // Local Storage Keys (Hive)
  static const String userBoxName = 'userBox';
  static const String artifactBoxName = 'artifactBox';
  static const String bookmarkBoxName = 'bookmarkBox';

  // Validation
  static const int maxPDFSizeMB = 50;
  static const int minPasswordLength = 6;
}
