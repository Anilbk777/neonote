

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:project/personalScreen/quicknotes.dart';
import 'package:project/providers/pages_provider.dart';
import 'package:project/models/page.dart'; // Ensure PageModel is imported
import 'package:project/personalScreen/diary_page.dart';
import 'package:project/dashboard.dart';
import 'package:project/personalScreen/inbox.dart';
import 'package:project/personalScreen/bin.dart';
import 'package:project/personalScreen/calender.dart';
import 'package:project/personalScreen/templates.dart';
import 'package:project/personalScreen/goal.dart';
import 'package:project/personalScreen/tasklist.dart';
import 'package:project/personalScreen/content_page.dart';

class CustomScaffold extends StatefulWidget {
  final String selectedPage;
  final Function(String) onItemSelected;
  final Widget body;
  final FloatingActionButton? floatingActionButton;

  const CustomScaffold({
    super.key,
    required this.selectedPage,
    required this.onItemSelected,
    required this.body,
    this.floatingActionButton,
  });

  @override
  _CustomScaffoldState createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> {
  List<String> personalSpacePages = ['Diary',  'Goals', 'Task List'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: widget.floatingActionButton,
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              height: double.infinity,
              color: const Color(0xFFEFEFF4),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'NeoNote',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF255DE1),
                        ),
                      ),
                    ),
                    const Divider(),
                    _buildSidebarItem(Icons.home, 'Home', '/dashboard'),
                    _buildSidebarItem(Icons.inbox, 'Inbox', InboxPage()),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Personal Space',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.black54),
                            onPressed: () => _showAddPageDialog(context),
                          ),
                        ],
                      ),
                    ),
                    for (var page in personalSpacePages)
                      _buildSidebarItem(Icons.book, page, _getPageByName(page)),
                    Consumer<PagesProvider>(
                      builder: (context, pagesProvider, child) {
                        return Column(
                          children: pagesProvider.pages.map((pageModel) {
                            return ListTile(
                              leading: const Icon(Icons.book, color: Colors.black54),
                              title: Text(
                                pageModel.title,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ContentPage(page: pageModel),
                                  ),
                                );
                              },
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteConfirmationDialog(context, pageModel),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const Divider(),
                    _buildSidebarItem(Icons.calendar_today, 'Calendar', Calenderpage()),
                    _buildSidebarItem(Icons.delete, 'Bin', BinPage()),
                    _buildSidebarItem(Icons.insert_drive_file, 'Templates', TemplatePage()),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: widget.body,
          ),
        ],
      ),
        // floatingActionButton: floatingActionButton,  // Use the parameter here
    );
  }

 Widget _buildSidebarItem(IconData icon, String label, dynamic destination) {
  return ListTile(
    leading: Icon(icon, color: Colors.black54),
    title: Text(
      label,
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
    ),
    onTap: () {
      // Delay navigation until the current frame is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (destination is String) {
          Navigator.pushNamed(context, destination);
        } else if (destination is Widget) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          );
        }
      });
    },
  );
}

  dynamic _getPageByName(String pageName) {
    switch (pageName) {
      case 'Diary':
        return '/diary';
      // case 'Quick Notes':
      //   return QuickNotesPage();
      case 'Goals':
        return GoalPage();
      case 'Task List':
        return TaskScreen();
      default:
        return Container();
    }
  }

  void _showAddPageDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Add New Page'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter page title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Provider.of<PagesProvider>(context, listen: false)
                      .createPage(controller.text, "")
                      .then((newPage) {
                    Navigator.of(dialogContext).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ContentPage(page: newPage)),
                    );
                  });
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }



  void _showDeleteConfirmationDialog(BuildContext context, PageModel pageModel) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Delete Page'),
        content: const Text('Are you sure you want to delete this page?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(), // Close the dialog
            child: const Text('Cancel'),
          ),
          ElevatedButton(
  onPressed: () {
    // Delete the page from the provider
    Provider.of<PagesProvider>(context, listen: false).deletePage(pageModel.id);

    // Close the current page (ContentPage)
    Navigator.of(dialogContext).pop(); // Close the dialog

    // Go back to Dashboard with a delay to prevent concurrent navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()), // Navigate to Dashboard
      );
    });
  },
  child: const Text('Delete'),
)

        ],
      );
    },
  );
}

}
