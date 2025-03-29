# Flutter App Integration Guide

This guide will help you set up a Flutter app that integrates with the workout scheduler ML model.

## Setting Up a New Flutter Project

1. Install Flutter from [flutter.dev](https://flutter.dev/docs/get-started/install)
2. Create a new Flutter project:

```bash
flutter create workout_scheduler_app
cd workout_scheduler_app
```

## Project Structure

Here's a recommended project structure for your Flutter app:

```
workout_scheduler_app/
├── lib/
│   ├── main.dart                # Main application entry point
│   ├── models/                  # Data models
│   │   ├── user_profile.dart    # User profile model
│   │   ├── workout_plan.dart    # Workout plan model
│   │   └── exercise.dart        # Exercise model
│   ├── screens/                 # App screens
│   │   ├── home_screen.dart     # Home screen
│   │   ├── profile_screen.dart  # User profile screen
│   │   ├── plan_screen.dart     # Workout plan display screen
│   │   └── exercise_screen.dart # Exercise details screen
│   ├── services/                # API and other services
│   │   ├── api_service.dart     # API service for model interaction
│   │   └── notification_service.dart # Notification service
│   └── widgets/                 # Reusable UI components
│       ├── exercise_card.dart   # Exercise card widget
│       └── plan_calendar.dart   # Calendar widget for workout plan
├── pubspec.yaml                 # Dependencies
└── README.md                    # Project documentation
```

## Required Dependencies

Add the following dependencies to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^0.13.4
  provider: ^6.0.2
  shared_preferences: ^2.0.13
  intl: ^0.17.0
  table_calendar: ^3.0.5
  flutter_local_notifications: ^9.4.0
  permission_handler: ^9.2.0
```

Run `flutter pub get` to install these dependencies.

## Key Model and API Integration Files

### 1. User Profile Model (lib/models/user_profile.dart)

```dart
class UserProfile {
  final int age;
  final String gender;
  final double weight;
  final double height;
  final int maxBPM;
  final int avgBPM;
  final int restingBPM;
  final double sessionDuration;
  final int caloriesBurned;
  final double fatPercentage;
  final double waterIntake;
  final int workoutFrequency;
  final String fitnessLevel;
  final double bmi;

  UserProfile({
    required this.age,
    required this.gender,
    required this.weight,
    required this.height,
    this.maxBPM = 180,
    this.avgBPM = 140,
    this.restingBPM = 60,
    this.sessionDuration = 1.0,
    this.caloriesBurned = 700,
    this.fatPercentage = 25.0,
    this.waterIntake = 2.0,
    required this.workoutFrequency,
    required this.fitnessLevel,
    required this.bmi,
  });

  Map<String, dynamic> toJson() {
    return {
      'Age': age,
      'Gender': gender,
      'Weight (kg)': weight,
      'Height (m)': height,
      'Max_BPM': maxBPM,
      'Avg_BPM': avgBPM,
      'Resting_BPM': restingBPM,
      'Session_Duration (hours)': sessionDuration,
      'Calories_Burned': caloriesBurned,
      'Fat_Percentage': fatPercentage,
      'Water_Intake (liters)': waterIntake,
      'Workout_Frequency (days/week)': workoutFrequency,
      'Fitness_Level': fitnessLevel,
      'BMI': bmi,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      age: json['Age'],
      gender: json['Gender'],
      weight: json['Weight (kg)'].toDouble(),
      height: json['Height (m)'].toDouble(),
      maxBPM: json['Max_BPM'] ?? 180,
      avgBPM: json['Avg_BPM'] ?? 140,
      restingBPM: json['Resting_BPM'] ?? 60,
      sessionDuration: json['Session_Duration (hours)'] ?? 1.0,
      caloriesBurned: json['Calories_Burned'] ?? 700,
      fatPercentage: json['Fat_Percentage'] ?? 25.0,
      waterIntake: json['Water_Intake (liters)'] ?? 2.0,
      workoutFrequency: json['Workout_Frequency (days/week)'],
      fitnessLevel: json['Fitness_Level'],
      bmi: json['BMI'].toDouble(),
    );
  }
}
```

### 2. Exercise Model (lib/models/exercise.dart)

```dart
class Exercise {
  final String name;
  final int sets;
  final int reps;
  final String benefit;
  final String targetMuscleGroup;
  final String equipmentNeeded;
  final String difficultyLevel;
  final String workoutType;

  Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.benefit,
    required this.targetMuscleGroup,
    required this.equipmentNeeded,
    required this.difficultyLevel,
    required this.workoutType,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sets': sets,
      'reps': reps,
      'benefit': benefit,
      'target_muscle_group': targetMuscleGroup,
      'equipment_needed': equipmentNeeded,
      'difficulty_level': difficultyLevel,
      'workout_type': workoutType,
    };
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'],
      sets: json['sets'],
      reps: json['reps'],
      benefit: json['benefit'],
      targetMuscleGroup: json['target_muscle_group'],
      equipmentNeeded: json['equipment_needed'],
      difficultyLevel: json['difficulty_level'],
      workoutType: json['workout_type'],
    );
  }
}
```

### 3. Workout Plan Model (lib/models/workout_plan.dart)

```dart
import 'exercise.dart';

