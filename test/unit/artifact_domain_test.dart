import 'package:flutter_test/flutter_test.dart';
import 'package:chpa/features/artifacts/domain/artifact_domain.dart';

void main() {
  group('Artifact Title Validation Tests', () {
    test('should return true for valid title', () {
      expect(ArtifactTitle.isValid('Great Obelisk'), isTrue);
      expect(ArtifactTitle.isValid('  Lalibela Church  '), isTrue);
    });

    test('should return false for empty/whitespace title', () {
      expect(ArtifactTitle.isValid(''), isFalse);
      expect(ArtifactTitle.isValid('    '), isFalse);
    });

    test('should construct and normalize valid titles', () {
      final title = ArtifactTitle('  Axum Obelisk  ');
      expect(title.value, equals('Axum Obelisk'));
    });

    test('should throw InvalidArtifactFieldFailure for invalid titles', () {
      expect(
        () => ArtifactTitle('  '),
        throwsA(isA<InvalidArtifactFieldFailure>()),
      );
    });
  });

  group('Artifact Description Validation Tests', () {
    test('should construct and normalize valid description', () {
      final desc = ArtifactDescription('  A historic artifact.  ');
      expect(desc.value, equals('A historic artifact.'));
    });

    test('should throw InvalidArtifactFieldFailure for empty description', () {
      expect(
        () => ArtifactDescription(''),
        throwsA(isA<InvalidArtifactFieldFailure>()),
      );
    });
  });

  group('Artifact Narrative Validation Tests', () {
    test('should construct valid narrative', () {
      final narrative = ArtifactNarrative('Deep narrative about the history.');
      expect(narrative.value, equals('Deep narrative about the history.'));
    });

    test('should throw InvalidArtifactFieldFailure for empty narrative', () {
      expect(
        () => ArtifactNarrative(' '),
        throwsA(isA<InvalidArtifactFieldFailure>()),
      );
    });
  });

  group('HeritageSignificanceList Validation Tests', () {
    test('should normalize multi-line inputs correctly', () {
      const input = '  Significance 1  \n\n  Significance 2  ';
      final list = HeritageSignificanceList(input);
      expect(list.value, equals(['Significance 1', 'Significance 2']));
    });

    test('should throw InvalidArtifactFieldFailure if significance list is empty', () {
      expect(
        () => HeritageSignificanceList('\n  \n'),
        throwsA(isA<InvalidArtifactFieldFailure>()),
      );
    });
  });

  group('createArtifactDraft Builder Tests', () {
    test('should successfully construct Artifact with valid fields', () {
      final artifact = createArtifactDraft(
        id: 'art_123',
        title: 'Fasil Ghebbi',
        description: 'Castles of Gondar',
        authorId: 'auth_999',
        authorName: 'Abebe',
        sections: [],
        createdAt: DateTime(2024, 1, 1),
        detailedDescription: 'Detailed castle historical description.',
        heritageSignificanceText: 'Historical value\nArchitectural value',
      );

      expect(artifact.id, equals('art_123'));
      expect(artifact.title, equals('Fasil Ghebbi'));
      expect(artifact.description, equals('Castles of Gondar'));
      expect(artifact.authorId, equals('auth_999'));
      expect(artifact.authorName, equals('Abebe'));
      expect(artifact.detailedDescription, equals('Detailed castle historical description.'));
      expect(artifact.heritageSignificance, equals(['Historical value', 'Architectural value']));
      expect(artifact.status, equals('pending'));
    });

    test('should throw exception if builder gets invalid field values', () {
      expect(
        () => createArtifactDraft(
          id: 'art_123',
          title: '   ',
          description: 'Valid description',
          authorId: 'auth_999',
          authorName: 'Abebe',
          sections: [],
          createdAt: DateTime(2024, 1, 1),
          detailedDescription: 'Detailed description',
          heritageSignificanceText: 'Significance',
        ),
        throwsA(isA<InvalidArtifactFieldFailure>()),
      );
    });
  });

  group('UserProgress Calculation Tests', () {
    test('calculateOverallProgress should return correct percent or 0 if total is 0', () {
      final progress = UserProgress(
        userId: 'u_1',
        artifactId: 'a_1',
        completedContentIds: ['c_1', 'c_2'],
        lastAccessedAt: DateTime.now(),
      );

      expect(progress.calculateOverallProgress(4), equals(50.0));
      expect(progress.calculateOverallProgress(0), equals(0.0));
    });

    test('hasPassedArtifact should correctly evaluate pass mark (>= 70%)', () {
      final progress = UserProgress(
        userId: 'u_1',
        artifactId: 'a_1',
        analysisScores: {
          'sec_1': 80,
          'sec_2': 60,
        },
        lastAccessedAt: DateTime.now(),
      );

      // Average score is (80+60)/2 = 70.0. Should pass.
      expect(progress.hasPassedArtifact(2), isTrue);

      final progressFailed = UserProgress(
        userId: 'u_1',
        artifactId: 'a_1',
        analysisScores: {
          'sec_1': 60,
          'sec_2': 60,
        },
        lastAccessedAt: DateTime.now(),
      );
      // Average score is 60. Should fail.
      expect(progressFailed.hasPassedArtifact(2), isFalse);

      // Should return false if not all analyses completed
      expect(progress.hasPassedArtifact(3), isFalse);

      // Should return true if totalAnalyses is 0
      expect(progress.hasPassedArtifact(0), isTrue);
    });

    test('calculateAverageScore should return mean of analysis scores', () {
      final progress = UserProgress(
        userId: 'u_1',
        artifactId: 'a_1',
        analysisScores: {
          'sec_1': 90,
          'sec_2': 70,
          'sec_3': 80,
        },
        lastAccessedAt: DateTime.now(),
      );

      expect(progress.calculateAverageScore(), equals(80.0));

      final emptyProgress = UserProgress(
        userId: 'u_1',
        artifactId: 'a_1',
        analysisScores: {},
        lastAccessedAt: DateTime.now(),
      );
      expect(emptyProgress.calculateAverageScore(), equals(0.0));
    });
  });
}
