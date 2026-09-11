import 'package:flutter_test/flutter_test.dart';
import 'package:deepfake_shield/models/analysis_result.dart';

void main() {
  group('VerifyResult Tests', () {
    test('DOĞRULANDI response marked as isRegistered', () {
      final res = VerifyResult.fromJson({
        'durum': 'DOĞRULANDI',
        'mesaj': 'Medya blokzincirinde doğrulandı',
        'veri': {
          'dosya_adi': 'test.jpg',
          'zaman': '2026-09-12 01:00:00',
        }
      });

      expect(res.isRegistered, isTrue);
      expect(res.isNotRegistered, isFalse);
    });

    test('KAYITLI response marked as isRegistered', () {
      final res = VerifyResult.fromJson({
        'durum': 'KAYITLI',
        'mesaj': 'Kayıt onaylandı',
      });

      expect(res.isRegistered, isTrue);
      expect(res.isNotRegistered, isFalse);
    });

    test('BULUNAMADI response marked as isNotRegistered', () {
      final res = VerifyResult.fromJson({
        'durum': 'BULUNAMADI',
        'mesaj': 'Kayıt bulunamadı',
      });

      expect(res.isRegistered, isFalse);
      expect(res.isNotRegistered, isTrue);
    });

    test('KAYITSIZ response marked as isNotRegistered', () {
      final res = VerifyResult.fromJson({
        'durum': 'KAYITSIZ',
        'mesaj': 'Kayıtsız medya',
      });

      expect(res.isRegistered, isFalse);
      expect(res.isNotRegistered, isTrue);
    });
  });
}
