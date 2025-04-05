import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:project/models/goal.dart';
import 'package:project/models/task.dart';

class ApiService {
  final String baseUrl = 'http://127.0.0.1:8000/gt';

  Future<List<Goal>> fetchGoals() async {
    final response = await http.get(Uri.parse('$baseUrl/goals/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((goal) => Goal.fromJson(goal)).toList();
    } else {
      throw Exception('Failed to load goals');
    }
  }

  Future<List<GoalTask>> fetchTasksForGoal(int goalId) async {
    final response = await http.get(Uri.parse('$baseUrl/goals/$goalId/tasks/'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((task) => GoalTask.fromJson(task)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<void> createTaskForGoal(String title, String status, DateTime? dueDate, int goalId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'title': title,
        'status': status,
        'due_date': dueDate?.toIso8601String(),
        'goal': goalId,
      }),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create task');
    }
  }

  Future<void> updateTask(int id, String title, String status, DateTime? dueDate) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'title': title,
        'status': status,
        'due_date': dueDate?.toIso8601String(),
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update task');
    }
  }

  Future<void> deleteTask(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/tasks/$id/'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete task');
    }
  }
}