class WorkoutPlan {
  final Map<String, List<Exercise>> dailyExercises;

  WorkoutPlan({
    required this.dailyExercises,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    
    dailyExercises.forEach((date, exercises) {
      data[date] = exercises.map((e) => e.toJson()).toList();
    });
    
    return data;
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    final Map<String, List<Exercise>> dailyExercises = {};
    
    json.forEach((date, exercises) {
      dailyExercises[date] = (exercises as List)
          .map((e) => Exercise.fromJson(e))
          .toList();
    });
    
    return WorkoutPlan(dailyExercises: dailyExercises);
  }
}
```

### 4. API Service (lib/services/api_service.dart)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_profile.dart';
import '../models/workout_plan.dart';

class ApiService {
  // Change this to your actual API endpoint
  final String baseUrl = 'http://10.0.2.2:5000'; // For Android emulator
  // Use 'http://localhost:5000' for iOS simulator
  
  Future<WorkoutPlan> generateWorkoutPlan(
      UserProfile userProfile, String startDate, int planDurationDays) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate_plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_profile': userProfile.toJson(),
          'start_date': startDate,
          'plan_duration_days': planDurationDays,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WorkoutPlan.fromJson(data['workout_plan']);
      } else {
        throw Exception('Failed to generate workout plan: ${response.body}');
      }
    } catch (e) {
      throw Exception('API request failed: $e');
    }
  }

  Future<WorkoutPlan> adjustWorkoutPlan(
      WorkoutPlan workoutPlan, Map<String, dynamic> userFeedback) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/adjust_plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'workout_plan': workoutPlan.toJson(),
          'user_feedback': userFeedback,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return WorkoutPlan.fromJson(data['adjusted_plan']);
      } else {
        throw Exception('Failed to adjust workout plan: ${response.body}');
      }
    } catch (e) {
      throw Exception('API request failed: $e');
    }
  }
}
```

### 5. Notification Service (lib/services/notification_service.dart)

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService() {
    init();
  }

  Future<void> init() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Request notification permissions
    await _requestPermissions();

    // Initialize notification settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
        
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false,
    );
        
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
  }

  Future<bool> _requestPermissions() async {
    if (await Permission.notification.request().isGranted) {
      return true;
    }
    return false;
  }

  Future<void> scheduleWorkoutReminder(
      int id, String title, String body, DateTime scheduledDate) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'workout_channel',
          'Workout Reminders',
          channelDescription: 'Channel for workout reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}
```

### 6. Main App (lib/main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.init();
  
  runApp(
    MultiProvider(
      providers: [
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: const WorkoutSchedulerApp(),
    ),
  );
}

class WorkoutSchedulerApp extends StatelessWidget {
  const WorkoutSchedulerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workout Scheduler',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
    );
  }
}
```

## Key Screens

### 1. Home Screen (lib/screens/home_screen.dart)

This is a starting point for your home screen. You'll need to implement:

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user_profile.dart';
import '../models/workout_plan.dart';
import 'profile_screen.dart';
import 'plan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  UserProfile? _userProfile;
  WorkoutPlan? _workoutPlan;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load saved user profile if available
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    // In a real app, load from SharedPreferences or a database
    // For this example, we'll use a hardcoded profile
    setState(() {
      _userProfile = UserProfile(
        age: 30,
        gender: 'Male',
        weight: 75.0,
        height: 1.75,
        workoutFrequency: 4,
        fitnessLevel: 'Intermediate',
        bmi: 24.5,
      );
    });
  }

  Future<void> _generateWorkoutPlan() async {
    if (_userProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set up your profile first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final String startDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final workoutPlan = await _apiService.generateWorkoutPlan(
        _userProfile!,
        startDate,
        7, // 7-day plan
      );

      setState(() {
        _workoutPlan = workoutPlan;
        _isLoading = false;
      });

      // Navigate to the plan screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PlanScreen(workoutPlan: _workoutPlan!),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Scheduler'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text(
                    'Welcome to Workout Scheduler',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            userProfile: _userProfile,
                            onSave: (profile) {
                              setState(() {
                                _userProfile = profile;
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: const Text('Set Up Profile'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _generateWorkoutPlan,
                    child: const Text('Generate Workout Plan'),
                  ),
                  if (_workoutPlan != null) ...[
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlanScreen(workoutPlan: _workoutPlan!),
                          ),
                        );
                      },
                      child: const Text('View Current Plan'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
```

### 2. Profile Screen (lib/screens/profile_screen.dart)

Implement a form to collect user data:

```dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class ProfileScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final Function(UserProfile) onSave;

  const ProfileScreen({
    Key? key,
    this.userProfile,
    required this.onSave,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late int _age;
  late String _gender;
  late double _weight;
  late double _height;
  late int _workoutFrequency;
  late String _fitnessLevel;

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing profile or defaults
    if (widget.userProfile != null) {
      _age = widget.userProfile!.age;
      _gender = widget.userProfile!.gender;
      _weight = widget.userProfile!.weight;
      _height = widget.userProfile!.height;
      _workoutFrequency = widget.userProfile!.workoutFrequency;
      _fitnessLevel = widget.userProfile!.fitnessLevel;
    } else {
      _age = 30;
      _gender = 'Male';
      _weight = 70.0;
      _height = 1.70;
      _workoutFrequency = 3;
      _fitnessLevel = 'Beginner';
    }
  }

  double _calculateBMI() {
    return _weight / (_height * _height);
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final profile = UserProfile(
        age: _age,
        gender: _gender,
        weight: _weight,
        height: _height,
        workoutFrequency: _workoutFrequency,
        fitnessLevel: _fitnessLevel,
        bmi: _calculateBMI(),
      );
      
      widget.onSave(profile);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: _age.toString(),
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  return null;
                },
                onSaved: (value) {
                  _age = int.parse(value!);
                },
              ),
              
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _gender = newValue!;
                  });
                },
              ),
              
              TextFormField(
                initialValue: _weight.toString(),
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  return null;
                },
                onSaved: (value) {
                  _weight = double.parse(value!);
                },
              ),
              
              TextFormField(
                initialValue: _height.toString(),
                decoration: const InputDecoration(labelText: 'Height (m)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  return null;
                },
                onSaved: (value) {
                  _height = double.parse(value!);
                },
              ),
              
              DropdownButtonFormField<int>(
                value: _workoutFrequency,
                decoration: const InputDecoration(labelText: 'Workout Frequency (days/week)'),
                items: [1, 2, 3, 4, 5, 6, 7].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _workoutFrequency = newValue!;
                  });
                },
              ),
              
              DropdownButtonFormField<String>(
                value: _fitnessLevel,
                decoration: const InputDecoration(labelText: 'Fitness Level'),
                items: ['Beginner', 'Intermediate', 'Advanced'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _fitnessLevel = newValue!;
                  });
                },
              ),
              
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

