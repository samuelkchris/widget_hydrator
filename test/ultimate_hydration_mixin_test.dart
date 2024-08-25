import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:widget_hydrator/services/configuration_service.dart';
import 'package:widget_hydrator/services/debug_service.dart';
import 'package:widget_hydrator/services/serialization_service.dart';
import 'package:widget_hydrator/services/storage_service.dart';
import 'package:widget_hydrator/widget_hydrator.dart';

// Mock classes
class MockStorageService extends Mock implements StorageService {}
class MockSerializationService extends Mock implements SerializationService {}
class MockDebugService extends Mock implements DebugService {}

class TestWidget extends StatefulWidget {
  @override
  _TestWidgetState createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> with UltimateHydrationMixin {
  late StorageService _storage;
  late SerializationService _serializer;
  late DebugService _debug;
  late ConfigurationService _config;
  bool _isInitialized = false;
  bool _isHydrated = false;

  String testData = '';

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  Map<String, dynamic> persistToJson() {
    return {'testData': testData};
  }

  @override
  void hydrateFromJson(Map<String, dynamic> json) {
    testData = json['testData'] as String;
  }

  @override
  void initializeDefaultState() {
    testData = 'default';
  }

  Future<void> _hydrateState() async {
    final data = await _storage.loadData('test_key', decompress: true, decrypt: true);
    final hydratedData = _serializer.deserialize(data);
    hydrateFromJson(hydratedData);
    _isHydrated = true;
  }

  Future<void> _persistState() async {
    final serializedData = _serializer.serialize(persistToJson(), version: 1, compress: true);
    await _storage.saveData('test_key', serializedData, compress: true, encrypt: true);
  }
}

void main() {
  late _TestWidgetState testState;
  late MockStorageService mockStorage;
  late MockSerializationService mockSerializer;
  late MockDebugService mockDebug;

  setUp(() {
    testState = _TestWidgetState();
    mockStorage = MockStorageService();
    mockSerializer = MockSerializationService();
    mockDebug = MockDebugService();

    // Inject mocks
    testState._storage = mockStorage;
    testState._serializer = mockSerializer;
    testState._debug = mockDebug;
  });

  group('UltimateHydrationMixin Tests', () {
    test('Initialization', () async {
      final config = HydrationConfig(
        useCompression: true,
        enableEncryption: true,
        encryptionKey: 'test-key',
      );

      when(mockStorage.initialize(encryptionKey: 'test-key')).thenAnswer((_) async {});

      await testState.initializeHydration(config);

      expect(testState._isInitialized, true);
      expect(testState._config.useCompression, true);
      expect(testState._config.enableEncryption, true);
      expect(testState._config.encryptionKey, 'test-key');
    });

    test('Hydration', () async {
      final mockData = {'testData': 'hydrated'};
      when(mockStorage.loadData('test_key', decompress: true, decrypt: true))
          .thenAnswer((_) async => mockData);
      when(mockSerializer.deserialize(mockData)).thenReturn(mockData);

      await testState._hydrateState();

      expect(testState.testData, 'hydrated');
      expect(testState._isHydrated, true);
    });

    test('Persistence', () async {
      final serializedData = {'data': 'serialized'};
      final dataToPersist = {'testData': 'persistent'};

      when(mockSerializer.serialize(dataToPersist, version: 1, compress: true))
          .thenReturn(serializedData);
      when(mockStorage.saveData('test_key', serializedData, compress: true, encrypt: true))
          .thenAnswer((_) async {});

      await testState._persistState();

      verify(mockStorage.saveData('test_key', serializedData, compress: true, encrypt: true)).called(1);
    });

    test('Undo/Redo', () {
      testState.testData = 'initial';
      testState.setState(() {
        testState.testData = 'changed';
      });
      expect(testState.testData, 'changed');

      testState.undo();
      expect(testState.testData, 'initial');

      testState.redo();
      expect(testState.testData, 'changed');
    });

    test('Create and Restore Snapshot', () async {
      testState.testData = 'snapshot data';
      await testState.createSnapshot('test_snapshot');

      verify(mockStorage.saveData('test_snapshot', {'testData': 'snapshot data'})).called(1);

      testState.testData = 'changed data';

      when(mockStorage.loadData('test_snapshot')).thenAnswer((_) async => {'testData': 'snapshot data'});

      await testState.restoreSnapshot('test_snapshot');

      expect(testState.testData, 'snapshot data');
    });

    test('State Observer', () {
      bool observerCalled = false;
      testState.addStateObserver((state) {
        observerCalled = true;
        expect(state['testData'], 'observed');
      });

      testState.setState(() {
        testState.testData = 'observed';
      });

      expect(observerCalled, true);
    });

    test('Performance Metrics', () async {
      await testState._hydrateState();
      await testState._persistState();

      final metrics = testState.getPerformanceMetrics();

      expect(metrics.containsKey('hydrationDuration'), true);
      expect(metrics.containsKey('persistDuration'), true);
    });

    test('Custom Serializer', () {
      dynamic customSerializer(dynamic obj) => {'custom': obj.toString()};
      dynamic customDeserializer(dynamic data) => data['custom'];

      testState.setCustomSerializer(customSerializer, customDeserializer);

      verify(mockSerializer.setCustomSerializers(customSerializer, customDeserializer)).called(1);
    });

    test('Clear Persisted State', () async {
      await testState.clearPersistedState();

      verify(mockStorage.deleteData('test_key')).called(1);
      expect(testState.testData, 'default');
    });
  });
}
