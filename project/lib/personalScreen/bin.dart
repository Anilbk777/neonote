import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project/models/page.dart';
import 'package:project/models/goals_model.dart';
import 'package:project/services/diary_service.dart';
import 'package:project/services/api_service.dart';
import 'package:project/services/goal_service.dart';
import 'package:project/providers/pages_provider.dart';
import 'package:provider/provider.dart';
import 'package:project/personalScreen/content_page.dart';
import 'package:project/personalScreen/newPages/Openned_diary.dart';
import 'package:project/personalScreen/goal.dart';
import 'package:project/widgets/custom_scaffold.dart';

// Model for deleted pages
class DeletedPage {
  final PageModel page;
  final DateTime deletedAt;

  DeletedPage({required this.page, required this.deletedAt});

  Map<String, dynamic> toJson() {
    return {
      'page': {
        'id': page.id,
        'title': page.title,
        'content': page.content,
      },
      'deletedAt': deletedAt.toIso8601String(),
    };
  }

  factory DeletedPage.fromJson(Map<String, dynamic> json) {
    return DeletedPage(
      page: PageModel(
        id: json['page']['id'],
        title: json['page']['title'],
        content: json['page']['content'],
      ),
      deletedAt: DateTime.parse(json['deletedAt']),
    );
  }
}

// Model for deleted diaries
class DeletedDiary {
  final DiaryEntry diary;
  final DateTime deletedAt;

  DeletedDiary({required this.diary, required this.deletedAt});

  Map<String, dynamic> toJson() {
    return {
      'diary': diary.toJson(),
      'deletedAt': deletedAt.toIso8601String(),
    };
  }

  factory DeletedDiary.fromJson(Map<String, dynamic> json) {
    return DeletedDiary(
      diary: DiaryEntry.fromJson(json['diary']),
      deletedAt: DateTime.parse(json['deletedAt']),
    );
  }
}

// Model for deleted goals
class DeletedGoal {
  final Goal goal;
  final DateTime deletedAt;

  DeletedGoal({required this.goal, required this.deletedAt});

  Map<String, dynamic> toJson() {
    return {
      'goal': {
        'id': goal.id,
        'title': goal.title,
        'startDate': goal.startDate.toIso8601String(),
        'completionDate': goal.completionDate.toIso8601String(),
        'isCompleted': goal.isCompleted,
        'completionTime': goal.completionTime?.toIso8601String(),
        'user': goal.user,
        'createdBy': goal.createdBy,
        'createdAt': goal.createdAt.toIso8601String(),
        'lastModifiedBy': goal.lastModifiedBy,
        'lastModifiedAt': goal.lastModifiedAt.toIso8601String(),
        'tasks': goal.tasks.map((task) => {
          'id': task.id,
          'title': task.title,
          'status': task.status,
          'priority': task.priority,
          'dueDate': task.dueDate?.toIso8601String(),
          'dateCreated': task.dateCreated.toIso8601String(),
          'goal': task.goal,
        }).toList(),
      },
      'deletedAt': deletedAt.toIso8601String(),
    };
  }

  factory DeletedGoal.fromJson(Map<String, dynamic> json) {
    final goalJson = json['goal'];
    final tasksJson = goalJson['tasks'] as List;

    return DeletedGoal(
      goal: Goal(
        id: goalJson['id'],
        title: goalJson['title'],
        startDate: DateTime.parse(goalJson['startDate']),
        completionDate: DateTime.parse(goalJson['completionDate']),
        isCompleted: goalJson['isCompleted'],
        completionTime: goalJson['completionTime'] != null
            ? DateTime.parse(goalJson['completionTime'])
            : null,
        user: goalJson['user'],
        createdBy: goalJson['createdBy'],
        createdAt: DateTime.parse(goalJson['createdAt']),
        lastModifiedBy: goalJson['lastModifiedBy'],
        lastModifiedAt: DateTime.parse(goalJson['lastModifiedAt']),
        tasks: tasksJson.map((taskJson) => GoalTask(
          id: taskJson['id'],
          title: taskJson['title'],
          status: taskJson['status'],
          priority: taskJson['priority'],
          dueDate: taskJson['dueDate'] != null
              ? DateTime.parse(taskJson['dueDate'])
              : null,
          dateCreated: DateTime.parse(taskJson['dateCreated']),
          goal: taskJson['goal'],
        )).toList(),
      ),
      deletedAt: DateTime.parse(json['deletedAt']),
    );
  }
}

