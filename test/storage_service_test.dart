// import 'package:flutter_test/flutter_test.dart';
// import 'package:widget_hydrator/services/storage_service.dart';
// import 'package:hive/hive.dart';
// import 'package:mockito/mockito.dart';
// import 'package:mockito/annotations.dart';
//
// @GenerateMocks([Box])
// void main() {
//   late StorageService storageService;
//   late MockBox mockBox;
//
//   setUp(() {
//     storageService = StorageService();
//     mockBox = MockBox();
//     storageService._box = mockBox;
//   });
//
//   group('StorageService Tests', () {
//     test('initialize sets up encryption when key is provided', () async {
//       await storageService.initialize(encryptionKey: 'testKey');
//       expect(storageService._encrypter, isNotNull);
//     });
//
//     test('initialize does not set up encryption when key is not provided', () async {
//       await storageService.initialize();
//       expect(storageService._encrypter, isNull);
//     });
//
//     test('saveData saves data correctly without compression or encryption', () async {
//       final data = {'key': 'value'};
//       await storageService.saveData('testKey', data);
//       verify(mockBox.put('testKey', any)).called(1);
//     });
//
//     test('loadData loads data correctly without decompression or decryption', () async {
//       final storedData = {
//         'data': '{"key":"value"}',
//         'hash': 'hash',
//         'version': 1,
//         'compressed': false,
//         'encrypted': false,
//       };
//       when(mockBox.get('testKey')).thenReturn(storedData);
//
//       final data = await storageService.loadData('testKey');
//       expect(data, {'key': 'value'});
//     });
//
//     test('deleteData deletes data correctly', () async {
//       await storageService.deleteData('testKey');
//       verify(mockBox.delete('testKey')).called(1);
//     });
//
//     test('clear clears all data correctly', () async {
//       await storageService.clear();
//       verify(mockBox.clear()).called(1);
//     });
//
//     test('saveData throws exception when encryption key is not set', () async {
//       final data = {'key': 'value'};
//       expect(
//         () async => await storageService.saveData('testKey', data, encrypt: true),
//         throwsException,
//       );
//     });
//
//     test('loadData throws exception when encryption key is not set', () async {
//       final storedData = {
//         'data': 'encryptedData',
//         'hash': 'hash',
//         'version': 1,
//         'compressed': false,
//         'encrypted': true,
//       };
//       when(mockBox.get('testKey')).thenReturn(storedData);
//
//       expect(
//         () async => await storageService.loadData('testKey', decrypt: true),
//         throwsException,
//       );
//     });
//
//     test('loadData returns null when key does not exist', () async {
//       when(mockBox.get('testKey')).thenReturn(null);
//       final data = await storageService.loadData('testKey');
//       expect(data, isNull);
//     });
//
//     test('saveData compresses data when compress is true', () async {
//       final data = {'key': 'value'};
//       await storageService.saveData('testKey', data, compress: true);
//       verify(mockBox.put('testKey', any)).called(1);
//     });
//
//     test('loadData decompresses data when compressed is true', () async {
//       final storedData = {
//         'data': 'compressedData',
//         'hash': 'hash',
//         'version': 1,
//         'compressed': true,
//         'encrypted': false,
//       };
//       when(mockBox.get('testKey')).thenReturn(storedData);
//
//       final data = await storageService.loadData('testKey', decompress: true);
//       expect(data, isNotNull);
//     });
//   });
// }