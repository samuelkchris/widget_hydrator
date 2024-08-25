import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:archive/archive.dart';
import 'package:universal_io/io.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

/// A cross-platform storage service that provides data persistence,
/// compression, and encryption capabilities.
class StorageService {
  static final StorageService _instance = StorageService._internal();

  factory StorageService() => _instance;

  StorageService._internal();

  late Box _box;
  encrypt.Encrypter? _encrypter;
  final _iv = encrypt.IV.fromLength(16);

  /// Initializes the StorageService.
  ///
  /// This method should be called before using any other methods of the service.
  /// If [encryptionKey] is provided, it enables data encryption.
  Future<void> initialize({String? encryptionKey}) async {
    try {
      debugPrint('Initializing StorageService...');
      if (kIsWeb) {
        // Web-specific initialization
        _initializeForWeb();
      } else {
        // Mobile and desktop initialization
        await _initializeForNative();
      }

      _box = await Hive.openBox('widget_hydrator');
      debugPrint('Hive box opened: widget_hydrator');
      if (encryptionKey != null && encryptionKey.isNotEmpty) {
        try {
          final key = encrypt.Key.fromBase64(encryptionKey);
          _encrypter = encrypt.Encrypter(encrypt.AES(key));
          debugPrint('Encryption enabled with provided key.');
        } catch (e) {
          debugPrint('🔑❌ Incorrect encryption key provided: $e');
          rethrow;
        }
      } else {
        debugPrint('No encryption key provided. Data will not be encrypted.');
      }
    } catch (e) {
      debugPrint('Failed to initialize StorageService: $e');
      rethrow; // Rethrow to allow caller to handle initialization errors
    }
  }

  /// Initializes storage for web platform.
  void _initializeForWeb() {
    // For web, we use in-memory storage
    Hive.init('');
    debugPrint('Initialized in-memory storage for web.');
  }

  /// Initializes storage for native platforms (mobile and desktop).
  Future<void> _initializeForNative() async {
    try {
      final directory = await _getApplicationDocumentsDirectory();
      Hive.init(directory.path);
      debugPrint(
          'Initialized storage for native platforms at ${directory.path}.');
    } catch (e) {
      debugPrint('Failed to initialize native storage: $e');
      rethrow;
    }
  }

  /// Gets the application documents directory.
  ///
  /// Uses path_provider package to get the correct directory for each platform.
  Future<Directory> _getApplicationDocumentsDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return await path_provider.getApplicationDocumentsDirectory();
    } else if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return await path_provider.getApplicationSupportDirectory();
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  /// Saves data to storage.
  ///
  /// [key] is the unique identifier for the data.
  /// [data] is the Map of data to be saved.
  /// If [compress] is true, the data will be compressed before saving.
  /// If [encrypt] is true, the data will be encrypted before saving.
  Future<void> saveData(String key, Map<String, dynamic> data,
      {bool compress = false, bool encrypt = false}) async {
    try {
      debugPrint('Saving data for key: $key');
      final String jsonData = json.encode(data);
      String processedData = jsonData;

      if (compress) {
        processedData = _compressString(processedData);
        debugPrint('Data compressed for key: $key');
      }

      if (encrypt) {
        if (_encrypter == null) {
          throw Exception(
              'Encryption key not set. Call initialize with an encryption key before using encryption.');
        }
        processedData = _encryptString(processedData);
        debugPrint('Data encrypted for key: $key');
      }

      final String hash = _calculateHash(jsonData);

      await _box.put(key, {
        'data': processedData,
        'hash': hash,
        'version': 1, // Increment this when you change the data structure
        'compressed': compress,
        'encrypted': encrypt,
      });
      debugPrint('Data saved successfully for key: $key');
    } catch (e) {
      debugPrint('Failed to save data for key $key: $e');
      rethrow;
    }
  }

  /// Loads data from storage.
  ///
  /// [key] is the unique identifier for the data.
  /// If [decompress] is true, the data will be decompressed after loading.
  /// If [decrypt] is true, the data will be decrypted after loading.
  Future<Map<String, dynamic>?> loadData(String key,
      {bool decompress = false, bool decrypt = false}) async
  {
    try {
      debugPrint('Loading data for key: $key');
      final storedData = await _box.get(key);
      if (storedData == null) {
        debugPrint('No data found for key: $key');
        return null;
      }

      String processedData = storedData['data'];

      if (decrypt && storedData['encrypted']) {
        if (_encrypter == null) {
          throw Exception(
              'Encryption key not set. Call initialize with an encryption key before using decryption.');
        }
        processedData = _decryptString(processedData);
        debugPrint('Data decrypted for key: $key');
      }

      if (decompress && storedData['compressed']) {
        processedData = _decompressString(processedData);
        debugPrint('Data decompressed for key: $key');
      }

      final decodedData = json.decode(processedData);
      debugPrint('Data decoded for key: $key');
      debugPrint('Data version: ${storedData['version']}');
      debugPrint('Data hash: ${storedData['hash']}');
      debugPrint('Data decompressed : $processedData');
      debugPrint('Data decoded : $decodedData');


      // // Convert Map<dynamic, dynamic> to Map<String, dynamic>
      // final Map<String, dynamic> typedData =
      //     _convertToStringDynamicMap(decodedData);

      final String hash = _calculateHash(json.encode(decodedData));
      if (hash != storedData['hash']) {
        throw Exception('Data integrity check failed for key $key');
      }

      debugPrint('Data loaded successfully for key: $key');
      return decodedData;
    } catch (e) {
      debugPrint('Failed to load data for key $key: $e');
      return null;
    }
  }


  /// Deletes data from storage.
  ///
  /// [key] is the unique identifier for the data to be deleted.
  Future<void> deleteData(String key) async {
    try {
      debugPrint('Deleting data for key: $key');
      await _box.delete(key);
      debugPrint('Data deleted for key: $key');
    } catch (e) {
      debugPrint('Failed to delete data for key $key: $e');
      rethrow;
    }
  }

  /// Clears all data from storage.
  Future<void> clear() async {
    try {
      debugPrint('Clearing all data from storage.');
      await _box.clear();
      debugPrint('All data cleared from storage.');
    } catch (e) {
      debugPrint('Failed to clear all data: $e');
      rethrow;
    }
  }

  /// Compresses a string using GZip compression.
  String _compressString(String input) {
    final List<int> stringBytes = utf8.encode(input);
    final compressedBytes = GZipEncoder().encode(stringBytes);
    return base64Encode(compressedBytes!);
  }

  /// Decompresses a string compressed with GZip.
  String _decompressString(String input) {
    final List<int> compressedBytes = base64Decode(input);
    final decompressedBytes = GZipDecoder().decodeBytes(compressedBytes);
    return utf8.decode(decompressedBytes);
  }

  /// Encrypts a string using AES encryption.
  String _encryptString(String input) {
    final encrypted = _encrypter!.encrypt(input, iv: _iv);
    return encrypted.base64;
  }

  /// Decrypts a string encrypted with AES encryption.
  String _decryptString(String input) {
    final encrypted = encrypt.Encrypted.fromBase64(input);
    return _encrypter!.decrypt(encrypted, iv: _iv);
  }

  /// Calculates SHA-256 hash of a string.
  String _calculateHash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  /// get all keys
  List<String> getAllKeys() {
    return _box.keys.cast<String>().toList();
  }
}
