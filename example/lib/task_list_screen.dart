import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:widget_hydrator/widget_hydrator.dart';
import 'task.dart';
import 'task_item.dart';
import 'hydration_config.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen>
    with UltimateHydrationMixin {
  List<Task> _tasks = [];
  String _filter = 'all';
  String _sort = 'title';

  @override
  void initState() {
    super.initState();
    _initializeAndHydrate();
  }

  Future<void> _initializeAndHydrate() async {
    await initializeHydration(hydrationConfig);
    await _loadTasks();
  }

  Future<void> _loadTasks() async {
    await ensureHydrated();
    setState(() {
      print("Hydrated state loaded. Tasks: ${_tasks.length}");
    });
  }

  @override
  Map<String, dynamic> persistToJson() {
    print("Persisting ${_tasks.length} tasks");
    return {
      'tasks': _tasks.map((task) => task.toJson()).toList(),
    };
  }

@override
void hydrateFromJson(Map<String, dynamic> json) {
  print("Hydrating tasks...");
  print("Hydrated data: $json");

  // Check if the data is in the new flat structure
  final taskList = json['tasks'] as List<dynamic>?;
  if (taskList != null) {
    _tasks = taskList.map((taskJson) {
      final taskMap = taskJson as Map<String, dynamic>;
      return Task(
        id: taskMap['id'] as String,
        title: taskMap['title'] as String,
        isCompleted: taskMap['isCompleted'] as bool,
      );
    }).toList();
    print("Hydrated ${_tasks.length} tasks from flat structure");
  } else {
    // Handle the original nested structure
    final data = json['data'] as Map<String, dynamic>?;
    if (data != null) {
      final tasksData = data['value']['tasks'] as Map<String, dynamic>?;
      if (tasksData != null) {
        final nestedTaskList = tasksData['value'] as List<dynamic>?;
        if (nestedTaskList != null) {
          _tasks = nestedTaskList.map((taskJson) {
            final taskMap = taskJson['value'] as Map<String, dynamic>;
            return Task(
              id: taskMap['id']['value'] as String,
              title: taskMap['title']['value'] as String,
              isCompleted: taskMap['isCompleted']['value'] as bool,
            );
          }).toList();
          print("Hydrated ${_tasks.length} tasks from nested structure");
        } else {
          print("No tasks found in hydrated data");
        }
      } else {
        print("No tasks data found in hydrated data");
      }
    } else {
      print("No data found in hydrated data");
    }
  }
}

  @override
  void initializeDefaultState() {
    _tasks = [];
    print("Initialized default state");
  }

  void _addTask(String title) {
    setState(() {
      _tasks.add(Task(id: DateTime.now().toString(), title: title, isCompleted: false));
      print("Added new task. Total tasks: ${_tasks.length}");
    });
  }

  void _editTask(String id, String newTitle) {
    setState(() {
      final task = _tasks.firstWhere((task) => task.id == id);
      task.title = newTitle;
      print("Edited task. Task ID: $id");
    });
  }

  void _toggleTaskCompletion(String id) {
    setState(() {
      final task = _tasks.firstWhere((task) => task.id == id);
      task.isCompleted = !task.isCompleted;
      print("Toggled task completion. Task ID: $id");
    });
  }

  void _deleteTask(String id) {
    setState(() {
      _tasks.removeWhere((task) => task.id == id);
      print("Deleted task. Task ID: $id");
    });
  }

  void _setFilter(String filter) {
    setState(() {
      _filter = filter;
    });
  }

  void _setSort(String sort) {
    setState(() {
      _sort = sort;
    });
  }

  List<Task> _getFilteredTasks() {
    if (_filter == 'completed') {
      return _tasks.where((task) => task.isCompleted).toList();
    } else if (_filter == 'incomplete') {
      return _tasks.where((task) => !task.isCompleted).toList();
    }
    return _tasks;
  }

  List<Task> _getSortedTasks(List<Task> tasks) {
    if (_sort == 'title') {
      tasks.sort((a, b) => a.title.compareTo(b.title));
    } else if (_sort == 'status') {
      tasks.sort((a, b) {
        if (a.isCompleted == b.isCompleted) return 0;
        return a.isCompleted ? 1 : -1;
      });
    }
    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _getFilteredTasks();
    final sortedTasks = _getSortedTasks(filteredTasks);

    return FutureBuilder(
      future: ensureHydrated(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: _buildAppBar(),
            body: _buildTaskList(sortedTasks),
            floatingActionButton: _buildFloatingActionButton(),
            drawer: _buildSnapshotDrawer(),
          );
        } else {
          return _buildLoadingScreen();
        }
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade700,
              Colors.deepPurple.shade300,
            ],
          ),
        ),
      ),
      title: const Text(
        'Task Manager',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Iconsax.filter),
          onSelected: _setFilter,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'all',
              child: Text('All Tasks'),
            ),
            const PopupMenuItem(
              value: 'completed',
              child: Text('Completed Tasks'),
            ),
            const PopupMenuItem(
              value: 'incomplete',
              child: Text('Incomplete Tasks'),
            ),
          ],
        ),
        PopupMenuButton<String>(
          icon: const Icon(Iconsax.sort),
          onSelected: _setSort,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'title',
              child: Text('Sort by Title'),
            ),
            const PopupMenuItem(
              value: 'status',
              child: Text('Sort by Status'),
            ),
          ],
        ),
        ElevatedButton.icon(
          icon: const Icon(Iconsax.refresh),
          label: const Text('Refresh'),
          onPressed: () async {
            print("Refreshing...");
            await _loadTasks();
            print("Refresh complete. Tasks: ${_tasks.length}");
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        IconButton(
          icon: const Icon(Iconsax.camera),
          onPressed: _showCreateSnapshotDialog,
          tooltip: 'Create Snapshot',
        ),
      ],
    );
  }

  Widget _buildTaskList(List<Task> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return TaskItem(
          task: task,
          onToggleCompletion: _toggleTaskCompletion,
          onDelete: _deleteTask,
          onEdit: _editTask,
        );
      },
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showAddTaskDialog,
      label: const Text('Add Task'),
      icon: const Icon(Iconsax.add),
    );
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String newTaskTitle = '';
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Task'),
          content: TextField(
            autofocus: true,
            onChanged: (value) => newTaskTitle = value,
            decoration: const InputDecoration(
              hintText: 'Enter task title',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton.icon(
              icon: const Icon(Iconsax.close_circle),
              label: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton.icon(
              icon: const Icon(Iconsax.tick_circle),
              label: const Text('Add'),
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
  }

  Widget _buildLoadingScreen() {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildSnapshotDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade100,
              Colors.deepPurple.shade50,
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade700,
                    Colors.deepPurple.shade300,
                  ],
                ),
              ),
              child: const Text(
                'Snapshots',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FutureBuilder<List<String>>(
              future: getSnapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const ListTile(
                    title: Text('No snapshots available'),
                  );
                } else {
                  return Column(
                    children: snapshot.data!.map((snapshotName) {
                      return ListTile(
                        leading: const Icon(Iconsax.camera),
                        title: Text(snapshotName),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (BuildContext context) => [
                            const PopupMenuItem(
                              value: 'restore',
                              child: Text('Restore'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                          onSelected: (String value) {
                            if (value == 'restore') {
                              _restoreSnapshot(snapshotName);
                            } else if (value == 'delete') {
                              _deleteSnapshot(snapshotName);
                            }
                          },
                        ),
                        onTap: () => _showSnapshotDetails(snapshotName),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateSnapshotDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String snapshotName = '';
        return AlertDialog(
          title: const Text('Create Snapshot'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Snapshot Name',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              snapshotName = value;
            },
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () async {
                if (snapshotName.isNotEmpty) {
                  await createSnapshot(snapshotName);
                  Navigator.of(context).pop();
                  setState(() {}); // Refresh the drawer
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _restoreSnapshot(String snapshotName) async {
    await restoreSnapshot(snapshotName);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Restored snapshot: $snapshotName')),
    );
  }

  void _deleteSnapshot(String snapshotName) async {
    await deleteSnapshot(snapshotName);
    setState(() {}); // Refresh the drawer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Deleted snapshot: $snapshotName')),
    );
  }

  void _showSnapshotDetails(String snapshotName) async {
    final details = await getSnapshotDetails(snapshotName);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Snapshot: $snapshotName'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Created: ${details['creationTime']}'),
                const SizedBox(height: 16),
                const Text('Summary:'),
                const SizedBox(height: 8),
                Text(details['summary'].toString()),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}