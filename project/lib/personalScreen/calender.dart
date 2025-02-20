import 'package:flutter/material.dart';

class Calenderpage extends StatelessWidget {
  const Calenderpage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary'),
      ),
      body: const Center(
        child: Text(
          'This is the Diary Page',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      ),
    );
  }
}
