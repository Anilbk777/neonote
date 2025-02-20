import 'package:flutter/material.dart';
class DynamicPage extends StatelessWidget {
  final String pageName;

  const DynamicPage({super.key, required this.pageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageName), // Use the page name dynamically
      ),
      body: Center(
        child: Text('Welcome to $pageName'),
      ),
    );
  }
}
