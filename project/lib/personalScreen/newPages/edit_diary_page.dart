import 'package:flutter/material.dart';

class EditDiaryPage extends StatelessWidget {
  final Map<String, String> entry;
  final Function(int) deleteEntry;
  final Function(int, String, String) updateEntry;
  final int index; // To keep track of the diary entry index

   EditDiaryPage({
     super.key,
    required this.entry,
    required this.deleteEntry,
    required this.updateEntry,
    required this.index,
  });

  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    titleController.text = entry['title'] ?? 'Untitled';
    contentController.text = entry['content'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Diary Entry"),
        backgroundColor: const Color(0xFF255DE1),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              deleteEntry(index); // Delete the entry
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: "Write your thoughts here...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Save updates to the entry
                updateEntry(index, titleController.text, contentController.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF255DE1),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                "Save Changes",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
