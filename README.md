# Widget Hydrator

## Table of Contents
1. [Introduction](#introduction)
2. [Installation](#installation)
3. [Basic Usage](#basic-usage)
4. [Advanced Features](#advanced-features)
5. [API Reference](#api-reference)
6. [Configuration](#configuration)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

## Introduction

Widget Hydrator is a powerful Flutter package that provides an easy and flexible way to persist and restore the state of your StatefulWidgets between app restarts. By using a single mixin, you can add robust state persistence to your widgets with minimal effort.

Key features include:
- Automatic state persistence and hydration
- Compression and encryption support
- In-memory caching for improved performance
- Undo/Redo functionality
- State migration support
- Selective persistence
- State snapshots
- Performance metrics

## Installation

To use Widget Hydrator in your Flutter project, add it to your `pubspec.yaml`:

```yaml
dependencies:
  widget_hydrator: ^1.0.0
```

Then run:

```
flutter pub get
```

## Basic Usage

1. Import the package in your Dart file:

```dart
import 'package:widget_hydrator/widget_hydrator.dart';
```

2. Add the `UltimateHydrationMixin` to your StatefulWidget's State class:

```dart
class _MyWidgetState extends State<MyWidget> with UltimateHydrationMixin {
  String _myStateVariable = '';

  @override
  Map<String, dynamic> persistToJson() {
    return {
      'myStateVariable': _myStateVariable,
    };
  }

  @override
  void hydrateFromJson(Map<String, dynamic> json) {
    _myStateVariable = json['myStateVariable'] as String;
  }

  @override
  void initializeDefaultState() {
    _myStateVariable = 'Default Value';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ensureHydrated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Text(_myStateVariable);
        } else {
          return CircularProgressIndicator();
        }
      },
    );
  }
}
```

## Advanced Features

### Selective Persistence

Persist only specific parts of your state:

```dart
persistSelectedKeys(['key1', 'key2']);
```

### State Snapshots

Create and restore named snapshots of your state:

```dart
createSnapshot('beforeImportantChange');
// ... make changes ...
restoreSnapshot('beforeImportantChange');
```

### Undo/Redo

Implement undo and redo functionality:

```dart
undo();
redo();
```

### State Observers

Add observers to be notified of state changes:

```dart
addStateObserver((state) {
  print('State changed: $state');
});
```

### Performance Metrics

Track hydration and persistence performance:

```dart
final metrics = getPerformanceMetrics();
print('Hydration took ${metrics['hydrationDuration']}ms');
```

### Custom Serialization

Handle complex objects with custom serialization:

```dart
setCustomSerializer(
  (obj) => (obj as ComplexObject).toJson(),
  (json) => ComplexObject.fromJson(json as Map<String, dynamic>)
);
```

## API Reference

### UltimateHydrationMixin

#### Methods to Implement

- `Map<String, dynamic> persistToJson()`
- `void hydrateFromJson(Map<String, dynamic> json)`
- `void initializeDefaultState()`

#### Optional Methods

- `Future<Map<String, dynamic>> migrateState(Map<String, dynamic> oldState)`

#### Public Methods

- `Future<void> ensureHydrated()`
- `Future<void> forcePersist()`
- `Future<void> forceHydrate()`
- `Future<void> clearPersistedState()`
- `Future<void> saveState({VoidCallback? onSaveComplete})`
- `void setAutoSaveInterval(Duration interval)`
- `void disableAutoSave()`
- `Future<void> persistSelectedKeys(List<String> keys)`
- `Future<void> createSnapshot(String snapshotName)`
- `Future<void> restoreSnapshot(String snapshotName)`
- `void undo()`
- `void redo()`
- `void addStateObserver(Function(Map<String, dynamic>) observer)`
- `void removeStateObserver(Function(Map<String, dynamic>) observer)`
- `Map<String, int> getPerformanceMetrics()`
- `void setCustomSerializer(Function(dynamic) serializer, Function(dynamic) deserializer)`

#### Configuration Methods

- `void enableCompression(bool enable)`
- `void enableEncryption(bool enable)`
- `void setEncryptionKey(String key)`
- `void setVersion(int version)`
- `void setStateExpirationDuration(Duration? duration)`

## Configuration

### Compression

Enable compression to reduce storage space:

```dart
enableCompression(true);
```

### Encryption

Enable encryption for sensitive data:

```dart
enableEncryption(true);
setEncryptionKey('your-secret-key');
```

### State Expiration

Set an expiration time for persisted state:

```dart
setStateExpirationDuration(Duration(days: 7));
```

## Best Practices

1. Implement `persistToJson()` and `hydrateFromJson()` methods to handle all state variables you want to persist.
2. Use `ensureHydrated()` in your `build` method to ensure the state is loaded before rendering.
3. Implement `initializeDefaultState()` to set default values when no persisted state is available.
4. Use `migrateState()` to handle version changes in your persisted state structure.
5. Consider using compression for large states and encryption for sensitive data.
6. Use selective persistence for large states where only part of the state needs to be persisted.
7. Implement custom serializers for complex objects that aren't natively serializable.

## Troubleshooting

### State Not Persisting

- Ensure `persistToJson()` includes all necessary state variables.
- Check if `ensureHydrated()` is called before accessing the state.
- Verify that `initializeDefaultState()` is implemented correctly.

### Performance Issues

- Use the `getPerformanceMetrics()` method to identify bottlenecks.
- Consider enabling compression for large states.
- Use in-memory caching by default to reduce disk I/O.

### Encryption Errors

- Ensure the encryption key is set correctly with `setEncryptionKey()`.
- Verify that encryption is enabled with `enableEncryption(true)`.

For more assistance, please file an issue on the GitHub repository.