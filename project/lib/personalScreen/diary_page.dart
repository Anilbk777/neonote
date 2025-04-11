import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:project/widgets/custom_scaffold.dart';
import 'package:project/personalScreen/newPages/Openned_diary.dart';
import 'package:project/services/diary_service.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({Key? key}) : super(key: key);

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  List<Map<String, dynamic>> diaries = [];
  bool isLoading = true;
  final ScrollController _scrollController = ScrollController();

  // We don't need these variables anymore as we're not creating/editing diaries in this class
  // All diary creation/editing is handled in the NewDiaryPage class

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
      print('Loading diaries...');
      setState(() => isLoading = true);
      final diaryService = DiaryService();
      final entries = await diaryService.getAllEntries();
      print('Loaded ${entries.length} diary entries');

      // Convert entries to JSON and debug
      final jsonEntries = entries.map((entry) {
        final json = entry.toJson();
        print('Entry JSON: $json');
        return json;
      }).toList();

      // Sort entries by updated_at or created_at in descending order (newest first)
      // This will ensure that newly created or updated entries appear at the top
      jsonEntries.sort((a, b) {
        DateTime? dateA;
        DateTime? dateB;

        // Try to use updated_at first, then created_at, then fall back to date
        if (a['updated_at'] != null && b['updated_at'] != null) {
          dateA = DateTime.parse(a['updated_at']);
          dateB = DateTime.parse(b['updated_at']);
        } else if (a['created_at'] != null && b['created_at'] != null) {
          dateA = DateTime.parse(a['created_at']);
          dateB = DateTime.parse(b['created_at']);
        } else {
          dateA = DateTime.parse(a['date']);
          dateB = DateTime.parse(b['date']);
        }

        // Compare dates in descending order (newest first)
        return dateB.compareTo(dateA);
      });

      // Print the sorted entries for debugging
      print('Sorted entries:');
      for (var entry in jsonEntries.take(5)) { // Print first 5 entries
        print('ID: ${entry['id']}, Date: ${entry['date']}, Title: ${entry['title']}');
      }

      setState(() {
        diaries = jsonEntries;
        isLoading = false;
        print('Diaries state updated with ${diaries.length} entries');

        // Debug the first diary entry if available
        if (diaries.isNotEmpty) {
          print('First diary in state: ${diaries[0]}');
        }
      });
    } catch (e) {
      print('Error loading diaries: $e');
      setState(() => isLoading = false);
    }
  }

  // This method is now only used to refresh the diary list after returning from the NewDiaryPage
  Future<void> _refreshDiaries() async {
    try {
      print('Refreshing diary list after edit/create');
      // We don't need to call _loadDiaries() here anymore
      // The new/updated diary is already at the top of the list
      // Just update the UI
      setState(() {});
    } catch (e) {
      print('Error refreshing diaries: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error refreshing diaries: $e')),
        );
      }
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
        print('New diary created: $result');

        // Insert the new diary at the top of the list
        setState(() {
          diaries.insert(0, result);
        });

        // Also refresh the list to ensure everything is up to date
        await _refreshDiaries();
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
      // Print the diary data for debugging
      print('Opening diary at index $index with data: ${diaries[index]}');

      // Create a Map with only serializable data
      // Extract and debug title and content
      final title = diaries[index]['title'];
      final content = diaries[index]['content'];
      print('Opening diary with title: "$title", content: "$content"');

      Map<String, dynamic> serializedDiary = {
        'id': diaries[index]['id'],
        'title': title != null ? title.toString() : 'No Title',
        'content': content != null ? content.toString() : '',
        'date': diaries[index]['date'],
        // Ensure color values are properly formatted as integers
        'background_color': diaries[index]['background_color'],
        'text_color': diaries[index]['text_color'],
        'backgroundColor': diaries[index]['background_color'], // For backward compatibility
        'textColor': diaries[index]['text_color'], // For backward compatibility
        'mood': diaries[index]['mood'] ?? '',
        'images': diaries[index]['images'] ?? [],
        'template': diaries[index]['template'] ?? 'Default',
        'isEditing': true, // Add this flag to indicate it's an existing diary
      };

      // Double check the serialized data
      print('Serialized title: "${serializedDiary['title']}"');
      print('Serialized content: "${serializedDiary['content']}"');

      print('Serialized diary data: $serializedDiary');

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => NewDiaryPage(
            initialData: serializedDiary, // Use initialData instead of diaryData
          ),
        ),
      );

      if (result != null && mounted) {
        // Check if the diary was deleted
        if (result is Map && result.containsKey('deleted') && result['deleted'] == true) {
          print('Diary was deleted, removing from list');
          setState(() {
            diaries.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Diary entry deleted')),
          );
        } else {
          print('Diary updated: $result');

          // Remove the old entry
          setState(() {
            diaries.removeAt(index);
          });

          // Insert the updated entry at the top of the list
          setState(() {
            diaries.insert(0, result);
          });

          // Also refresh the list to ensure everything is up to date
          await _refreshDiaries();
        }
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
      final diaryService = DiaryService();
      await diaryService.deleteEntry(diaries[index]['id']);
      setState(() {
        diaries.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diary entry deleted')),
      );
    } catch (e) {
      print('Error deleting diary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting diary entry')),
      );
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
      if (diary['text_color'] != null) {
        textColor = Color(diary['text_color']);
      } else if (diary['textColor'] != null) {
        textColor = Color(diary['textColor']);
      } else {
        textColor = const Color(0xFF000000);
      }
    } catch (e) {
      print('Error parsing text color in recent diary card: $e');
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
    print('Building diary list item for index $index: $diary');

    // Debug title and content
    final title = diary['title'];
    final content = diary['content'];
    print('Title: $title, Content: $content');

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

    // Try to get background color using both naming conventions
    try {
      if (diary['background_color'] != null) {
        backgroundColor = Color(diary['background_color']);
      } else if (diary['backgroundColor'] != null) {
        backgroundColor = Color(diary['backgroundColor']);
      } else {
        backgroundColor = const Color(0xFFFFFFFF);
      }
    } catch (e) {
      print('Error parsing background color: $e');
      backgroundColor = const Color(0xFFFFFFFF);
    }

    // Try to get text color using both naming conventions
    try {
      if (diary['text_color'] != null) {
        textColor = Color(diary['text_color']);
      } else if (diary['textColor'] != null) {
        textColor = Color(diary['textColor']);
      } else {
        textColor = const Color(0xFF000000);
      }
    } catch (e) {
      print('Error parsing text color: $e');
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
            // Try different ways to access the title
            diary['title'] != null && diary['title'].toString().isNotEmpty
                ? diary['title'].toString()
                : (diary.containsKey('title')
                    ? 'Title is empty'
                    : 'No title key - ' + DateFormat('MMM d, yyyy').format(date)),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(DateFormat('MMM d, yyyy').format(date)),
                  if (mood != null && moodEmoji != null) ...[
                    const SizedBox(width: 8),
                    Text(moodEmoji),
                  ],
                ],
              ),
              // Add content preview
              if (diary['content'] != null && diary['content'].toString().isNotEmpty)
                Text(
                  diary['content'].toString().length > 50
                      ? diary['content'].toString().substring(0, 50) + '...'
                      : diary['content'].toString(),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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
                  Row(
                    children: const [
                      Icon(
                        Icons.book,
                        size: 24,
                        color: Color(0xFF255DE1),
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Recent Entries",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  Icon(
                    Icons.book,
                    size: 24,
                    color: Color(0xFF255DE1),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "All Entries",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
    );
  }
}
