import 'package:flutter_test/flutter_test.dart';

import 'package:client_hp/utils/formatters.dart';
import 'package:client_hp/utils/validators.dart';

void main() {
  group('validators', () {
    test('email wajib dan harus valid', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('bukan-email'), isNotNull);
      expect(validateEmail('user@mail.com'), isNull);
    });

    test('password minimal 8 karakter', () {
      expect(validatePassword('1234567'), isNotNull);
      expect(validatePassword('12345678'), isNull);
    });

    test('username minimal 3 karakter', () {
      expect(validateUsername('ab'), isNotNull);
      expect(validateUsername('abc'), isNull);
    });

    test('harga harus angka lebih dari 0', () {
      expect(validatePrice(''), isNotNull);
      expect(validatePrice('abc'), isNotNull);
      expect(validatePrice('0'), isNotNull);
      expect(validatePrice('25000'), isNull);
      expect(validatePrice('25.000'), isNull);
    });

    test('stok harus angka dan tidak negatif', () {
      expect(validateStock(''), isNotNull);
      expect(validateStock('-1'), isNotNull);
      expect(validateStock('0'), isNull);
    });
  });

  group('formatters', () {
    test('format rupiah memakai pemisah ribuan', () {
      expect(formatRupiah(25000), 'Rp 25.000');
      expect(formatRupiah(1000000), 'Rp 1.000.000');
    });
  });
}
