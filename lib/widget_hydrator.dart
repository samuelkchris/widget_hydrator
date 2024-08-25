import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:widget_hydrator/services/configuration_service.dart';
import 'package:widget_hydrator/services/debug_service.dart';
import 'package:widget_hydrator/services/serialization_service.dart';
import 'package:widget_hydrator/services/storage_service.dart';

/// Configuration options for the UltimateHydrationMixin.
///
/// These options can be set when initializing the mixin.
class HydrationConfig {
  final bool useCompression;
  final bool enableEncryption;
  final String? encryptionKey;
  final int version;
  final Duration autoSaveInterval;
  final Duration? stateExpirationDuration;
  final int maxRetries;
  final Duration debounceDuration;

  HydrationConfig({
    this.useCompression = false,
    this.enableEncryption = false,
    this.encryptionKey,
    this.version = 1,
    this.autoSaveInterval = const Duration(minutes: 5),
    this.stateExpirationDuration,
    this.maxRetries = 3,
    this.debounceDuration = const Duration(milliseconds: 300),
  });
}

/// A mixin that provides robust state persistence capabilities for StatefulWidgets.
///
/// This mixin allows for automatic or manual persistence of widget state,
/// with features such as compression, encryption, in-memory caching,
/// undo/redo functionality, state migration, and performance metrics.
///
/// Usage:
/// ```dart
/// class _MyWidgetState extends State<MyWidget> with UltimateHydrationMixin {
///   @override
///   void initState() {
///     super.initState();
///     initializeHydration(HydrationConfig(
///       useCompression: true,
///       enableEncryption: true,
///       encryptionKey: 'my-secret-key',
///     ));
///   }
///
///   @override
///   Map<String, dynamic> persistToJson() {
///     // Implement this method to return the state as a JSON-serializable map
///   }
///
///   @override
///   void hydrateFromJson(Map<String, dynamic> json) {
///     // Implement this method to restore the state from a JSON-serializable map
///   }
///
///   @override
///   void initializeDefaultState() {
///     // Implement this method to set default values when no persisted state is available
///   }
/// }
/// ```
mixin UltimateHydrationMixin<T extends StatefulWidget> on State<T> {
  late String _stateKey;
  bool _isInitialized = false;
  bool _isHydrated = false;
  late ConfigurationService _config;
  late StorageService _storage;
  late SerializationService _serializer;
  late DebugService _debug;

  Timer? _autoSaveTimer;
  Timer? _debounceTimer;
  String? _lastPersistedStateHash;

  // In-memory cache
  Map<String, dynamic>? _stateCache;

  // Undo/Redo stacks
  final List<Map<String, dynamic>> _undoStack = [];
  final List<Map<String, dynamic>> _redoStack = [];

  // State observers
  final List<Function(Map<String, dynamic>)> _stateObservers = [];

  // Performance metrics
  int _hydrationDuration = 0;
  int _persistDuration = 0;

  /// Initializes the UltimateHydrationMixin with the given configuration.
  ///
  /// This method should be called in the initState method of your StatefulWidget.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   initializeHydration(HydrationConfig(
  ///     useCompression: true,
  ///     enableEncryption: true,
  ///     encryptionKey: 'my-secret-key',
  ///     version: 2,
  ///     autoSaveInterval: Duration(minutes: 10),
  ///   ));
  /// }
  /// ```
  Future<void> initializeHydration(HydrationConfig config) async {
    _config = ConfigurationService()
      ..useCompression = config.useCompression
      ..enableEncryption = config.enableEncryption
      ..encryptionKey = config.encryptionKey
      ..currentVersion = config.version
      ..stateExpirationDuration = config.stateExpirationDuration;

    _serializer = SerializationService();
    _debug = DebugService();
    _storage = StorageService();
    await _storage.initialize(encryptionKey: config.encryptionKey);
    _stateKey = await _generateRobustStateKey();
    _isInitialized = true;
    _setupAutoSave(config.autoSaveInterval);
    await _hydrateState();
  }




  @override
  void dispose() {
    _persistState();
    _autoSaveTimer?.cancel();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<String> _generateRobustStateKey() async {
    final widgetTypeString = widget.runtimeType.toString();
    final widgetKey = widget.key?.toString() ?? '';

    // Generate a unique string based on the widget type and key
    final baseString = '$widgetTypeString-$widgetKey';

    // Use SHA-256 to create a consistent hash
    final bytes = utf8.encode(baseString);
    final hash = sha256.convert(bytes);
    final consistentHash = hash.toString();

    // Use StorageService to store and retrieve persistent identifiers
    final storedKeyData =
    await _storage.loadData('state_key_$consistentHash');

    if (storedKeyData != null && storedKeyData.containsKey('key')) {
      return storedKeyData['key'] as String;
    } else {
      // If no stored key exists, create a new one
      final newKey = '${widget.runtimeType}_$consistentHash';
      await _storage
          .saveData('state_key_$consistentHash', {'key': newKey});
      return newKey;
    }
  }
  void _setupAutoSave(Duration interval) {
    _autoSaveTimer = Timer.periodic(interval, (_) => _persistState());
  }

  Future<void> _hydrateState() async {
    if (_isHydrated || !_isInitialized) return;

    final stopwatch = Stopwatch()..start();

    try {
      Map<String, dynamic>? storedData = await _storage.loadData(
        _stateKey,
        decompress: _config.useCompression,
        decrypt: _config.enableEncryption,
      );

      if (storedData != null) {
        if (_isStateExpired(storedData)) {
          _debug.log('Stored state has expired for $_stateKey');
          initializeDefaultState();
        } else {
          final migratedData = await migrateState(storedData);
          _debug.log('State migrated for $_stateKey');
          _debug.log('Migrated data: $migratedData');

          setState(() {
            hydrateFromJson(migratedData);
            _isHydrated = true;
          });

          _lastPersistedStateHash = _calculateStateHash(migratedData);
          _debug.log('State hydrated for $_stateKey');

          // Update cache
          _stateCache = migratedData;
        }
      } else {
        _debug.log('No stored state found for $_stateKey, initializing with default values');
        setState(() {
          initializeDefaultState();
          _isHydrated = true;
        });
      }
    } catch (e) {
      _debug.logError('Failed to hydrate state for $_stateKey: $e');
      await _handleHydrationError(e);
    }

    stopwatch.stop();
    _hydrationDuration = stopwatch.elapsedMilliseconds;
  }

  Future<void> _persistState() async {
    if (!_isInitialized || _stateKey == null) return;

    final stopwatch = Stopwatch()..start();

    try {
      final stateJson = persistToJson();
      final currentStateHash = _calculateStateHash(stateJson);

      if (currentStateHash != _lastPersistedStateHash) {
        final serialized = _serializer.serialize(
          stateJson,
          version: _config.currentVersion,
          compress: _config.useCompression,
        );

        if (serialized.containsKey('error')) {
          throw Exception(serialized['error']);
        }

        await _storage.saveData(
          _stateKey,
          serialized,
          compress: _config.useCompression,
          encrypt: _config.enableEncryption,
        );

        _lastPersistedStateHash = currentStateHash;
        _debug.log('State persisted for $_stateKey');

        // Update cache
        _stateCache = stateJson;

        // Notify observers
        _notifyObservers(stateJson);
      } else {
        _debug.log('State unchanged, skipping persistence for $_stateKey');
      }
    } catch (e) {
      _debug.logError('Failed to persist state for $_stateKey: $e');
      await _handlePersistenceError(e);
    }

    stopwatch.stop();
    _persistDuration = stopwatch.elapsedMilliseconds;
  }

  String _calculateStateHash(Map<String, dynamic> state) {
    return _serializer.generateHash(state);
  }

  Future<void> _handleHydrationError(dynamic error) async {
    _debug.logWarning('Handling hydration error: $error');
    setState(() {
      initializeDefaultState();
      _isHydrated = true;
    });
    // Optionally, you could try to clear the corrupted data
    await _storage.deleteData(_stateKey);
  }

  Future<void> _handlePersistenceError(dynamic error) async {
    _debug.logWarning('Handling persistence error: $error');
    await _retryPersistence(maxRetries: 3);
  }

  Future<void> _retryPersistence({int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        await _persistState();
        _debug.log('State persisted successfully on retry ${i + 1}');
        return;
      } catch (e) {
        if (i == maxRetries - 1) {
          _debug.logError('All retries failed. Unable to persist state.');
        } else {
          _debug.logWarning('Retry ${i + 1} failed. Retrying...');
          await Future.delayed(
              Duration(seconds: 1 << i)); // Exponential backoff
        }
      }
    }
  }

  bool _isStateExpired(Map<String, dynamic> state) {
    if (_config.stateExpirationDuration != null &&
        state.containsKey('timestamp')) {
      final stateTimestamp = DateTime.parse(state['timestamp'] as String);
      return DateTime.now().difference(stateTimestamp) >
          _config.stateExpirationDuration!;
    }
    return false;
  }

  void _notifyObservers(Map<String, dynamic> state) {
    for (final observer in _stateObservers) {
      observer(state);
    }
  }

  /// Ensures that the state is hydrated before use.
  ///
  /// This method should be called in the build method of your widget
  /// to ensure that the state is hydrated before it's used.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return FutureBuilder(
  ///     future: ensureHydrated(),
  ///     builder: (context, snapshot) {
  ///       if (snapshot.connectionState == ConnectionState.done) {
  ///         return YourWidget();
  ///       } else {
  ///         return CircularProgressIndicator();
  ///       }
  ///     },
  ///   );
  /// }
  /// ```
  Future<void> ensureHydrated() async {
    if (!_isInitialized) {
      throw StateError(
          'UltimateHydrationMixin not initialized. Call initializeHydration() in initState().');
    }
    if (!_isHydrated) {
      await _hydrateState();
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _persistState();
    });

    // Add current state to undo stack
    _undoStack.add(persistToJson());
    // Clear redo stack
    _redoStack.clear();
  }

  /// Returns whether the state has been hydrated.
  bool get isHydrated => _isHydrated;

  /// Returns whether the mixin has been initialized.
  bool get isInitialized => _isInitialized;

  /// Manually triggers a state save operation.
  ///
  /// This method can be used to force a state save at a specific point in time.
  /// An optional callback can be provided to be executed after the save is complete.
  ///
  /// Example:
  /// ```dart
  /// await saveState(onSaveComplete: () {
  ///   print('State saved successfully');
  /// });
  /// ```
  Future<void> saveState({VoidCallback? onSaveComplete}) async {
    await _persistState();
    onSaveComplete?.call();
  }

  /// Sets a new interval for automatic state saving.
  ///
  /// This method allows you to change the frequency of automatic state saves.
  ///
  /// Example:
  /// ```dart
  /// setAutoSaveInterval(Duration(minutes: 10));
  /// ```
  void setAutoSaveInterval(Duration interval) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(interval, (_) => _persistState());
  }

  /// Disables automatic state saving.
  ///
  /// After calling this method, state will only be saved manually or when setState is called.
  void disableAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Persists only the specified keys of the state.
  ///
  /// This method allows for selective persistence of the state,
  /// which can be useful for large state objects where only part
  /// of the state needs to be persisted.
  ///
  /// Example:
  /// ```dart
  /// await persistSelectedKeys(['user', 'preferences']);
  /// ```
  Future<void> persistSelectedKeys(List<String> keys) async {
    final fullState = persistToJson();
    final selectedState = Map.fromEntries(
        fullState.entries.where((entry) => keys.contains(entry.key)));
    await _storage.saveData(_stateKey, selectedState);
  }

  /// Retrieves a list of all available snapshots.
  ///
  /// Returns a list of snapshot names that have been created for this widget.
  ///
  /// Example:
  /// ```dart
  /// final snapshots = await getSnapshots();
  /// print('Available snapshots: $snapshots');
  /// ```
  Future<List<String>> getSnapshots() async {
    final allKeys = _storage.getAllKeys();
    final snapshotPrefix = '${_stateKey}_snapshot_';
    return allKeys
        .where((key) => key.startsWith(snapshotPrefix))
        .map((key) => key.substring(snapshotPrefix.length))
        .toList();
  }

  /// Retrieves details of a specific snapshot.
  ///
  /// Returns a map containing details about the snapshot, including its creation time
  /// and a summary of its contents.
  ///
  /// Example:
  /// ```dart
  /// final details = await getSnapshotDetails('before_important_change');
  /// print('Snapshot details: $details');
  /// ```
  Future<Map<String, dynamic>> getSnapshotDetails(String snapshotName) async {
    final snapshotData = await _storage.loadData('${_stateKey}_snapshot_$snapshotName');
    if (snapshotData == null) {
      throw Exception('Snapshot $snapshotName not found');
    }

    final creationTime = snapshotData['_creationTime'] as String?;
    final stateData = snapshotData['_stateData'] as Map<String, dynamic>?;

    return {
      'name': snapshotName,
      'creationTime': creationTime ?? 'Unknown',
      'summary': _generateStateSummary(stateData ?? {}),
    };
  }

  /// Creates a named snapshot of the current state.
  ///
  /// This method allows you to save the current state under a specific name,
  /// which can be restored later using [restoreSnapshot].
  ///
  /// Example:
  /// ```dart
  /// await createSnapshot('before_important_change');
  /// ```
  Future<void> createSnapshot(String snapshotName) async {
    final state = persistToJson();
    final snapshotData = {
      '_creationTime': DateTime.now().toIso8601String(),
      '_stateData': state,
    };
    await _storage.saveData('${_stateKey}_snapshot_$snapshotName', snapshotData);
  }

  /// Restores a previously created named snapshot.
  ///
  /// This method restores the state from a snapshot created with [createSnapshot].
  ///
  /// Example:
  /// ```dart
  /// await restoreSnapshot('before_important_change');
  /// ```
  Future<void> restoreSnapshot(String snapshotName) async {
    final snapshotData = await _storage.loadData('${_stateKey}_snapshot_$snapshotName');
    if (snapshotData != null && snapshotData['_stateData'] != null) {
      setState(() {
        hydrateFromJson(snapshotData['_stateData']);
      });
    } else {
      throw Exception('Snapshot $snapshotName not found or invalid');
    }
  }

  /// Deletes a specific snapshot.
  ///
  /// Removes the specified snapshot from storage.
  ///
  /// Example:
  /// ```dart
  /// await deleteSnapshot('old_snapshot');
  /// ```
  Future<void> deleteSnapshot(String snapshotName) async {
    await _storage.deleteData('${_stateKey}_snapshot_$snapshotName');
  }

  /// Generates a summary of the state data.
  ///
  /// This method creates a brief summary of the state data, which can be useful
  /// for displaying snapshot contents without revealing sensitive information.
  Map<String, dynamic> _generateStateSummary(Map<String, dynamic> stateData) {
    return stateData.map((key, value) {
      if (value is Map) {
        return MapEntry(key, '{...}');
      } else if (value is List) {
        return MapEntry(key, '[...]');
      } else {
        return MapEntry(key, value.toString());
      }
    });
  }


  /// Undoes the last state change.
  ///
  /// This method reverts the state to the previous state in the undo stack.
  void undo() {
    if (_undoStack.isNotEmpty) {
      final currentState = persistToJson();
      _redoStack.add(currentState);
      final previousState = _undoStack.removeLast();
      setState(() {
        hydrateFromJson(previousState);
      });
    }
  }

  /// Redoes the last undone state change.
  ///
  /// This method applies the next state in the redo stack.
  void redo() {
    if (_redoStack.isNotEmpty) {
      final currentState = persistToJson();
      _undoStack.add(currentState);
      final nextState = _redoStack.removeLast();
      setState(() {
        hydrateFromJson(nextState);
      });
    }
  }

  /// Adds an observer to be notified of state changes.
  ///
  /// The observer will be called with the new state whenever it changes.
  ///
  /// Example:
  /// ```dart
  /// addStateObserver((newState) {
  ///   print('State changed: $newState');
  /// });
  /// ```
  void addStateObserver(Function(Map<String, dynamic>) observer) {
    _stateObservers.add(observer);
  }

  /// Removes a previously added state observer.
  void removeStateObserver(Function(Map<String, dynamic>) observer) {
    _stateObservers.remove(observer);
  }

  /// Returns performance metrics for hydration and persistence operations.
  ///
  /// The returned map contains 'hydrationDuration' and 'persistDuration' in milliseconds.
  Map<String, int> getPerformanceMetrics() {
    return {
      'hydrationDuration': _hydrationDuration,
      'persistDuration': _persistDuration,
    };
  }

  /// Sets custom serializer and deserializer functions.
  ///
  /// This method allows you to provide custom serialization logic
  /// for complex objects that aren't natively JSON-serializable.
  ///
  /// Example:
  /// ```dart
  /// setCustomSerializer(
  ///   (obj) => (obj as ComplexObject).toJson(),
  ///   (json) => ComplexObject.fromJson(json as Map<String, dynamic>)
  /// );
  /// ```
  void setCustomSerializer(
      Function(dynamic) serializer, Function(dynamic) deserializer) {
    _serializer.setCustomSerializers(serializer, deserializer);
  }

  /// Forcefully persists the current state.
  ///
  /// This method can be used to manually trigger a state persistence
  /// operation, bypassing any debounce or auto-save mechanisms.
  Future<void> forcePersist() async => await _persistState();

  /// Forcefully hydrates the state from persisted storage.
  ///
  /// This method can be used to manually trigger a state hydration
  /// operation, which will overwrite the current state with the
  /// persisted state.
  Future<void> forceHydrate() async => await _hydrateState();

  /// Clears all persisted state data.
  ///
  /// This method removes all persisted state data from storage.
  /// Use with caution as this operation cannot be undone.
  Future<void> clearPersistedState() async {
    await _storage.deleteData(_stateKey);
    _stateCache = null;
    _debug.log('Cleared persisted state for $_stateKey');
  }

  /// Enables or disables compression for state persistence.
  ///
  /// Compression can reduce storage space but may impact performance.
  void enableCompression(bool enable) {
    _config.useCompression = enable;
  }

  /// Enables or disables encryption for state persistence.
  ///
  /// Encryption adds security but may impact performance.
  void enableEncryption(bool enable) {
    _config.enableEncryption = enable;
  }

  /// Sets the encryption key for state persistence.
  ///
  /// This method should be called if encryption is enabled.
  void setEncryptionKey(String key) {
    _config.encryptionKey = key;
  }

  /// Sets the version of the current state structure.
  ///
  /// This can be used in conjunction with the [migrateState] method
  /// to handle version changes in your persisted state structure.
  void setVersion(int version) {
    _config.currentVersion = version;
  }

  /// Sets the expiration duration for persisted state.
  ///
  /// After this duration, persisted state will be considered expired
  /// and the default state will be used instead.
  void setStateExpirationDuration(Duration? duration) {
    _config.stateExpirationDuration = duration;
  }

  // Abstract methods to be implemented by the user

  /// Converts the current state to a JSON-serializable map.
  ///
  /// This method should be implemented to return a map representation
  /// of the current state that can be serialized to JSON.
  Map<String, dynamic> persistToJson();

  /// Restores the state from a JSON-serializable map.
  ///
  /// This method should be implemented to update the current state
  /// based on the provided JSON-serializable map.
  void hydrateFromJson(Map<String, dynamic> json);

  /// Initializes the state with default values.
  ///
  /// This method should be implemented to set default values for the state
  /// when no persisted state is available.
  void initializeDefaultState();

  /// Optional method for state migration between versions.
  ///
  /// This method can be overridden to provide custom migration logic
  /// when the state structure changes between versions.
  ///
  /// Example:
  /// ```dart
  /// @override
  /// Future<Map<String, dynamic>> migrateState(Map<String, dynamic> oldState) async {
  ///   if (oldState['version'] == 1) {
  ///     // Migrate from version 1 to version 2
  ///     oldState['newField'] = 'default value';
  ///     oldState['version'] = 2;
  ///   }
  ///   return oldState;
  /// }
  /// ```
  Future<Map<String, dynamic>> migrateState(
      Map<String, dynamic> oldState) async {
    return oldState;
  }

  /// Clears all persisted state data.

  Future<void> clearAllStateKeys() async {
    final allKeys = await _storage.loadData('all_state_keys') ?? {'keys': []};
    final List<String> keys = List<String>.from(allKeys['keys']);

    for (final key in keys) {
      await _storage.deleteData('state_key_$key');
    }

    await _storage.saveData('all_state_keys', {'keys': []});
  }
}
