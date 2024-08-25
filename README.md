# Widget Hydrator 🌊

[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)
[![Under Development](https://img.shields.io/badge/Status-Under%20Development-yellow.svg)](https://GitHub.com/Naereen/StrapDown.js/graphs/commit-activity)
[![Flutter Platform](https://img.shields.io/badge/Platform-Flutter-blue.svg)](https://flutter.dev)
[![Dart Version](https://img.shields.io/badge/Dart-2.12+-00B4AB.svg)](https://dart.dev)

## 🚧 Under Active Development 🚧

Widget Hydrator is a powerful Flutter package that revolutionizes state management by providing an easy and flexible way to persist and restore the state of your StatefulWidgets between app restarts. By using a single mixin, you can add robust state persistence to your widgets with minimal effort, enhancing user experience and simplifying development.

## 📚 Table of Contents

- [Key Features](#-key-features)
- [Installation](#-installation)
- [Basic Usage](#-basic-usage)
- [Advanced Features](#-advanced-features)
    - [Configuration](#configuration)
    - [State Snapshots](#-state-snapshots)
    - [Undo/Redo Functionality](#-undoredo-functionality)
    - [Selective Persistence](#-selective-persistence)
    - [Custom Serialization](#-custom-serialization)
    - [Performance Metrics](#-performance-metrics)
    - [State Migration](#-state-migration)
- [Best Practices](#-best-practices)
- [Common Pitfalls and Solutions](#-common-pitfalls-and-solutions)
- [Full Example: Task List Application](#-full-example-task-list-application)
- [To-Do List](#-to-do-list)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact and Support](#-contact-and-support)

## 🌟 Key Features

Widget Hydrator offers a comprehensive suite of features to enhance your Flutter app's state management:

- ✅ **Automatic State Persistence**: Seamlessly save and restore widget state across app restarts.
- ❌ **Compression Support**: Optimize storage usage with built-in data compression.
- ❌ **Encryption Capabilities**: Secure sensitive state data with encryption.
- ✅ **In-memory Caching**: Improve performance with intelligent caching mechanisms.
- ✅ **Undo/Redo Functionality**: Easily implement undo and redo features in your app.
- ✅ **State Migration Support**: Smoothly handle state structure changes between app versions.
- ✅ **Selective Persistence**: Choose specific parts of your state to persist.
- ✅ **State Snapshots**: Create and restore named snapshots of your app's state.
- ✅ **Performance Metrics**: Monitor and optimize hydration and persistence operations.
- ✅ **Custom Serialization**: Handle complex objects with custom serialization logic.
- ✅ **Flexible Configuration**: Tailor the hydration process to your app's needs.

## 📦 Installation

To use Widget Hydrator in your Flutter project, add it to your `pubspec.yaml`:

```yaml
dependencies:
  widget_hydrator: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## 🚀 Basic Usage

1. Import the package in your Dart file:

```dart
import 'package:widget_hydrator/widget_hydrator.dart';
```

2. Add the `UltimateHydrationMixin` to your StatefulWidget's State class:

```dart
class _MyWidgetState extends State<MyWidget> with UltimateHydrationMixin {
  String _myStateVariable = '';

  @override
  void initState() {
    super.initState();
    _initializeHydration();
  }

  Future<void> _initializeHydration() async {
    await initializeHydration(HydrationConfig(
      // useCompression: true,
      // enableEncryption: true,
      // encryptionKey: 'your-secret-key',
    ));
    await ensureHydrated();
  }

  @override
  Map<String, dynamic> persistToJson() {
    return {
      'myStateVariable': _myStateVariable,
    };
  }

  @override
  void hydrateFromJson(Map<String, dynamic> json) {
    _myStateVariable = json['myStateVariable'] as String? ?? '';
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

## 🛠 Advanced Features

### Configuration

Widget Hydrator offers flexible configuration options to tailor its behavior to your app's needs:

```dart
HydrationConfig config = HydrationConfig(
  // useCompression: true,
  // enableEncryption: true,
  // encryptionKey: 'your-secret-key',
  // version: 1,
  // autoSaveInterval: Duration(minutes: 5),
  stateExpirationDuration: Duration(days: 7),
  // maxRetries: 3,
  // debounceDuration: Duration(milliseconds: 300),
);

await initializeHydration(config);
```

### 📸 State Snapshots

State snapshots allow you to save and restore specific points in your app's state:

```dart
// Create a snapshot
await createSnapshot('before_important_change');

// Restore a snapshot
await restoreSnapshot('before_important_change');

// Get list of snapshots
List<String> snapshots = await getSnapshots();

// Get snapshot details
Map<String, dynamic> details = await getSnapshotDetails('snapshot_name');

// Delete a snapshot
await deleteSnapshot('old_snapshot');
```

### ↩️ Undo/Redo Functionality

Implement undo and redo functionality with ease:

```dart
void undoLastAction() {
  undo();
  // Additional logic if needed
}

void redoLastUndo() {
  redo();
  // Additional logic if needed
}
```

### 🎯 Selective Persistence

Choose specific parts of your state to persist:

```dart
await persistSelectedKeys(['user', 'preferences']);
```

### 🔧 Custom Serialization

Handle complex objects with custom serialization:

```dart
setCustomSerializer(
  (obj) => (obj as ComplexObject).toJson(),
  (json) => ComplexObject.fromJson(json as Map<String, dynamic>)
);
```

### 📊 Performance Metrics

Monitor the performance of hydration and persistence operations:

```dart
Map<String, int> metrics = getPerformanceMetrics();
print('Hydration took ${metrics['hydrationDuration']}ms');
print('Persistence took ${metrics['persistDuration']}ms');
```

### 🔄 State Migration

Handle changes in your state structure between app versions:

```dart
@override
Future<Map<String, dynamic>> migrateState(Map<String, dynamic> oldState) async {
  if (oldState['version'] == 1) {
    // Migrate from version 1 to version 2
    oldState['newField'] = 'default value';
    oldState['version'] = 2;
  }
  return oldState;
}
```

## 💡 Best Practices

1. **Initialize Early**: Call `initializeHydration()` in your widget's `initState()` method to ensure hydration is ready when needed.

2. **Use FutureBuilder**: Wrap your widget's content in a FutureBuilder with `ensureHydrated()` to handle the asynchronous nature of hydration.

3. **Keep It Simple**: Only persist essential state that needs to survive app restarts. Avoid persisting large amounts of data that can be easily recreated or fetched.

4. **Handle Errors Gracefully**: Implement error handling in `hydrateFromJson()` to deal with potential issues in the persisted data.

5. **Use Encryption for Sensitive Data**: Enable encryption when dealing with user-specific or sensitive information.

6. **Regularly Clean Up**: Implement a mechanism to clear old or unnecessary persisted states to manage storage efficiently.

7. **Test Thoroughly**: Ensure your app works correctly with both fresh installs and updates, testing various scenarios of state persistence and restoration.

## 🚫 Common Pitfalls and Solutions

1. **Persisting Too Much Data**:
    - Problem: Slow performance due to persisting large amounts of data.
    - Solution: Only persist essential state, use selective persistence for large datasets.

2. **Inconsistent State After Updates**:
    - Problem: App crashes or behaves unexpectedly after an update.
    - Solution: Implement proper state migration logic in the `migrateState()` method.

3. **Encryption Key Management**:
    - Problem: Lost or compromised encryption keys.
    - Solution: Use secure key storage solutions and implement key rotation mechanisms.

4. **Performance Issues**:
    - Problem: Slow app startup due to hydration.
    - Solution: Use the in-memory cache, optimize the amount of persisted data, and consider asynchronous loading patterns.

## 📱 Full Example: Task List Application

Here's a more comprehensive example of using Widget Hydrator in a task list application:

```dart
import 'package:flutter/material.dart';
import 'package:widget_hydrator/widget_hydrator.dart';

class Task {
  final String id;
  String title;
  bool isCompleted;

  Task({required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'isCompleted': isCompleted,
  };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'],
    title: json['title'],
    isCompleted: json['isCompleted'],
  );
}

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> with UltimateHydrationMixin {
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _initializeAndHydrate();
  }

  Future<void> _initializeAndHydrate() async {
    await initializeHydration(HydrationConfig(
      // useCompression: false,
      // enableEncryption: true,
      // encryptionKey: 'bXktc2VjcmV0LWtleS0xMjM0NTY3ODkwMTIzNDU2Nzg5MDEyMzQ1Njc4OTA=', // 256-bit Base64 encoded key
      stateExpirationDuration: const Duration(days: 7),
    ));
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    await ensureHydrated();
    setState(() {});
  }

  @override
  Map<String, dynamic> persistToJson() {
    return {
      'tasks': _tasks.map((task) => task.toJson()).toList(),
    };
  }

  @override
  void hydrateFromJson(Map<String, dynamic> json) {
    final taskList = json['tasks'] as List<dynamic>?;
    if (taskList != null) {
      _tasks = taskList.map((taskJson) => Task.fromJson(taskJson)).toList();
    }
  }

  @override
  void initializeDefaultState() {
    _tasks = [];
  }

  void _addTask(String title) {
    setState(() {
      _tasks.add(Task(id: DateTime.now().toString(), title: title));
    });
  }

  void _toggleTask(String id) {
    setState(() {
      final task = _tasks.firstWhere((task) => task.id == id);
      task.isCompleted = !task.isCompleted;
    });
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((task) => task.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Task List')),
      body: FutureBuilder(
        future: ensureHydrated(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ListView.builder(
              itemCount: _tasks.length,
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return ListTile(
                  title: Text(task.title),
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (_) => _toggleTask(task.id),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _deleteTask(task.id),
                  ),
                );
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              String newTaskTitle = '';
              return AlertDialog(
                title: Text('Add New Task'),
                content: TextField(
                  autofocus: true,
                  onChanged: (value) => newTaskTitle = value,
                ),
                actions: [
                  TextButton(
                    child: Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: Text('Add'),
                    onPressed: () {
                      if (newTaskTitle.isNotEmpty) {
                        _addTask(newTaskTitle);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
```

This example demonstrates a fully functional task list application using Widget Hydrator for state persistence.

## 📝 To-Do List

- [ ] Implement more comprehensive error handling and recovery mechanisms
- [ ] Add support for custom storage backends (e.g., SQLite, Hive)
- [ ] Implement a plugin system for extending functionality
- [ ] Create video tutorials and interactive documentation
- [ ] Develop a suite of automated tests for various usage scenarios
- [ ] Optimize performance for extremely large state objects
- [ ] Implement a web interface for managing persisted states during development
- [ ] Add support for remote state synchronization
- [ ] Develop analytics tools for monitoring state changes over time

## 🤝 Contributing

We welcome contributions to the Widget Hydrator project! Here's how you can help:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## 👨‍💻 Contact and Support

- **Author**: Samuel Ssekizinvu
- **GitHub**: [@samuelkchris](https://github.com/samuelkchris)
- **Twitter**: [@samuelkchris](https://twitter.com/samuelkchris)

If you have any questions, suggestions, or feedback, feel free to reach out. We'd love to hear from you!



## 🙏 Acknowledgements

Special thanks to [Luke Pighetti](https://x.com/luke_pighetti) for his ideas and inspiration that led to the creation of Widget Hydrator.

```