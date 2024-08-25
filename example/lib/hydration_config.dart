import 'package:widget_hydrator/widget_hydrator.dart';

final hydrationConfig = HydrationConfig(
  // useCompression: false,
  // enableEncryption: true,
  // encryptionKey: 'bXktc2VjcmV0LWtleS0xMjM0NTY3ODkwMTIzNDU2Nzg5MDEyMzQ1Njc4OTA=', // 256-bit Base64 encoded key
  stateExpirationDuration: const Duration(days: 7),
);