### 3. Plan Screen (lib/screens/plan_screen.dart)

This screen will display the workout plan:

```dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart';
import '../services/notification_service.dart';
import 'package:provider/provider.dart';
import 'exercise_screen.dart';

class PlanScreen extends StatefulWidget {
  final WorkoutPlan workoutPlan;

  const PlanScreen({Key? key, required this.workoutPlan}) : super(key: key);

  @override
  _PlanScreenState createState() => _PlanScreenState();
}

class _PlanScreenState extends State<PlanScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.week;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    
    // Schedule notifications for workout days
    _scheduleWorkoutReminders();
  }

  void _scheduleWorkoutReminders() {
    final notificationService = Provider.of<NotificationService>(context, listen: false);
    
    // Cancel existing notifications
    notificationService.cancelAllNotifications();
    
    // Schedule new notifications for each workout day
    int id = 0;
    widget.workoutPlan.dailyExercises.forEach((dateStr, exercises) {
      if (exercises.isNotEmpty) {
        final date = DateTime.parse(dateStr);
        final workoutTime = DateTime(
          date.year,
          date.month,
          date.day,
          8, // 8 AM
          0,
        );
        
        if (workoutTime.isAfter(DateTime.now())) {
          notificationService.scheduleWorkoutReminder(
            id++,
            'Workout Reminder',
            'You have a workout scheduled for today!',
            workoutTime,
          );
        }
      }
    });
  }

  List<Exercise> _getExercisesForDay(DateTime day) {
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    return widget.workoutPlan.dailyExercises[dateStr] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Plan'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 7)),
            lastDay: DateTime.now().add(const Duration(days: 30)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            eventLoader: (day) {
              // Mark days with exercises
              return _getExercisesForDay(day);
            },
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
          ),
          const Divider(),
          Expanded(
            child: _buildExerciseList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList() {
    final exercises = _getExercisesForDay(_selectedDay);
    
    if (exercises.isEmpty) {
      return const Center(
        child: Text('No exercises scheduled for this day'),
      );
    }
    
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            title: Text(exercise.name),
            subtitle: Text('${exercise.sets} sets x ${exercise.reps} reps'),
            trailing: Icon(
              _getIconForWorkoutType(exercise.workoutType),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseScreen(exercise: exercise),
                ),
              );
            },
          ),
        );
      },
    );
  }

  IconData _getIconForWorkoutType(String workoutType) {
    switch (workoutType) {
      case 'Strength':
        return Icons.fitness_center;
      case 'Cardio':
        return Icons.directions_run;
      case 'HIIT':
        return Icons.timer;
      case 'Yoga':
        return Icons.self_improvement;
      default:
        return Icons.sports;
    }
  }
}
```

## Next Steps

1. Complete the implementation of the screens and widgets
2. Set up the API service to connect to your Flask backend
3. Implement proper error handling and loading states
4. Add user authentication if needed
5. Enhance the UI with custom styling and animations

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Flutter Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)
- [HTTP Package for Flutter](https://pub.dev/packages/http)
- [Provider Package for State Management](https://pub.dev/packages/provider)
- [Table Calendar for Flutter](https://pub.dev/packages/table_calendar) 