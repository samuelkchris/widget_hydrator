import 'package:flutter/material.dart';
import 'task_list_screen.dart';
import 'theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: appTheme,
      home: const TaskListScreen(),
    );
  }
}