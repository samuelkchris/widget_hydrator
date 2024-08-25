import 'package:flutter_test/flutter_test.dart';
import 'package:widget_hydrator/services/configuration_service.dart';

void main() {
  group('ConfigurationService', () {
    test('toJson returns correct map', () {
      final service = ConfigurationService();
      service.useCompression = true;
      service.currentVersion = 2;
      service.enableEncryption = true;
      service.encryptionKey = 'testKey';
      service.stateExpirationDuration = const Duration(seconds: 3600);

      final json = service.toJson();

      expect(json, {
        'useCompression': true,
        'currentVersion': 2,
        'enableEncryption': true,
        'encryptionKey': 'testKey',
        'stateExpirationDuration': 3600,
      });
    });

    test('fromJson sets correct values', () {
      final service = ConfigurationService();
      final json = {
        'useCompression': true,
        'currentVersion': 2,
        'enableEncryption': true,
        'encryptionKey': 'testKey',
        'stateExpirationDuration': 3600,
      };

      service.fromJson(json);

      expect(service.useCompression, true);
      expect(service.currentVersion, 2);
      expect(service.enableEncryption, true);
      expect(service.encryptionKey, 'testKey');
      expect(service.stateExpirationDuration, Duration(seconds: 3600));
    });

    test('reset sets default values', () {
      final service = ConfigurationService();
      service.useCompression = true;
      service.currentVersion = 2;
      service.enableEncryption = true;
      service.encryptionKey = 'testKey';
      service.stateExpirationDuration = Duration(seconds: 3600);

      service.reset();

      expect(service.useCompression, false);
      expect(service.currentVersion, 1);
      expect(service.enableEncryption, false);
      expect(service.encryptionKey, null);
      expect(service.stateExpirationDuration, null);
    });

    test('fromJson handles missing fields', () {
      final service = ConfigurationService();
      final json = {
        'useCompression': true,
      };

      service.fromJson(json);

      expect(service.useCompression, true);
      expect(service.currentVersion, 1);
      expect(service.enableEncryption, false);
      expect(service.encryptionKey, null);
      expect(service.stateExpirationDuration, null);
    });
  });
}