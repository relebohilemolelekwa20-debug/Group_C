/*
  GROUP_C - Student Assistant Application
  Members:
  - S.Rululu (222057369)
  - k.Malikoe (224004891)
  - T.Maqala (219004340)
  - R.Molelekwa (222015201)
  Date: May 2026
  Module: TPG316C
*/

import 'package:flutter/material.dart';
import '../views/login_view.dart';
import '../views/home_view.dart';
import '../views/application_form_view.dart';
import '../views/application_detail_view.dart';

class RouteManager {
  // Static route names
  static const String login = '/';
  static const String home = '/home';
  static const String applicationForm = '/application-form';
  static const String applicationDetail = '/application-detail';
  
  // Generate route handler
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const LoginView());
        
      case home:
        return MaterialPageRoute(builder: (_) => const HomeView());
        
      case applicationForm:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ApplicationFormView(
            isEditing: args?['isEditing'] ?? false,
            application: args?['application'],
          ),
        );
        
      case applicationDetail:
        final application = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ApplicationDetailView(application: application),
        );
        
      default:
        throw Exception('Route ${settings.name} not found');
    }
  }
  
  // Navigation methods
  static void pushNamed(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }
  
  static void pushReplacementNamed(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }
  
  static void pop(BuildContext context) {
    Navigator.pop(context);
  }
  
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }
  
  static void pushNamedAndRemoveUntil(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context, 
      routeName, 
      (route) => false,
      arguments: arguments,
    );
  }
}