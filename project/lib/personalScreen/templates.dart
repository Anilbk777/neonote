import 'package:flutter/material.dart';

class TemplatePage extends StatelessWidget {
  final List<Map<String, dynamic>> templates = [
    {
      "name": "Floral Pink",
      "color": Colors.pink[100],
      "icon": Icons.local_florist,
      "iconColor": Colors.pink,
    },
    {
      "name": "Modern Green",
      "color": Colors.green[100],
      "icon": Icons.eco,
      "iconColor": Colors.green,
    },
    {
      "name": "Classic Blue",
      "color": Colors.blue[100],
      "icon": Icons.book,
      "iconColor": Colors.blue,
    },
    {
      "name": "Starry Night",
      "color": Colors.deepPurple[100],
      "icon": Icons.star,
      "iconColor": Colors.deepPurple,
    },
    {
      "name": "Sunshine Yellow",
      "color": Colors.yellow[100],
      "icon": Icons.wb_sunny,
      "iconColor": Colors.orangeAccent,
    },
    {
      "name": "Rainbow",
      "color": Colors.purple[100],
      "icon": Icons.palette,
      "iconColor": Colors.purple,
    },
  ];

  TemplatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose a Template"),
        backgroundColor: const Color(0xFF255DE1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Select a Template Style",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two columns
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(
                          context, template); // Return selected template
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              template["color"] as Color,
                              Colors.white,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: template["iconColor"] as Color,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              template["icon"] as IconData,
                              size: 50,
                              color: template["iconColor"] as Color,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              template["name"] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
