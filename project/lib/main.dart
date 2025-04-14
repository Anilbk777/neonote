

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Import FlutterQuillLocalizations
import 'package:provider/provider.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'dashboard.dart';
import 'providers/pages_provider.dart';
import 'package:project/personalScreen/diary_page.dart';
import 'package:project/services/local_storage.dart';

void main() async {
  // Check if the user is already logged in
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PagesProvider()..fetchPages()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _initialRoute = '/login';

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Check if the user is already logged in
    String? token = await LocalStorage.getToken();
    if (token != null && token.isNotEmpty) {
      setState(() {
        _initialRoute = '/dashboard';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NeoNote', // Updated title
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      supportedLocales: const [
        Locale('en'), // Add other locales if needed
      ],
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate, // Fix for FlutterQuill localization
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: _initialRoute,
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/dashboard': (context) => DashboardScreen(),
        '/diary': (context) => DiaryPage(),
      },
    );
  }
}
