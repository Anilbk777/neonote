import 'package:flutter/material.dart';
import 'package:project/dashboard.dart';
import 'package:project/login_page.dart';
import 'package:project/register_page.dart';
import 'package:project/personalScreen/diary_page.dart';
import 'package:project/services/local_storage.dart';
import 'package:project/home_page.dart';

class AppRouter {
  static const String homeRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String dashboardRoute = '/dashboard';
  static const String diaryRoute = '/diary';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homeRoute:
        return MaterialPageRoute(builder: (_) => HomePage());
      case loginRoute:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case registerRoute:
        return MaterialPageRoute(builder: (_) => RegisterPage());
      case dashboardRoute:
        return MaterialPageRoute(builder: (_) => DashboardScreen());
      case diaryRoute:
        return MaterialPageRoute(builder: (_) => DiaryPage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }

  static Future<String> getInitialRoute() async {
    return homeRoute;
  }
}
