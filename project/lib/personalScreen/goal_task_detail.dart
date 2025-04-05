
// import 'package:flutter/material.dart';
// import 'package:project/models/goals_model.dart';
// import 'package:intl/intl.dart';
// import 'package:project/widgets/custom_scaffold.dart';

// class GoalDetailScreen extends StatelessWidget {
//   final Goal goal;

//   const GoalDetailScreen({Key? key, required this.goal}) : super(key: key);

//   Widget _buildGoalDetailsSection() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.indigo.shade200),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.indigo.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Goal Details",
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.indigo,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             "Start Date: ${DateFormat.yMMMd().format(goal.startDate.toLocal())}",
//             style: const TextStyle(fontSize: 18, color: Colors.black87),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Completion Date: ${DateFormat.yMMMd().format(goal.completionDate.toLocal())}",
//             style: const TextStyle(fontSize: 18, color: Colors.black87),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Completion Percentage: ${goal.completionPercentage().toStringAsFixed(1)}%",
//             style: const TextStyle(fontSize: 18, color: Colors.black87),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGoalTasksSection(BuildContext context) {
//     if (goal.tasks.isEmpty) {
//       return Center(
//         child: Text(
//           "No tasks available",
//           style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//         ),
//       );
//     }

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.indigo.shade200),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.indigo.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Text(
//               "Goal Tasks",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.indigo,
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Container(
//             height: 300,
//             child: SingleChildScrollView(
//               child: DataTable(
//                 headingRowColor:
//                     MaterialStateProperty.all(Colors.indigo.shade50),
//                 dividerThickness: 1,
//                 headingTextStyle: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.indigo,
//                   fontSize: 16,
//                 ),
//                 dataTextStyle: const TextStyle(
//                   color: Colors.black87,
//                   fontSize: 14,
//                 ),
//                 columns: const [
//                   DataColumn(label: Text("Task Title")),
//                   DataColumn(label: Text("Status")),
//                   DataColumn(label: Text("Due Date")),
//                   DataColumn(label: Text("Actions")),
//                 ],
//                 rows: goal.tasks.map((task) {
//                   return DataRow(
//                     cells: [
//                       DataCell(Text(task.title)),
//                       DataCell(Text(task.status)),
//                       DataCell(Text(
//                         task.dueDate != null
//                             ? DateFormat('yyyy-MM-dd')
//                                 .format(task.dueDate!)
//                             : '-',
//                       )),
//                       DataCell(
//                         Row(
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.edit, color: Colors.indigo),
//                               onPressed: () {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content:
//                                         Text("Edit task not implemented"),
//                                   ),
//                                 );
//                               },
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.delete,
//                                   color: Colors.redAccent),
//                               onPressed: () {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content:
//                                         Text("Delete task not implemented"),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CustomScaffold(
//       selectedPage: goal.title, // Use selectedPage instead of title.
//       onItemSelected: (page) {}, // Provide a callback if necessary.
//       body: Scaffold(
//         appBar: AppBar(
//           title: Text(goal.title),
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back),
//             onPressed: () {
//               Navigator.pop(context);
//             },
//           ),
//         ),
//         body: SingleChildScrollView(
//           child: Column(
//             children: [
//               _buildGoalDetailsSection(),
//               _buildGoalTasksSection(context),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// ==============================================================================================================================
// import 'package:flutter/material.dart';
// import 'package:project/models/goals_model.dart';
// import 'package:intl/intl.dart';
// import 'package:project/widgets/custom_scaffold.dart';

// class GoalDetailScreen extends StatelessWidget {
//   final Goal goal;

//   const GoalDetailScreen({Key? key, required this.goal}) : super(key: key);

