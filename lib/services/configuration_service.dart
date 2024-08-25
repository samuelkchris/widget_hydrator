class ConfigurationService {
  static final ConfigurationService _instance = ConfigurationService._internal();
  factory ConfigurationService() => _instance;
  ConfigurationService._internal();

  bool useCompression = false;
  int currentVersion = 1;
  bool enableEncryption = false;
  String? encryptionKey;
  Duration? stateExpirationDuration;

  void reset() {
    useCompression = false;
    currentVersion = 1;
    enableEncryption = false;
    encryptionKey = null;
    stateExpirationDuration = null;
  }

  Map<String, dynamic> toJson() {
    return {
      'useCompression': useCompression,
      'currentVersion': currentVersion,
      'enableEncryption': enableEncryption,
      'encryptionKey': encryptionKey,
      'stateExpirationDuration': stateExpirationDuration?.inSeconds,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    useCompression = json['useCompression'] as bool? ?? false;
    currentVersion = json['currentVersion'] as int? ?? 1;
    enableEncryption = json['enableEncryption'] as bool? ?? false;
    encryptionKey = json['encryptionKey'] as String?;
    final expirationSeconds = json['stateExpirationDuration'] as int?;
    stateExpirationDuration = expirationSeconds != null ? Duration(seconds: expirationSeconds) : null;
  }
}