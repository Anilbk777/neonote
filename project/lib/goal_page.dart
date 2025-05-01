import 'package:flutter/material.dart';
import 'package:project/widgets/custom_scaffold_workspace.dart'; // Assuming you want the same scaffold

class GoalPage extends StatefulWidget {
  final int projectId;
  final String projectTitle; // Add projectTitle parameter

  const GoalPage({
    Key? key,
    required this.projectId,
    required this.projectTitle, // Make it required
  }) : super(key: key);

  @override
  _GoalPageState createState() => _GoalPageState();
}

class _GoalPageState extends State<GoalPage> {
  @override
  Widget build(BuildContext context) {
    // Using CustomScaffoldWorkspace for consistency, adjust if needed
    return CustomScaffoldWorkspace(
      selectedPage: 'Work', // Or maybe none if it's a sub-page
      onItemSelected: (page) {
        // Handle navigation if needed, e.g., back to WorkPage
        if (page == 'Work') {
          Navigator.pop(context); // Simple pop for now
        }
      },
      body: Column( // Wrap body content in a Column
        children: [
          // Add the top bar container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: const BoxDecoration(
              color: Colors.blueAccent, // Blue background
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: SafeArea( // Ensure content is within safe area
              child: Row(
                children: [
                  IconButton( // Back button
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded( // Title text - Removed const
                    child: Text( // Use the passed project title
                      'Goal of ${widget.projectTitle}', // Display dynamic title
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White color
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Add other actions here if needed (e.g., Edit button)
                ],
              ),
            ),
          ),
          // Existing content (placeholder text) - wrapped in Expanded
          Expanded(
            child: Center(
              child: Text(
                'Project Goal Page for Project ID: ${widget.projectId}\n(Content to be added)',
                style: const TextStyle(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}