//   Widget _buildGoalDetailsSection() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.indigo.shade200),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.indigo.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Goal Details",
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.indigo,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             "Start Date: ${DateFormat.yMMMd().format(goal.startDate.toLocal())}",
//             style: const TextStyle(fontSize: 18, color: Colors.black87),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Completion Date: ${DateFormat.yMMMd().format(goal.completionDate.toLocal())}",
//             style: const TextStyle(fontSize: 18, color: Colors.black87),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Completion Percentage: ${goal.completionPercentage().toStringAsFixed(1)}%",
//             style: const TextStyle(fontSize: 18, color: Colors.black87),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGoalTasksSection(BuildContext context) {
//     if (goal.tasks.isEmpty) {
//       return Center(
//         child: Text(
//           "No tasks available",
//           style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//         ),
//       );
//     }

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.indigo.shade200),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.indigo.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Text(
//               "Goal Tasks",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.indigo,
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Container(
//             height: 300,
//             child: SingleChildScrollView(
//               child: DataTable(
//                 headingRowColor:
//                     MaterialStateProperty.all(Colors.indigo.shade50),
//                 dividerThickness: 1,
//                 headingTextStyle: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.indigo,
//                   fontSize: 16,
//                 ),
//                 dataTextStyle: const TextStyle(
//                   color: Colors.black87,
//                   fontSize: 14,
//                 ),
//                 columns: const [
//                   DataColumn(label: Text("Task Title")),
//                   DataColumn(label: Text("Status")),
//                   DataColumn(label: Text("Due Date")),
//                   DataColumn(label: Text("Actions")),
//                 ],
//                 rows: goal.tasks.map((task) {
//                   return DataRow(
//                     cells: [
//                       DataCell(Text(task.title)),
//                       DataCell(Text(task.status)),
//                       DataCell(Text(
//                         task.dueDate != null
//                             ? DateFormat('yyyy-MM-dd')
//                                 .format(task.dueDate!)
//                             : '-',
//                       )),
//                       DataCell(
//                         Row(
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.edit, color: Colors.indigo),
//                               onPressed: () {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content:
//                                         Text("Edit task not implemented"),
//                                   ),
//                                 );
//                               },
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.delete,
//                                   color: Colors.redAccent),
//                               onPressed: () {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content:
//                                         Text("Delete task not implemented"),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CustomScaffold(
//       selectedPage: goal.title, // Use selectedPage instead of title.
//       onItemSelected: (page) {}, // Provide a callback if necessary.
//       body: Scaffold(
//         appBar: AppBar(
//           backgroundColor: Colors.indigo, // Added background color
//           title: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Text(
//               goal.title,
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back),
//             onPressed: () {
//               Navigator.pop(context);
//             },
//           ),
//         ),
//         body: SingleChildScrollView(
//           child: Column(
//             children: [
//               _buildGoalDetailsSection(),
//               _buildGoalTasksSection(context),
//             ],
//           ),
//         ),2
//       ),
//     );
//   }
// }

// ========================================================================================================================

// import 'package:flutter/material.dart';
// import 'package:project/models/goals_model.dart';
// import 'package:intl/intl.dart';
// import 'package:project/widgets/custom_scaffold.dart';

// class GoalDetailScreen extends StatelessWidget {
//   final Goal goal;

//   const GoalDetailScreen({Key? key, required this.goal}) : super(key: key);

