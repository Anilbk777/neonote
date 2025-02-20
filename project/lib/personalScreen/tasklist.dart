import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/widgets/custom_scaffold.dart'; // Import CustomScaffold

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  _TaskListPageState createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final TextEditingController _taskController = TextEditingController();
  final List<Map<String, dynamic>> _tasks = [];

  void _addTask(String task) {
    if (task.isNotEmpty) {
      setState(() {
        _tasks.add({
          'task': task,
          'timestamp': DateTime.now(),
          'completed': false,
        });
      });
      _taskController.clear();
    }
  }

  // Tasks for today
  List<Map<String, dynamic>> get _todayTasks {
    return _tasks.where((task) {
      final now = DateTime.now();
      final taskDate = task['timestamp'];
      return !task['completed'] &&
          taskDate.day == now.day &&
          taskDate.month == now.month &&
          taskDate.year == now.year;
    }).toList();
  }

  // Uncompleted tasks from previous days
  List<Map<String, dynamic>> get _uncompletedPreviousTasks {
    return _tasks.where((task) {
      final now = DateTime.now();
      final taskDate = task['timestamp'];
      return !task['completed'] &&
          (taskDate.day != now.day ||
              taskDate.month != now.month ||
              taskDate.year != now.year);
    }).toList();
  }

  void _toggleTaskCompletion(int index) {
    setState(() {
      _tasks[index]['completed'] = !_tasks[index]['completed'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: 'Task List',
      onItemSelected: (selectedPage) {
        print('Navigated to $selectedPage');
      },
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          AppBar(
            backgroundColor: const Color(0xFF255DE1),
            title: const Text(
              'Your Task, Your Way ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 249, 252, 253),
              ),
              textAlign: TextAlign.center,
            ),
            automaticallyImplyLeading: false,
          ),
          // Input field and add button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: const InputDecoration(
                      labelText: 'Enter a task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _addTask(_taskController.text),
                  child: const Text('Add'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Task lists
          Expanded(
            child: ListView(
              children: [
                // Today's Tasks
                if (_todayTasks.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Today\'s Tasks',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._todayTasks.map((task) {
                    final taskIndex = _tasks.indexOf(task);
                    return ListTile(
                      title: Text(task['task']),
                      subtitle: Text(
                        'Added: ${DateFormat('hh:mm a').format(task['timestamp'])}',
                      ),
                      trailing: Checkbox(
                        value: task['completed'],
                        onChanged: (value) => _toggleTaskCompletion(taskIndex),
                      ),
                    );
                  }),
                ],
                // Uncompleted Previous Tasks
                if (_uncompletedPreviousTasks.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Uncompleted Tasks from Previous Days',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ..._uncompletedPreviousTasks.map((task) {
                    final taskIndex = _tasks.indexOf(task);
                    return ListTile(
                      title: Text(task['task']),
                      subtitle: Text(
                        'Added on: ${DateFormat('MMM d, yyyy hh:mm a').format(task['timestamp'])}',
                      ),
                      trailing: Checkbox(
                        value: task['completed'],
                        onChanged: (value) => _toggleTaskCompletion(taskIndex),
                      ),
                    );
                  }),
                ],
                if (_todayTasks.isEmpty && _uncompletedPreviousTasks.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: Text(
                        'No tasks to show.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
