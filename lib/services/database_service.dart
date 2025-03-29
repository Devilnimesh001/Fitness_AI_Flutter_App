import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    final path = join(await getDatabasesPath(), 'workout_app.db');
    
    return await openDatabase(
      path,
      version: 2, // Increased version for new schema
      onCreate: (Database db, int version) async {
        // Create user profile table
        await db.execute('''
          CREATE TABLE user_profile (
            id INTEGER PRIMARY KEY,
            name TEXT,
            age INTEGER,
            gender TEXT,
            weight REAL,
            height REAL,
            workout_frequency INTEGER,
            fitness_level TEXT,
            goal TEXT,
            created_at TEXT
          )
        ''');
        
        // Create completed workouts table for tracking progress
        await db.execute('''
          CREATE TABLE completed_workouts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT,
            exercise_name TEXT,
            completed INTEGER DEFAULT 0,
            workout_date TEXT
          )
        ''');
        
        // Create app_preferences table for storing app settings
        await db.execute('''
          CREATE TABLE app_preferences (
            key TEXT PRIMARY KEY,
            value TEXT,
            value_type TEXT,
            updated_at TEXT
          )
        ''');
        
        // Create workout_plans table for storing generated plans
        await db.execute('''
          CREATE TABLE workout_plans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_date TEXT,
            end_date TEXT,
            plan_data TEXT,
            created_at TEXT
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Create workout_plans table if upgrading from version 1
          await db.execute('''
            CREATE TABLE workout_plans (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              start_date TEXT,
              end_date TEXT,
              plan_data TEXT,
              created_at TEXT
            )
          ''');
        }
      },
    );
  }

  // User Profile Methods
  Future<Map<String, dynamic>> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1], // We'll always use ID 1 for the single user
    );

    if (maps.isNotEmpty) {
      print('Retrieved user profile: ${maps.first}');
      return maps.first;
    }

    // Return default profile if none exists
    final defaultProfile = {
      'id': 1,
      'name': 'User',
      'age': 30,
      'gender': 'Male',
      'weight': 70.0,
      'height': 1.75,
      'workout_frequency': 3,
      'fitness_level': 'Beginner',
      'goal': 'Get Fit', // Default goal value
      'created_at': DateTime.now().toIso8601String(),
    };
    
    print('Returning default profile as no user profile found');
    return defaultProfile;
  }

  Future<void> saveUserProfile(Map<String, dynamic> userProfile) async {
    final db = await database;
    
    // Ensure goal has a default value if not provided
    if (!userProfile.containsKey('goal') || userProfile['goal'] == null) {
      userProfile['goal'] = 'Get Fit';
    }
    
    // Create a copy of the profile without the 'bmi' field since it's not in the database schema
    final Map<String, dynamic> profileToSave = Map.from(userProfile);
    profileToSave.remove('bmi'); // Remove bmi as it's not in the database schema
    
    print('Saving user profile: $profileToSave');
    
    // Check if profile exists
    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
    );
    
    if (maps.isEmpty) {
      // Insert new profile
      await db.insert('user_profile', {
        'id': 1,
        ...profileToSave,
        'created_at': DateTime.now().toIso8601String(),
      });
      print('Inserted new user profile');
    } else {
      // Update existing profile
      await db.update(
        'user_profile',
        profileToSave,
        where: 'id = ?',
        whereArgs: [1],
      );
      print('Updated existing user profile');
    }
  }

  // App Preferences Methods (replacing SharedPreferences functionality)
  
  // Save a string preference
  Future<void> setString(String key, String value) async {
    await _savePreference(key, value, 'string');
  }
  
  // Get a string preference
  Future<String?> getString(String key) async {
    return await _getPreference(key, 'string') as String?;
  }
  
  // Save a boolean preference
  Future<void> setBool(String key, bool value) async {
    await _savePreference(key, value.toString(), 'bool');
  }
  
  // Get a boolean preference
  Future<bool?> getBool(String key) async {
    final value = await _getPreference(key, 'bool');
    return value != null ? value.toString() == 'true' : null;
  }
  
  // Save an integer preference
  Future<void> setInt(String key, int value) async {
    await _savePreference(key, value.toString(), 'int');
  }
  
  // Get an integer preference
  Future<int?> getInt(String key) async {
    final value = await _getPreference(key, 'int');
    return value != null ? int.tryParse(value.toString()) : null;
  }
  
  // Save a double preference
  Future<void> setDouble(String key, double value) async {
    await _savePreference(key, value.toString(), 'double');
  }
  
  // Get a double preference
  Future<double?> getDouble(String key) async {
    final value = await _getPreference(key, 'double');
    return value != null ? double.tryParse(value.toString()) : null;
  }
  
  // Helper method to save a preference
  Future<void> _savePreference(String key, String value, String type) async {
    final db = await database;
    
    // Check if key exists
    final List<Map<String, dynamic>> existing = await db.query(
      'app_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    
    if (existing.isEmpty) {
      // Insert new preference
      await db.insert('app_preferences', {
        'key': key,
        'value': value,
        'value_type': type,
        'updated_at': DateTime.now().toIso8601String(),
      });
      print('Inserted new preference: $key = $value ($type)');
    } else {
      // Update existing preference
      await db.update(
        'app_preferences',
        {
          'value': value,
          'value_type': type,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'key = ?',
        whereArgs: [key],
      );
      print('Updated preference: $key = $value ($type)');
    }
  }
  
  // Helper method to retrieve a preference
  Future<dynamic> _getPreference(String key, String type) async {
    final db = await database;
    
    final List<Map<String, dynamic>> results = await db.query(
      'app_preferences',
      where: 'key = ? AND value_type = ?',
      whereArgs: [key, type],
    );
    
    if (results.isEmpty) {
      print('Preference not found: $key ($type)');
      return null;
    }
    
    print('Retrieved preference: $key = ${results.first['value']} (${results.first['value_type']})');
    return results.first['value'];
  }
  
  // Clear all preferences
  Future<void> clearPreferences() async {
    final db = await database;
    await db.delete('app_preferences');
    print('Cleared all preferences');
  }
  
  // Remove a specific preference
  Future<void> removePreference(String key) async {
    final db = await database;
    await db.delete(
      'app_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    print('Removed preference: $key');
  }
  
  // Workout Plan Storage Methods
  
  // Save a workout plan
  Future<int> saveWorkoutPlan(Map<String, dynamic> workoutPlan, String startDate, int durationDays) async {
    final db = await database;
    
    // Calculate end date
    final startDateTime = DateTime.parse(startDate);
    final endDateTime = startDateTime.add(Duration(days: durationDays - 1));
    final endDate = "${endDateTime.year}-${endDateTime.month.toString().padLeft(2, '0')}-${endDateTime.day.toString().padLeft(2, '0')}";
    
    // Convert workout plan to JSON
    final planJson = jsonEncode(workoutPlan);
    
    // Save to database
    final id = await db.insert('workout_plans', {
      'start_date': startDate,
      'end_date': endDate,
      'plan_data': planJson,
      'created_at': DateTime.now().toIso8601String(),
    });
    
    print('Saved workout plan with ID: $id');
    return id;
  }
  
  // Get the most recent workout plan
  Future<Map<String, dynamic>?> getLatestWorkoutPlan() async {
    final db = await database;
    
    final List<Map<String, dynamic>> results = await db.query(
      'workout_plans',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    
    if (results.isEmpty) {
      print('No workout plans found');
      return null;
    }
    
    try {
      final planJson = results.first['plan_data'] as String;
      final Map<String, dynamic> workoutPlan = jsonDecode(planJson);
      
      print('Retrieved latest workout plan from ${results.first['start_date']} to ${results.first['end_date']}');
      return workoutPlan;
    } catch (e) {
      print('Error parsing workout plan: $e');
      return null;
    }
  }
  
  // Get workout plan for a specific date range
  Future<Map<String, dynamic>?> getWorkoutPlanForDateRange(String startDate, String endDate) async {
    final db = await database;
    
    final List<Map<String, dynamic>> results = await db.query(
      'workout_plans',
      where: '(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)',
      whereArgs: [startDate, startDate, endDate, endDate, startDate, endDate],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    
    if (results.isEmpty) {
      print('No workout plans found for date range $startDate to $endDate');
      return null;
    }
    
    try {
      final planJson = results.first['plan_data'] as String;
      final Map<String, dynamic> workoutPlan = jsonDecode(planJson);
      
      print('Retrieved workout plan from ${results.first['start_date']} to ${results.first['end_date']}');
      return workoutPlan;
    } catch (e) {
      print('Error parsing workout plan: $e');
      return null;
    }
  }

  // Workout Tracking Methods
  Future<void> markExerciseAsCompleted(String date, String exerciseName) async {
    final db = await database;
    
    // First check if the record exists
    final List<Map<String, dynamic>> existing = await db.query(
      'completed_workouts',
      where: 'date = ? AND exercise_name = ?',
      whereArgs: [date, exerciseName],
    );
    
    if (existing.isEmpty) {
      // Insert new record
      await db.insert('completed_workouts', {
        'date': date,
        'exercise_name': exerciseName,
        'completed': 1,
        'workout_date': DateTime.now().toIso8601String(),
      });
    } else {
      // Update existing record
      await db.update(
        'completed_workouts',
        {'completed': 1, 'workout_date': DateTime.now().toIso8601String()},
        where: 'date = ? AND exercise_name = ?',
        whereArgs: [date, exerciseName],
      );
    }
  }

  Future<void> markExerciseAsIncomplete(String date, String exerciseName) async {
    final db = await database;
    
    await db.update(
      'completed_workouts',
      {'completed': 0},
      where: 'date = ? AND exercise_name = ?',
      whereArgs: [date, exerciseName],
    );
  }

  Future<bool> isExerciseCompleted(String date, String exerciseName) async {
    final db = await database;
    
    final List<Map<String, dynamic>> result = await db.query(
      'completed_workouts',
      where: 'date = ? AND exercise_name = ?',
      whereArgs: [date, exerciseName],
    );
    
    if (result.isEmpty) return false;
    return result.first['completed'] == 1;
  }

  Future<Map<String, int>> getProgressStats(List<String> dates) async {
    final db = await database;
    
    // Total exercises for the dates
    int totalExercises = 0;
    int completedExercises = 0;
    
    for (String date in dates) {
      // Count all exercises for this date (we're determining this from completed_workouts entries)
      final allExercises = await db.query(
        'completed_workouts',
        where: 'date = ?',
        whereArgs: [date],
      );
      
      totalExercises += allExercises.length;
      
      // Count completed exercises
      final completed = await db.query(
        'completed_workouts',
        where: 'date = ? AND completed = ?',
        whereArgs: [date, 1],
      );
      
      completedExercises += completed.length;
    }
    
    return {
      'total': totalExercises,
      'completed': completedExercises,
    };
  }
  
  // Get workout completion by day for the chart
  Future<List<Map<String, dynamic>>> getCompletionByDay(int days) async {
    final db = await database;
    final List<Map<String, dynamic>> results = [];
    
    // Get dates for last X days
    final now = DateTime.now();
    
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      
      // Get total exercises for this date
      final allExercises = await db.query(
        'completed_workouts',
        where: 'date = ?',
        whereArgs: [dateStr],
      );
      
      // Get completed exercises
      final completed = await db.query(
        'completed_workouts',
        where: 'date = ? AND completed = ?',
        whereArgs: [dateStr, 1],
      );
      
      double completionRate = 0;
      if (allExercises.isNotEmpty) {
        completionRate = completed.length / allExercises.length;
      }
      
      results.add({
        'date': dateStr,
        'completion_rate': completionRate,
        'total': allExercises.length,
        'completed': completed.length,
      });
    }
    
    return results;
  }
} 