//   Widget _buildGoalDetailsSection() {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.indigo.shade200),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.indigo.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             "Goal Details",
//             style: TextStyle(
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//               color: Colors.indigo,
//             ),
//           ),
//           const SizedBox(height: 16),
//           Text(
//             "Start Date: ${DateFormat.yMMMd().format(goal.startDate.toLocal())}",
//             style: const TextStyle(fontSize: 18, color: Colors.black87),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Completion Date: ${DateFormat.yMMMd().format(goal.completionDate.toLocal())}",
//             style: const TextStyle(fontSize: 18, color: Colors.black87),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             "Completion Percentage: ${goal.completionPercentage().toStringAsFixed(1)}%",
//             style: const TextStyle(fontSize: 18, color: Colors.black87),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildGoalTasksSection(BuildContext context) {
//     if (goal.tasks.isEmpty) {
//       return Center(
//         child: Text(
//           "No tasks available",
//           style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//         ),
//       );
//     }

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border.all(color: Colors.indigo.shade200),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.indigo.withOpacity(0.1),
//             blurRadius: 8,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Text(
//               "Goal Tasks",
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.indigo,
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Container(
//             height: 300,
//             child: SingleChildScrollView(
//               child: DataTable(
//                 headingRowColor:
//                     MaterialStateProperty.all(Colors.indigo.shade50),
//                 dividerThickness: 1,
//                 headingTextStyle: const TextStyle(
//                   fontWeight: FontWeight.bold,
//                   color: Colors.indigo,
//                   fontSize: 16,
//                 ),
//                 dataTextStyle: const TextStyle(
//                   color: Colors.black87,
//                   fontSize: 14,
//                 ),
//                 columns: const [
//                   DataColumn(label: Text("Task Title")),
//                   DataColumn(label: Text("Status")),
//                   DataColumn(label: Text("Due Date")),
//                   DataColumn(label: Text("Actions")),
//                 ],
//                 rows: goal.tasks.map((task) {
//                   return DataRow(
//                     cells: [
//                       DataCell(Text(task.title)),
//                       DataCell(Text(task.status)),
//                       DataCell(Text(
//                         task.dueDate != null
//                             ? DateFormat('yyyy-MM-dd')
//                                 .format(task.dueDate!)
//                             : '-',
//                       )),
//                       DataCell(
//                         Row(
//                           children: [
//                             IconButton(
//                               icon: const Icon(Icons.edit, color: Colors.indigo),
//                               onPressed: () {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content:
//                                         Text("Edit task not implemented"),
//                                   ),
//                                 );
//                               },
//                             ),
//                             IconButton(
//                               icon: const Icon(Icons.delete,
//                                   color: Colors.redAccent),
//                               onPressed: () {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content:
//                                         Text("Delete task not implemented"),
//                                   ),
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   );
//                 }).toList(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return CustomScaffold(
//       selectedPage: goal.title, // Use selectedPage instead of title.
//       onItemSelected: (page) {}, // Provide a callback if necessary.
//       body: Scaffold(
//         appBar: AppBar(
//           backgroundColor: Colors.indigo, // Added background color
//           title: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Text(
//               goal.title,
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back),
//             onPressed: () {
//               Navigator.pop(context);
//             },
//           ),
//         ),
//         body: SingleChildScrollView(
//           child: Column(
//             children: [
//               _buildGoalDetailsSection(),
//               _buildGoalTasksSection(context),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// ========================================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/services/goal_task.dart';

class GoalDetailScreen extends StatefulWidget {
  final Goal goal;

  const GoalDetailScreen({Key? key, required this.goal}) : super(key: key);

  @override
  _GoalDetailScreenState createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends State<GoalDetailScreen> {
  final TextEditingController _taskController = TextEditingController();
  final ApiService _apiService = ApiService();
  late Future<List<GoalTask>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _apiService.fetchTasksForGoal(widget.goal.id);
  }

  void _addTask(String title, String status, DateTime? dueDate) async {
    if (title.isNotEmpty) {
      await _apiService.createTaskForGoal(title, status, dueDate, widget.goal.id);
      setState(() {
        _tasksFuture = _apiService.fetchTasksForGoal(widget.goal.id);
      });
      _taskController.clear();
    }
  }

  void _updateTask(GoalTask task, String title, String status, DateTime? dueDate) async {
    await _apiService.updateTask(task.id, title, status, dueDate);
    setState(() {
      _tasksFuture = _apiService.fetchTasksForGoal(widget.goal.id);
    });
  }

  void _deleteTask(GoalTask task) async {
    await _apiService.deleteTask(task.id);
    setState(() {
      _tasksFuture = _apiService.fetchTasksForGoal(widget.goal.id);
    });
  }

  void _toggleTaskCompletion(GoalTask task) async {
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';
    await _apiService.updateTask(task.id, task.title, newStatus, task.dueDate);
    setState(() {
      _tasksFuture = _apiService.fetchTasksForGoal(widget.goal.id);
    });
  }