// Provider for managing deleted items
class BinProvider extends ChangeNotifier {
  List<DeletedPage> _deletedPages = [];
  List<DeletedDiary> _deletedDiaries = [];
  List<DeletedGoal> _deletedGoals = [];

  List<DeletedPage> get deletedPages => _deletedPages;
  List<DeletedDiary> get deletedDiaries => _deletedDiaries;
  List<DeletedGoal> get deletedGoals => _deletedGoals;

  BinProvider() {
    // Load deleted items when the provider is created
    _loadDeletedItems();
  }

  // Load deleted items from local storage
  Future<void> _loadDeletedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load deleted pages
      final pagesJson = prefs.getString('deleted_pages');
      if (pagesJson != null) {
        final List<dynamic> pagesData = jsonDecode(pagesJson);
        _deletedPages = pagesData.map((data) => DeletedPage.fromJson(data)).toList();
      }

      // Load deleted diaries
      final diariesJson = prefs.getString('deleted_diaries');
      if (diariesJson != null) {
        final List<dynamic> diariesData = jsonDecode(diariesJson);
        _deletedDiaries = diariesData.map((data) => DeletedDiary.fromJson(data)).toList();
      }

      // Load deleted goals
      final goalsJson = prefs.getString('deleted_goals');
      if (goalsJson != null) {
        final List<dynamic> goalsData = jsonDecode(goalsJson);
        _deletedGoals = goalsData.map((data) => DeletedGoal.fromJson(data)).toList();
      }

      notifyListeners();
    } catch (e) {
      print('Error loading deleted items: $e');
    }
  }

  // Save deleted items to local storage
  Future<void> _saveDeletedItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Save deleted pages
      final pagesJson = jsonEncode(_deletedPages.map((page) => page.toJson()).toList());
      await prefs.setString('deleted_pages', pagesJson);

      // Save deleted diaries
      final diariesJson = jsonEncode(_deletedDiaries.map((diary) => diary.toJson()).toList());
      await prefs.setString('deleted_diaries', diariesJson);

      // Save deleted goals
      final goalsJson = jsonEncode(_deletedGoals.map((goal) => goal.toJson()).toList());
      await prefs.setString('deleted_goals', goalsJson);

      print('Saved deleted items to local storage');
    } catch (e) {
      print('Error saving deleted items: $e');
    }
  }

  // Add a deleted page
  void addDeletedPage(PageModel page) {
    _deletedPages.add(DeletedPage(page: page, deletedAt: DateTime.now()));
    _saveDeletedItems();
    notifyListeners();
  }

  // Add a deleted diary
  void addDeletedDiary(DiaryEntry diary) {
    _deletedDiaries.add(DeletedDiary(diary: diary, deletedAt: DateTime.now()));
    _saveDeletedItems();
    notifyListeners();
  }

  // Add a deleted goal
  void addDeletedGoal(Goal goal) {
    _deletedGoals.add(DeletedGoal(goal: goal, deletedAt: DateTime.now()));
    _saveDeletedItems();
    notifyListeners();
  }

  // Restore a deleted page
  Future<void> restorePage(DeletedPage deletedPage) async {
    try {
      final apiService = ApiService();
      await apiService.createPage(deletedPage.page.title, deletedPage.page.content);
      _deletedPages.remove(deletedPage);
      _saveDeletedItems();
      notifyListeners();
    } catch (e) {
      print('Error restoring page: $e');
      rethrow;
    }
  }

  // Restore a deleted diary
  Future<void> restoreDiary(DeletedDiary deletedDiary) async {
    try {
      final diaryService = DiaryService();
      await diaryService.createEntry(deletedDiary.diary);
      _deletedDiaries.remove(deletedDiary);
      _saveDeletedItems();
      notifyListeners();
    } catch (e) {
      print('Error restoring diary: $e');
      rethrow;
    }
  }

  // Restore a deleted goal
  Future<void> restoreGoal(DeletedGoal deletedGoal) async {
    try {
      await GoalService.createGoal(
        title: deletedGoal.goal.title,
        startDate: deletedGoal.goal.startDate,
        completionDate: deletedGoal.goal.completionDate,
      );
      _deletedGoals.remove(deletedGoal);
      _saveDeletedItems();
      notifyListeners();
    } catch (e) {
      print('Error restoring goal: $e');
      rethrow;
    }
  }

  // Permanently delete a page
  void permanentlyDeletePage(DeletedPage deletedPage) {
    _deletedPages.remove(deletedPage);
    _saveDeletedItems();
    notifyListeners();
  }

  // Permanently delete a diary
  void permanentlyDeleteDiary(DeletedDiary deletedDiary) {
    _deletedDiaries.remove(deletedDiary);
    _saveDeletedItems();
    notifyListeners();
  }

  // Permanently delete a goal
  void permanentlyDeleteGoal(DeletedGoal deletedGoal) {
    _deletedGoals.remove(deletedGoal);
    _saveDeletedItems();
    notifyListeners();
  }
}

