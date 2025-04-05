

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/personalScreen/newPages/Openned_diary.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  List<Map<String, dynamic>> diaries = [];
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadDiaries() async {
    try {
      setState(() => isLoading = true);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? diaryData = prefs.getString('diaries');
      
      if (diaryData != null) {
        List<Map<String, dynamic>> loadedDiaries = List<Map<String, dynamic>>.from(
          jsonDecode(diaryData).map((item) => Map<String, dynamic>.from(item))
        );
        
        // Sort diaries by date (newest first)
        loadedDiaries.sort((a, b) {
          DateTime dateA = DateTime.parse(a['date']);
          DateTime dateB = DateTime.parse(b['date']);
          return dateB.compareTo(dateA);
        });

        setState(() {
          diaries = loadedDiaries;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading diaries: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveDiaries() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('diaries', jsonEncode(diaries));
    } catch (e) {
      print('Error saving diaries: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving diary entries'))
      );
    }
  }

  Future<void> _navigateToNewDiary() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const NewDiaryPage(), // No parameters for new diary
        ),
      );

      if (result != null && mounted) {
        setState(() {
          diaries.insert(0, result);
        });
        await _saveDiaries();
      }
    } catch (e) {
      print('Error creating new diary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating new diary entry'))
        );
      }
    }
  }

  Future<void> _openDiary(int index) async {
    try {
      // Create a Map with only serializable data
      Map<String, dynamic> serializedDiary = {
        'title': diaries[index]['title'],
        'content': diaries[index]['content'],
        'date': diaries[index]['date'],
        'backgroundColor': diaries[index]['backgroundColor'],
        'textColor': diaries[index]['textColor'],
        'mood': diaries[index]['mood'],
        'images': diaries[index]['images'],
        'isEditing': true, // Add this flag to indicate it's an existing diary
      };

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewDiaryPage(
            initialData: serializedDiary, // Use initialData instead of diaryData
          ),
        ),
      );

      if (result != null && mounted) {
        setState(() {
          diaries[index] = result;
        });
        await _saveDiaries();
      }
    } catch (e) {
      print('Error opening diary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error opening diary entry'))
        );
      }
    }
  }

  Future<void> _deleteDiary(int index) async {
    try {
      setState(() {
        diaries.removeAt(index);
      });
      await _saveDiaries();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diary entry deleted'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error deleting diary: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error deleting diary entry'))
        );
      }
    }
  }

  Widget _buildRecentDiaryCard(int index) {
    if (index >= diaries.length) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: _navigateToNewDiary,
          child: Container(
            height: 90,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.add_circle_outline,
                  size: 32,
                  color: Colors.grey,
                ),
                SizedBox(height: 4),
                Text(
                  'New Entry',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final diary = diaries[index];
    final date = DateTime.parse(diary['date']);
    Color textColor;
    try {
      textColor = Color(int.parse(diary['textColor']));
    } catch (e) {
      textColor = const Color(0xFF000000);
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _openDiary(index),
        child: Container(
          height: 90,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.book,
                size: 32,
                color: textColor,
              ),
              const SizedBox(height: 4),
              Text(
                diary['title'] ?? DateFormat('MMM d').format(date),
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              Text(
                DateFormat('MMM d').format(date),
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiaryListItem(int index) {
    final diary = diaries[index];
    final date = DateTime.parse(diary['date']);
    final mood = diary['mood'];
    final moodEmoji = {
      'Happy': '😊',
      'Sad': '😢',
      'Excited': '🤩',
      'Tired': '😴',
      'Anxious': '😰',
    }[mood];
    Color backgroundColor;
    Color textColor;
    try {
      backgroundColor = Color(int.parse(diary['backgroundColor']));
    } catch (e) {
      backgroundColor = const Color(0xFFFFFFFF);
    }
    try {
      textColor = Color(int.parse(diary['textColor']));
    } catch (e) {
      textColor = const Color(0xFF000000);
    }

    return Dismissible(
      key: Key(diary['date']),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Diary Entry'),
              content: const Text('Are you sure you want to delete this entry?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) => _deleteDiary(index),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade300,
              ),
            ),
            child: Icon(
              Icons.book,
              color: textColor,
            ),
          ),
          title: Text(
            diary['title'] ?? DateFormat('MMM d, yyyy').format(date),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Row(
            children: [
              Text(DateFormat('MMM d, yyyy').format(date)),
              if (mood != null && moodEmoji != null) ...[
                const SizedBox(width: 8),
                Text(moodEmoji),
              ],
            ],
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openDiary(index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      selectedPage: 'Diary',
      onItemSelected: (String page) {},
      body: RefreshIndicator(
        onRefresh: _loadDiaries,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF255DE1),
              child: const Center(
                child: Text(
                  "Write Today",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Entries",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _navigateToNewDiary,
                    icon: const Icon(Icons.add),
                    label: const Text("New Entry"),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF255DE1),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 110,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: diaries.length + 1,
                itemBuilder: (context, index) => Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  child: _buildRecentDiaryCard(index),
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "All Entries",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Expanded(
              child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : diaries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No diary entries yet",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _navigateToNewDiary,
                            icon: const Icon(Icons.add),
                            label: const Text("Create your first entry"),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF255DE1),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: diaries.length,
                      itemBuilder: (context, index) => _buildDiaryListItem(index),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToNewDiary,
        backgroundColor: const Color(0xFF255DE1),
        child: const Icon(Icons.add),
      ),
    );
  }
}