  Widget _buildGoalDetailsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.indigo.shade200),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Goal Details",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Start Date: ${DateFormat.yMMMd().format(widget.goal.startDate.toLocal())}",
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "Completion Date: ${DateFormat.yMMMd().format(widget.goal.completionDate.toLocal())}",
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            "Completion Percentage: ${widget.goal.completionPercentage().toStringAsFixed(1)}%",
            style: const TextStyle(fontSize: 18, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTasksSection(BuildContext context) {
    return FutureBuilder<List<GoalTask>>(
      future: _tasksFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading tasks'));
        } else {
          final tasks = snapshot.data!;
          final activeTasks = tasks.where((task) => task.status != 'completed').toList();
          final completedTasks = tasks.where((task) => task.status == 'completed').toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (activeTasks.isNotEmpty) ...[
                Center(
                  child: Text(
                    "Goal Tasks",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                ),
                Container(
                  height: 300,
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.indigo.shade50),
                      dividerThickness: 1,
                      headingTextStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        fontSize: 16,
                      ),
                      dataTextStyle: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                      columns: const [
                        DataColumn(label: Text("Task Title")),
                        DataColumn(label: Text("Status")),
                        DataColumn(label: Text("Due Date")),
                        DataColumn(label: Text("Actions")),
                      ],
                      rows: activeTasks.map((task) {
                        return DataRow(
                          cells: [
                            DataCell(Text(task.title)),
                            DataCell(Text(task.status)),
                            DataCell(Text(task.dueDate != null ? DateFormat('yyyy-MM-dd').format(task.dueDate!) : '-')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.indigo),
                                    onPressed: () {
                                      _showEditTaskDialog(task);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                                    onPressed: () {
                                      _deleteTask(task);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
              if (completedTasks.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Completed Tasks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...completedTasks.map((task) {
                  return ListTile(
                    title: Text(task.title),
                    subtitle: Text(
                      task.dueDate != null ? 'Due Date: ${DateFormat('yyyy-MM-dd').format(task.dueDate!)}' : 'No Due Date',
                    ),
                    trailing: Checkbox(
                      value: task.status == 'completed',
                      onChanged: (value) {
                        _toggleTaskCompletion(task);
                      },
                    ),
                    onTap: () {
                      _showEditTaskDialog(task);
                    },
                  );
                }),
              ],
              if (tasks.isEmpty)
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
          );
        }
      },
    );
  }

  void _showEditTaskDialog(GoalTask task) {
    TextEditingController titleController = TextEditingController(text: task.title);
    TextEditingController dueDateController = TextEditingController(
      text: task.dueDate != null ? DateFormat('yyyy-MM-dd').format(task.dueDate!) : '',
    );
    String selectedStatus = task.status;
    DateTime selectedDate = task.dueDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Edit Task", style: TextStyle(color: Colors.indigo)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                  labelStyle: TextStyle(color: Colors.indigo),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: dueDateController,
                decoration: InputDecoration(
                  labelText: "Due Date",
                  labelStyle: TextStyle(color: Colors.indigo),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                readOnly: true,
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: ColorScheme.light(primary: Colors.indigo),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    setState(() {
                      dueDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                      selectedDate = pickedDate;
                    });
                  }
                },
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  labelText: "Status",
                  labelStyle: TextStyle(color: Colors.indigo),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['pending', 'in_progress', 'on_hold', 'cancelled', 'completed']
                    .map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(color: Colors.black)),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    selectedStatus = newValue!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  _showErrorDialog("Title is required.");
                  return;
                }
                await _updateTask(
                  task,
                  titleController.text,
                  selectedStatus,
                  selectedDate,
                );
                Navigator.pop(context);
              },
              child: Text("Update", style: TextStyle(color: Colors.indigo)),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text("Error", style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("OK", style: TextStyle(color: Colors.indigo)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: widget.goal.title,
      onItemSelected: (page) {},
      body: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          title: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.goal.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildGoalDetailsSection(),
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
                      onPressed: () {
                        _addTask(_taskController.text, 'pending', null);
                      },
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
              _buildGoalTasksSection(context),
            ],
          ),
        ),
      ),
    );
  }
}