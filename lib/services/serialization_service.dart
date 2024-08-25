import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:archive/archive.dart';

class SerializationService {
  static final SerializationService _instance = SerializationService._internal();
  factory SerializationService() => _instance;
  SerializationService._internal();

  Function(dynamic)? _customSerializer;
  Function(dynamic)? _customDeserializer;

  void setCustomSerializers(
      Function(dynamic) serializer,
      Function(dynamic) deserializer
      ) {
    _customSerializer = serializer;
    _customDeserializer = deserializer;
  }

  Map<String, dynamic> serialize(dynamic object, {int version = 1, bool compress = false}) {
    try {
      final serialized = _customSerializer != null
          ? _customSerializer!(object)
          : _serializeInternal(object);
      final result = {'data': serialized, 'version': version};

      if (compress) {
        final compressed = _compressMap(result);
        return {'compressed': true, 'data': compressed};
      }

      return result;
    } catch (e) {
      debugPrint('Serialization error: $e');
      return {'error': 'Serialization failed: ${e.toString()}'};
    }
  }

  dynamic deserialize(dynamic data) {
    try {
      if (data is! Map<String, dynamic>) {
        throw FormatException('Expected a Map, but got ${data.runtimeType}');
      }

      if (data.containsKey('error')) {
        throw Exception(data['error']);
      }

      if (data['compressed'] == true) {
        final decompressed = _decompressMap(data['data']);
        data = decompressed;
      }

      return _customDeserializer != null
          ? _customDeserializer!(data['data'])
          : _deserializeInternal(data['data']);
    } catch (e) {
      debugPrint('Deserialization error: $e');
      return null;
    }
  }

  dynamic _serializeInternal(dynamic object) {
    if (object == null) {
      return {'type': 'null', 'value': null};
    }

    if (object is num || object is String || object is bool) {
      return {'type': object.runtimeType.toString(), 'value': object};
    }

    if (object is List) {
      return {
        'type': 'List',
        'value': object.map((e) => _serializeInternal(e)).toList(),
      };
    }

    if (object is Map) {
      return {
        'type': 'Map',
        'value': object.map((k, v) => MapEntry(k.toString(), _serializeInternal(v))),
      };
    }

    if (object is DateTime) {
      return {'type': 'DateTime', 'value': object.toIso8601String()};
    }

    // Instead of throwing an error, return a special error object
    return {'type': 'error', 'value': 'Unsupported type: ${object.runtimeType}'};
  }

  dynamic _deserializeInternal(dynamic data) {
    // Check if data is a Map
    if (data is! Map<String, dynamic>) {
      debugPrint('Expected a Map, but got ${data.runtimeType}');
      return null;
    }

    final type = data['type'];
    final value = data['value'];

    switch (type) {
      case 'null':
        return null;
      case 'int':
        return value as int;
      case 'double':
        return value as double;
      case 'String':
        return value as String;
      case 'bool':
        return value as bool;
      case 'List':
        return (value as List).map((e) => _deserializeInternal(e)).toList();
      case 'Map':
        return (value as Map).map((k, v) => MapEntry(k, _deserializeInternal(v)));
      case 'DateTime':
        return DateTime.parse(value as String);
      case 'error':
        debugPrint('Deserialization error: $value');
        return null;
      default:
        debugPrint('Unsupported type for deserialization: $type');
        return null;
    }
  }

  String _compressMap(Map<String, dynamic> data) {
    try {
      final jsonString = json.encode(data);
      final bytes = utf8.encode(jsonString);
      final compressed = GZipEncoder().encode(bytes);
      return base64Encode(compressed!);
    } catch (e) {
      debugPrint('Compression error: $e');
      // Return original data as a string if compression fails
      return json.encode(data);
    }
  }

  Map<String, dynamic> _decompressMap(String compressedData) {
    try {
      final compressed = base64Decode(compressedData);
      final bytes = GZipDecoder().decodeBytes(compressed);
      final jsonString = utf8.decode(bytes);
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Decompression error: $e');
      try {
        return json.decode(compressedData) as Map<String, dynamic>;
      } catch (_) {
        return {};
      }
    }
  }

  String generateHash(Map<String, dynamic> data) {
    try {
      final jsonString = json.encode(data);
      return sha256.convert(utf8.encode(jsonString)).toString();
    } catch (e) {
      debugPrint('Hash generation error: $e');
      // Return a placeholder hash if generation fails
      return 'error_generating_hash';
    }
  }
}