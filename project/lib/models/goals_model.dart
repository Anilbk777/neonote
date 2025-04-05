// class Goal {
//   String title;
//   DateTime startDate;
//   DateTime completionDate;
//   bool isCompleted;
//   DateTime? completionTime;

//   Goal({
//     required this.title,
//     required this.startDate,
//     required this.completionDate,
//     this.isCompleted = false,
//     this.completionTime,
//   });
// }

// class Goal {
//   final int id;
//   String title;
//   DateTime startDate;
//   DateTime completionDate;
//   bool isCompleted;
//   DateTime? completionTime;
//   List<GoalTask> tasks;

//   Goal({
//     required this.id,
//     required this.title,
//     required this.startDate,
//     required this.completionDate,
//     this.isCompleted = false,
//     this.completionTime,
//     this.tasks = const [],
//   });

//   double completionPercentage() {
//     if (tasks.isEmpty) return 0;
//     int completedTasks = tasks.where((task) => task.status == 'completed').length;
//     return (completedTasks / tasks.length) * 100;
//   }

//   factory Goal.fromJson(Map<String, dynamic> json) {
//     return Goal(
//       id: json['id'],
//       title: json['title'],
//       startDate: DateTime.parse(json['start_date']),
//       completionDate: DateTime.parse(json['completion_date']),
//       isCompleted: json['is_completed'] ?? false,
//       completionTime: json['completion_time'] != null 
//           ? DateTime.parse(json['completion_time'])
//           : null,
//       tasks: (json['tasks'] as List<dynamic>?)
//           ?.map((taskJson) => GoalTask.fromJson(taskJson))
//           .toList() ?? [],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'title': title,
//       'start_date': startDate.toIso8601String(),
//       'completion_date': completionDate.toIso8601String(),
//       'is_completed': isCompleted,
//       'completion_time': completionTime?.toIso8601String(),
//       'tasks': tasks.map((task) => task.toJson()).toList(),
//     };
//   }
// }

// class GoalTask {
//   final int id;
//   String title;
//   String status;
//   DateTime? dueDate;

//   GoalTask({
//     required this.id,
//     required this.title,
//     this.status = 'pending',
//     this.dueDate,
//   });

//   factory GoalTask.fromJson(Map<String, dynamic> json) {
//     return GoalTask(
//       id: json['id'],
//       title: json['title'],
//       status: json['status'] ?? 'pending',
//       dueDate: json['due_date'] != null 
//           ? DateTime.parse(json['due_date'])
//           : null,
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'title': title,
//       'status': status,
//       'due_date': dueDate?.toIso8601String(),
//     };
//   }
// }


// ==================================================================================================================================


// class Goal {
//   final int id;
//   final String title;
//   final DateTime startDate;
//   final DateTime completionDate;
//   final bool isCompleted;
//   final DateTime? completionTime;
//   final int user;
//   final String createdBy;
//   final DateTime createdAt;
//   final String? lastModifiedBy;
//   final DateTime lastModifiedAt;

//   Goal({
//     required this.id,
//     required this.title,
//     required this.startDate,
//     required this.completionDate,
//     required this.isCompleted,
//     this.completionTime,
//     required this.user,
//     required this.createdBy,
//     required this.createdAt,
//     this.lastModifiedBy,
//     required this.lastModifiedAt,
//   });

//   factory Goal.fromJson(Map<String, dynamic> json) {
//     return Goal(
//       id: json['id'],
//       title: json['title'],
//       startDate: DateTime.parse(json['start_date']),
//       completionDate: DateTime.parse(json['completion_date']),
//       isCompleted: json['is_completed'],
//       completionTime: json['completion_time'] != null
//           ? DateTime.parse(json['completion_time'])
//           : null,
//       user: json['user'],
//       createdBy: json['created_by'],
//       createdAt: DateTime.parse(json['created_at']),
//       lastModifiedBy: json['last_modified_by'],
//       lastModifiedAt: DateTime.parse(json['last_modified_at']),
//     );
//   }
// }


// ================================================================================================================
import 'dart:convert';

class Goal {
  final int id;
  final String title;
  final DateTime startDate;
  final DateTime completionDate;
  final bool isCompleted;
  final DateTime? completionTime;
  final int user;
  final String createdBy;
  final DateTime createdAt;
  final String? lastModifiedBy;
  final DateTime lastModifiedAt;
  final List<GoalTask> tasks;

  Goal({
    required this.id,
    required this.title,
    required this.startDate,
    required this.completionDate,
    required this.isCompleted,
    this.completionTime,
    required this.user,
    required this.createdBy,
    required this.createdAt,
    this.lastModifiedBy,
    required this.lastModifiedAt,
    required this.tasks,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    var tasksFromJson = json['tasks'] as List<dynamic>? ?? [];
    List<GoalTask> taskList = tasksFromJson.map((task) => GoalTask.fromJson(task)).toList();

    return Goal(
      id: json['id'],
      title: json['title'],
      startDate: DateTime.parse(json['start_date']),
      completionDate: DateTime.parse(json['completion_date']),
      isCompleted: json['is_completed'],
      completionTime: json['completion_time'] != null
          ? DateTime.parse(json['completion_time'])
          : null,
      user: json['user'],
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
      lastModifiedBy: json['last_modified_by'],
      lastModifiedAt: DateTime.parse(json['last_modified_at']),
      tasks: taskList,
    );
  }

  static List<Goal> fromJsonList(String jsonString) {
    final List<dynamic> jsonData = jsonDecode(jsonString);
    return jsonData.map((json) => Goal.fromJson(json)).toList();
  }

  double completionPercentage() {
    if (tasks.isEmpty) return 0;
    int completedTasks = tasks.where((task) => task.status == 'completed').length;
    return (completedTasks / tasks.length) * 100;
  }
}

class GoalTask {
  final int id;
  final String title;
  final String status;
  final DateTime? dueDate;

  GoalTask({
    required this.id,
    required this.title,
    required this.status,
    this.dueDate,
  });

  factory GoalTask.fromJson(Map<String, dynamic> json) {
    return GoalTask(
      id: json['id'],
      title: json['title'],
      status: json['status'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    );
  }
}