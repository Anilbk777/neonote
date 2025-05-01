// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:project/services/local_storage.dart'; // Assuming LocalStorageService is here

// class ProjectTaskList extends StatefulWidget {
//   final int projectId;

//   const ProjectTaskList({
//     Key? key,
//     required this.projectId,
//   }) : super(key: key);

//   @override
//   _ProjectTaskListState createState() => _ProjectTaskListState();
// }

// class _ProjectTaskListState extends State<ProjectTaskList> {
//   bool _isLoading = true;
//   List<dynamic> _tasks = [];
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _fetchProjectTasks();
//   }

//   Future<void> _fetchProjectTasks() async {
//     // Ensure the widget is still mounted before proceeding
//     if (!mounted) return;

//     setState(() {
//       _isLoading = true;
//       _error = null;
//     });

//     try {
//       final token = await LocalStorageService.getToken(); // Use LocalStorageService
//       if (token == null) {
//         throw Exception('Authentication token not found.');
//       }

//       // Use the nested URL structure
//       // Use 10.0.2.2 for Android emulator accessing localhost, or your machine's IP
//       final url = Uri.parse('http://10.0.2.2:8000/api/work/projects/${widget.projectId}/tasks/');
//       final response = await http.get(
//         url,
//         headers: {
//           'Authorization': 'Bearer $token',
//           'Content-Type': 'application/json',
//           'Accept': 'application/json',
//         },
//       );

//       // Check mounted again before updating state after async gap
//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         setState(() {
//           _tasks = json.decode(response.body);
//         });
//       } else {
//         throw Exception('Failed to load project tasks: ${response.statusCode}');
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _error = e.toString());
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_isLoading) {
//       return const Center(child: CircularProgressIndicator());
//     }
//     if (_error != null) {
//       return Center(child: Text('Error loading tasks: $_error', style: const TextStyle(color: Colors.red)));
//     }
//     if (_tasks.isEmpty) {
//       return const Center(child: Text('No tasks found for this project.', style: TextStyle(color: Colors.grey)));
//     }

//     // Build the list view for tasks
//     return ListView.builder(
//       shrinkWrap: true, // Important inside a Column/ListView
//       physics: const NeverScrollableScrollPhysics(), // Disable scrolling within the outer scroll view
//       itemCount: _tasks.length,
//       itemBuilder: (context, index) {
//         final task = _tasks[index];
//         // Basic display - customize as needed
//         return ListTile(
//           leading: Icon(task['status'] == 'completed' ? Icons.check_circle : Icons.radio_button_unchecked, color: task['status'] == 'completed' ? Colors.green : Colors.grey),
//           title: Text(task['title'] ?? 'No Title'),
//           subtitle: Text('Priority: ${task['priority'] ?? 'N/A'} - Due: ${task['due_date'] ?? 'None'}'),
//           trailing: Text(task['assigned_to']?['full_name'] ?? 'Unassigned'),
//           // TODO: Add onTap to view/edit task details
//         );
//       },
//     );
//   }
// }

// ====================================================================================================================================



import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project/services/local_storage.dart';
import 'package:intl/intl.dart'; // Import intl package for date formatting

class ProjectTaskList extends StatefulWidget {
  final int projectId;
  final List<Map<String, dynamic>> teamMembers;

  const ProjectTaskList({
    Key? key,
    required this.projectId,
    required this.teamMembers,
  }) : super(key: key);

  @override
  _ProjectTaskListState createState() => _ProjectTaskListState();
}

class _ProjectTaskListState extends State<ProjectTaskList> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchProjectTasks();
  }

  Future<void> _fetchProjectTasks() async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await http
          .get(
            Uri.parse('http://127.0.0.1:8000/api/work/projects/${widget.projectId}/tasks/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _tasks = data ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load tasks: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on http.ClientException catch (e) {
      setState(() {
        _error = 'Connection error: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addTask(
    String title,
    int? assignedToId, // Change type to int?
    String priority,
    DateTime dueDate,
  ) async {
    try {
      final token = await LocalStorage.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not authenticated')),
        );
        return;
      }

      final response = await http
          .post(
            Uri.parse('http://127.0.0.1:8000/api/work/projects/${widget.projectId}/tasks/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'title': title,
              'assigned_to_id': assignedToId, // Use correct key and type
              'priority': priority,
              'due_date': DateFormat('yyyy-MM-dd').format(dueDate),
              'status': 'pending', // Explicitly add the default status
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          _tasks.add(data);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task added successfully'), backgroundColor: Colors.green),
        );
      } else {
        final errorData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          // Log the full error response for better debugging
          SnackBar(content: Text('Failed to add task: ${errorData.toString()}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding task: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    int? selectedAssigneeId; // Change type to int?
    String? selectedPriority;
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>( // Change type to int
                  value: selectedAssigneeId,
                  onChanged: (value) {
                    setState(() {
                      selectedAssigneeId = value; // Update state variable
                    });
                  },
                  items: widget.teamMembers
                      .map<DropdownMenuItem<int>>( // Change type to int
                        (member) => DropdownMenuItem(
                          value: member['id'], // Remove .toString()
                          child: Text(member['full_name']),
                        ),
                      )
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Assign To',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  onChanged: (value) {
                    setState(() { // No need for setState here as it's handled by the dialog's internal state management
                      selectedPriority = value;
                    });
                  },
                  items: ['Low', 'Medium', 'High']
                      .map(
                        (priority) => DropdownMenuItem(
                          value: priority,
                          child: Text(priority), // Display value remains the same
                        ),
                      )
                      .toList(),
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dueDate == null
                            ? 'Select Due Date'
                            : 'Due Date: ${dueDate?.toLocal().toString().split(' ')[0] ?? ''}', // Add null check
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: dueDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        setState(() {
                          dueDate = selectedDate;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    // selectedAssigneeId can be null if unassigned is allowed
                    selectedPriority != null &&
                    dueDate != null) {
                  _addTask(
                    titleController.text,
                    selectedAssigneeId, // Pass the ID (can be null)
                    selectedPriority!.toLowerCase(), // Send lowercase value
                    dueDate!,
                  );
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _showAddTaskDialog,
            child: const Text('Add Task'),
          ),
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (_error != null)
          Center(
            child: Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          )
        else if (_tasks.isEmpty)
          const Center(
            child: Text(
              'No tasks available.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return Card(
                child: ListTile(
                  title: Text(task['title'] ?? 'Unnamed Task'),
                  // Access the nested 'full_name' within 'assigned_to'
                  // Add null checks for both 'assigned_to' and 'full_name'
                  subtitle: Text('Assigned to: ${task['assigned_to']?['full_name'] ?? 'Unassigned'}'),
                  trailing: Text('Priority: ${task['priority'] ?? 'N/A'}'),
                ),
              );

            },
          ),
      ],
    );
  }
}