import 'package:flutter_test/flutter_test.dart';
import 'package:widget_hydrator/services/serialization_service.dart';

void main() {
  late SerializationService serializationService;

  setUp(() {
    serializationService = SerializationService();
  });

  group('SerializationService Tests', () {
    test('Serialize and deserialize simple data', () {
      final data = {'name': 'John Doe', 'age': 30};
      final serialized = serializationService.serialize(data);
      final deserialized = serializationService.deserialize(serialized);
      expect(deserialized, equals(data));
    });

    test('Serialize and deserialize with compression', () {
      final data = {'name': 'John Doe', 'age': 30};
      final serialized = serializationService.serialize(data, compress: true);
      expect(serialized['compressed'], isTrue);
      final deserialized = serializationService.deserialize(serialized);
      expect(deserialized, equals(data));
    });

    test('Serialize and deserialize complex data', () {
      final data = {
        'user': {'name': 'John Doe', 'age': 30},
        'scores': [85, 90, 95],
        'isActive': true,
        'lastLogin': DateTime(2023, 5, 1).toIso8601String(),
      };
      final serialized = serializationService.serialize(data);
      final deserialized = serializationService.deserialize(serialized);
      expect(deserialized, equals(data));
    });

    test('Handle unsupported type', () {
      final data = {'unsupported': RegExp(r'\d+')};
      final serialized = serializationService.serialize(data);
      expect(serialized['data']['value'], contains('Unsupported type:'));
    });

    test('Deserialize invalid data returns null', () {
      final invalidData = {'invalid': 'data'};
      final result = serializationService.deserialize(invalidData);
      expect(result, isNull);
    });

    test('Generate hash for data', () {
      final data = {'name': 'John Doe', 'age': 30};
      final hash = serializationService.generateHash(data);
      expect(hash, isNotEmpty);
      expect(hash, isNot('error_generating_hash'));
    });

    test('Custom serializers', () {
      serializationService.setCustomSerializers(
            (data) => {'custom': data.toString()},
            (data) => data['custom'],
      );

      final data = {'name': 'John Doe', 'age': 30};
      final serialized = serializationService.serialize(data);
      final deserialized = serializationService.deserialize(serialized);

      expect(serialized['data']['custom'], isA<String>());
      expect(deserialized, isA<String>());
    });

    test('Serialize and deserialize null', () {
      final serialized = serializationService.serialize(null);
      final deserialized = serializationService.deserialize(serialized);
      expect(deserialized, isNull);
    });

    test('Serialize and deserialize empty map', () {
      final data = <String, dynamic>{};
      final serialized = serializationService.serialize(data);
      final deserialized = serializationService.deserialize(serialized);
      expect(deserialized, isEmpty);
    });

    test('Serialize and deserialize list', () {
      final data = [1, 'two', true];
      final serialized = serializationService.serialize(data);
      final deserialized = serializationService.deserialize(serialized);
      expect(deserialized, equals(data));
    });
  });
}