import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'services/notification_service.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initNotifications();
  
  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.initDatabase();
  
  print('Database and notifications initialized');
  
  runApp(MyApp(
    notificationService: notificationService,
    databaseService: databaseService,
  ));
}

class MyApp extends StatelessWidget {
  final NotificationService notificationService;
  final DatabaseService databaseService;
  
  const MyApp({
    Key? key, 
    required this.notificationService,
    required this.databaseService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Freaks AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: HomePage(
        notificationService: notificationService,
        databaseService: databaseService,
      ),
    );
  }
} 