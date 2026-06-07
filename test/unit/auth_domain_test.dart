import 'package:flutter_test/flutter_test.dart';
import 'package:chpa/features/auth/domain/auth_domain.dart';

void main() {
  group('EmailAddress Validation Tests', () {
    test('should return true for valid email format', () {
      expect(EmailAddress.isValid('test@example.com'), isTrue);
      expect(EmailAddress.isValid('user.name+tag@domain.co.uk'), isTrue);
    });

    test('should return false for invalid email format', () {
      expect(EmailAddress.isValid('testexample.com'), isFalse);
      expect(EmailAddress.isValid('test@'), isFalse);
      expect(EmailAddress.isValid('test@example'), isFalse);
      expect(EmailAddress.isValid('  '), isFalse);
    });

    test('should succeed and normalize when creating a valid EmailAddress instance', () {
      final email = EmailAddress('  TEST@Example.COM  ');
      expect(email.value, equals('test@example.com'));
    });

    test('should throw InvalidEmailFailure when creating an invalid EmailAddress instance', () {
      expect(() => EmailAddress('invalid-email'), throwsA(isA<InvalidEmailFailure>()));
    });
  });

  group('Password Validation Tests', () {
    test('should return true for passwords with length >= 6', () {
      expect(Password.isValid('123456'), isTrue);
      expect(Password.isValid('abcdefg'), isTrue);
    });

    test('should return false for passwords with length < 6', () {
      expect(Password.isValid('12345'), isFalse);
      expect(Password.isValid(''), isFalse);
      expect(Password.isValid('  '), isFalse);
    });

    test('should succeed when creating a valid Password instance', () {
      final password = Password('secure123');
      expect(password.value, equals('secure123'));
    });

    test('should throw InvalidPasswordFailure when creating an invalid Password instance', () {
      expect(() => Password('123'), throwsA(isA<InvalidPasswordFailure>()));
    });
  });
}
