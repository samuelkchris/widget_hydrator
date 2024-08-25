import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'task.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final Function(String) onToggleCompletion;
  final Function(String) onDelete;
  final Function(String, String) onEdit;

  TaskItem({
    Key? key,
    required this.task,
    required this.onToggleCompletion,
    required this.onDelete,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: Key(task.id),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDelete(task.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Iconsax.trash,
            label: 'Delete',
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: task.isCompleted
              ? Colors.green.withOpacity(0.1)
              : Colors.deepPurple.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Checkbox(
            value: task.isCompleted,
            onChanged: (_) => onToggleCompletion(task.id),
            shape: const CircleBorder(),
            activeColor: Colors.green,
          ),
          title: Text(
            task.title,
            style: TextStyle(
              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              color: task.isCompleted ? Colors.grey : Colors.white,
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Iconsax.edit),
            onPressed: () => _showEditTaskDialog(context),
          ),
        ),
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context) {
    String editedTaskTitle = task.title;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit Task'),
          content: TextFormField(
            autofocus: true,
            initialValue: task.title,
            onChanged: (value) => editedTaskTitle = value,
            decoration: const InputDecoration(
              hintText: 'Enter new task title',
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
              label: const Text('Save'),
              onPressed: () {
                if (editedTaskTitle.isNotEmpty) {
                  onEdit(task.id, editedTaskTitle);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }
}