class BinPage extends StatefulWidget {
  const BinPage({super.key});

  @override
  State<BinPage> createState() => _BinPageState();
}

class _BinPageState extends State<BinPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late BinProvider _binProvider;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get the shared BinProvider instance
    _binProvider = Provider.of<BinProvider>(context, listen: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: 'Bin',
      onItemSelected: (String page) {
        // Navigation logic is handled by CustomScaffold
      },
      body: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF255DE1),
          automaticallyImplyLeading: false, // Remove back arrow
          centerTitle: true,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.delete_outline, size: 28, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'Bin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48.0),
            child: Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.black54,
                indicatorColor: Colors.black87,
                tabs: const [
                  Tab(text: 'Pages'),
                  Tab(text: 'Diaries'),
                  Tab(text: 'Goals'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Pages Tab
            _buildPagesTab(),
            // Diaries Tab
            _buildDiariesTab(),
            // Goals Tab
            _buildGoalsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPagesTab() {
    return Consumer<BinProvider>(
      builder: (context, binProvider, child) {
        if (binProvider.deletedPages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.description_outlined,
                      size: 48,
                      color: Color(0xFF255DE1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No deleted pages",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: binProvider.deletedPages.length,
          itemBuilder: (context, index) {
            final deletedPage = binProvider.deletedPages[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(deletedPage.page.title),
                subtitle: Text(
                  'Deleted on: ${_formatDate(deletedPage.deletedAt)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore, color: Colors.blue),
                      onPressed: () async {
                        try {
                          await binProvider.restorePage(deletedPage);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Page restored successfully')),
                            );
                            // Refresh pages in the provider
                            Provider.of<PagesProvider>(context, listen: false).fetchPages();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error restoring page: $e')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                          context,
                          'page',
                          () {
                            binProvider.permanentlyDeletePage(deletedPage);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Page permanently deleted')),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDiariesTab() {
    return Consumer<BinProvider>(
      builder: (context, binProvider, child) {
        if (binProvider.deletedDiaries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_book,
                      size: 48,
                      color: Color(0xFF255DE1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No deleted diaries",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: binProvider.deletedDiaries.length,
          itemBuilder: (context, index) {
            final deletedDiary = binProvider.deletedDiaries[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(deletedDiary.diary.title),
                subtitle: Text(
                  'Deleted on: ${_formatDate(deletedDiary.deletedAt)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore, color: Colors.blue),
                      onPressed: () async {
                        try {
                          await binProvider.restoreDiary(deletedDiary);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Diary restored successfully')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error restoring diary: $e')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                          context,
                          'diary',
                          () {
                            binProvider.permanentlyDeleteDiary(deletedDiary);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Diary permanently deleted')),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoalsTab() {
    return Consumer<BinProvider>(
      builder: (context, binProvider, child) {
        if (binProvider.deletedGoals.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.flag_outlined,
                      size: 48,
                      color: Color(0xFF255DE1),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "No deleted goals",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: binProvider.deletedGoals.length,
          itemBuilder: (context, index) {
            final deletedGoal = binProvider.deletedGoals[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(deletedGoal.goal.title),
                subtitle: Text(
                  'Deleted on: ${_formatDate(deletedGoal.deletedAt)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.restore, color: Colors.blue),
                      onPressed: () async {
                        try {
                          await binProvider.restoreGoal(deletedGoal);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Goal restored successfully')),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error restoring goal: $e')),
                            );
                          }
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () {
                        _showDeleteConfirmationDialog(
                          context,
                          'goal',
                          () {
                            binProvider.permanentlyDeleteGoal(deletedGoal);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Goal permanently deleted')),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, String itemType, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete $itemType'),
          content: Text('Are you sure you want to permanently delete this $itemType? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Delete Permanently',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
