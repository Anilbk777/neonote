import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project/personalScreen/templates.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  _DiaryPageState createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  Map<String, dynamic>? selectedTemplate;
  TextEditingController diaryController = TextEditingController();
  TextEditingController titleController = TextEditingController();
  String currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  List<Map<String, String>> previousEntries = [];

  void _addFile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("File added!")),
    );
  }

  void _addPicture() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Picture added!")),
    );
  }

  void _addVoice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Voice note added!")),
    );
  }

  void _saveEntry() {
    final diaryText = diaryController.text;
    final title = titleController.text;

    if (diaryText.isNotEmpty) {
      setState(() {
        previousEntries.add({
          'title': title.isNotEmpty ? title : 'Untitled',
          'date': currentDate,
          'content': diaryText,
        });
      });
      diaryController.clear();
      titleController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Diary entry saved!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Diary entry is empty!")),
      );
    }
  }

  void _deleteEntry(int index) {
    setState(() {
      previousEntries.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Entry deleted!")),
    );
  }

  void _editEntry(int index) {
    final entry = previousEntries[index];
    titleController.text = entry['title'] ?? '';
    diaryController.text = entry['content'] ?? '';
    setState(() {
      previousEntries.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF255DE1),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () async {
              final template = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TemplatePage()),
              );
              if (template != null && template is Map<String, dynamic>) {
                setState(() {
                  selectedTemplate = template;
                });
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Side: Previous Entries List
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: previousEntries.length,
                itemBuilder: (context, index) {
                  final entry = previousEntries[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(entry['title'] ?? 'Untitled'),
                      subtitle: Text("Date: ${entry['date']}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditDiaryPage(
                                entry: entry,
                                index: index,
                                deleteEntry: _deleteEntry,
                                updateEntry: _saveEntry,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Right Side: Diary Editor
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: selectedTemplate != null
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          selectedTemplate!["color"] as Color,
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Date: $currentDate",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: "Topic or Title",
                      hintText: "Enter the title of your diary",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: TextField(
                      controller: diaryController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        hintText: "Write your thoughts here...",
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.black54),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: _addFile,
                      ),
                      IconButton(
                        icon: const Icon(Icons.photo),
                        onPressed: _addPicture,
                      ),
                      IconButton(
                        icon: const Icon(Icons.mic),
                        onPressed: _addVoice,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF255DE1),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      "Save Entry",
                      style: TextStyle(fontSize: 16),
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

  @override
  void dispose() {
    diaryController.dispose();
    titleController.dispose();
    super.dispose();
  }
}

class EditDiaryPage extends StatefulWidget {
  final Map<String, String> entry;
  final int index;
  final Function(int) deleteEntry;
  final Function updateEntry;

  const EditDiaryPage({
    super.key,
    required this.entry,
    required this.index,
    required this.deleteEntry,
    required this.updateEntry,
  });

  @override
  _EditDiaryPageState createState() => _EditDiaryPageState();
}

class _EditDiaryPageState extends State<EditDiaryPage> {
  late TextEditingController titleController;
  late TextEditingController diaryController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.entry['title']);
    diaryController = TextEditingController(text: widget.entry['content']);
  }

  void _saveChanges() {
    final updatedTitle = titleController.text;
    final updatedContent = diaryController.text;

    if (updatedContent.isNotEmpty) {
      setState(() {
        widget.updateEntry();
        widget.deleteEntry(widget.index); // Remove the old entry
        widget.updateEntry(updatedTitle, updatedContent);
      });
      Navigator.pop(context); // Close the screen after saving changes
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Diary entry is empty!")),
      );
    }
  }

  void _deleteDiary() {
    widget.deleteEntry(widget.index); // Delete the diary entry
    Navigator.pop(context); // Close the screen after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Diary Entry"),
        backgroundColor: const Color(0xFF255DE1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Topic or Title",
                hintText: "Enter the title of your diary",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TextField(
                controller: diaryController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: "Write your thoughts here...",
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Colors.black54),
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF255DE1),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: _deleteDiary,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    "Delete Entry",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    diaryController.dispose();
    super.dispose();
  }
}
