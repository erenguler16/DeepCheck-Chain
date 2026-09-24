import 'package:flutter_test/flutter_test.dart';
import 'package:deepfake_shield/services/api_service.dart';

void main() {
  group('HealthCheck Live Test', () {
    test('checkHealth successfully connects to current backend', () async {
      final status = await ApiService.checkHealth();
      // Server is currently active on ngrok
      expect(status.isOnline, isTrue);
      expect(status.message.isNotEmpty, isTrue);
      // Verify message matches our hibrit backend
      expect(status.message, contains('DeepCheck-Chain'));
    });
  });
}
