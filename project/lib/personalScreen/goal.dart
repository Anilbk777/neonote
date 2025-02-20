import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/widgets/custom_scaffold.dart';

class Goal {
  final String title;
  final DateTime startDate;
  final DateTime completionDate;
  bool isCompleted;
  DateTime? completionTime;

  Goal({
    required this.title,
    required this.startDate,
    required this.completionDate,
    this.isCompleted = false,
    this.completionTime,
  });
}

class GoalPage extends StatefulWidget {
  const GoalPage({super.key});

  @override
  _GoalPageState createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  final List<Goal> _goals = [];
  final _goalController = TextEditingController();
  DateTime? _startDate;
  DateTime? _completionDate;

  void _addGoal() {
    String goalTitle = _goalController.text.trim();

    if (goalTitle.isEmpty) {
      _showErrorDialog('Goal title cannot be empty.');
      return;
    }

    if (_startDate == null) {
      _showErrorDialog('Please select a start date.');
      return;
    }

    if (_completionDate == null) {
      _showErrorDialog('Please select a completion date.');
      return;
    }

    if (_completionDate!.isBefore(_startDate!)) {
      _showErrorDialog('Completion date cannot be earlier than the start date.');
      return;
    }

    setState(() {
      _goals.add(Goal(
        title: goalTitle,
        startDate: _startDate!,
        completionDate: _completionDate!,
      ));
      _goals.sort((a, b) => a.isCompleted ? 1 : -1); // Ensure active goals stay on top.
    });

    _goalController.clear();
    _startDate = null;
    _completionDate = null;
  }

  void _toggleCompletion(int index) {
    setState(() {
      _goals[index].isCompleted = !_goals[index].isCompleted;
      _goals[index].completionTime = _goals[index].isCompleted ? DateTime.now() : null;
      _goals.sort((a, b) => a.isCompleted ? 1 : -1); // Re-sort goals to show active goals on top.
    });
  }

  List<Goal> get _activeGoals {
    return _goals.where((goal) => !goal.isCompleted).toList();
  }

  List<Goal> get _completedGoals {
    final now = DateTime.now();
    return _goals.where((goal) {
      if (!goal.isCompleted) return false;
      final completionTime = goal.completionTime;
      if (completionTime == null) return false;
      return now.difference(completionTime).inDays <= 30;
    }).toList();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: 'Goals',
      
      onItemSelected: (page) {
        // .........................
      },
      body: Column(
        children: [
          AppBar(
            backgroundColor: const Color(0xFF255DE1),
            title: const Text(
              'Dreams to achive ',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 249, 252, 253), 
              ),
              textAlign: TextAlign.center,
            ),
              automaticallyImplyLeading: false,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _goalController,
                    decoration: const InputDecoration(labelText: 'Goal Title'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_startDate == null
                            ? 'Start Date: Not Selected'
                            : 'Start Date: ${DateFormat.yMMMd().format(_startDate!)}'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _startDate = pickedDate;
                            });
                          }
                        },
                        child: const Text('Select Start Date'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_completionDate == null
                            ? 'Completion Date: Not Selected'
                            : 'Completion Date: ${DateFormat.yMMMd().format(_completionDate!)}'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _completionDate = pickedDate;
                            });
                          }
                        },
                        child: const Text('Select Completion Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _addGoal,
                    child: const Text('Add Goal'),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_activeGoals.isNotEmpty) ...[
                            const Text('Active Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ..._activeGoals.map((goal) => ListTile(
                                  title: Text(goal.title),
                                  subtitle: Text(
                                      'Start: ${DateFormat.yMMMd().format(goal.startDate)} - End: ${DateFormat.yMMMd().format(goal.completionDate)}'),
                                  trailing: Checkbox(
                                    value: goal.isCompleted,
                                    onChanged: (_) => _toggleCompletion(_goals.indexOf(goal)),
                                  ),
                                )),
                            const SizedBox(height: 20),
                          ],
                          if (_completedGoals.isNotEmpty) ...[
                            const Text('Completed Goals (Last 30 Days)',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ..._completedGoals.map((goal) => ListTile(
                                  title: Text(goal.title),
                                  subtitle: Text(
                                      'Start: ${DateFormat.yMMMd().format(goal.startDate)} - End: ${DateFormat.yMMMd().format(goal.completionDate)}'),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
