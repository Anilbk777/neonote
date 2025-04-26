import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart'; // Import FlutterQuillLocalizations
import 'package:provider/provider.dart';
import 'package:calendar_view/calendar_view.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'providers/pages_provider.dart';
import 'providers/notification_provider.dart';
import 'app_router.dart';
import 'personalScreen/bin.dart'; // Import BinProvider
import 'package:timezone/data/latest.dart' as tz_data; // Import timezone data

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database
  tz_data.initializeTimeZones();

  // Configure timeago
  timeago.setLocaleMessages('en', timeago.EnMessages());
  timeago.setLocaleMessages('en_short', timeago.EnShortMessages());

  // Get the initial route based on login status
  String initialRoute = await AppRouter.getInitialRoute();

  // Create providers
  final pagesProvider = PagesProvider();
  final binProvider = BinProvider();
  final notificationProvider = NotificationProvider();

  // Initialize notification provider (don't await to avoid blocking app startup)
  notificationProvider.initialize().catchError((error) {
    print('Error initializing notification provider: $error');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: pagesProvider),
        ChangeNotifierProvider.value(value: binProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
      ],
      child: MyApp(initialRoute: initialRoute),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return CalendarControllerProvider(
      controller: EventController(),
      child: MaterialApp(
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
        initialRoute: initialRoute,
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}