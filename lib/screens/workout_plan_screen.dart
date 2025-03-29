import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import 'user_data_screen.dart';

class WorkoutPlanScreen extends StatefulWidget {
  final Map<String, dynamic> workoutPlan;
  final NotificationService notificationService;
  final DatabaseService databaseService;
  
  const WorkoutPlanScreen({
    Key? key,
    required this.workoutPlan,
    required this.notificationService,
    required this.databaseService,
  }) : super(key: key);

  @override
  _WorkoutPlanScreenState createState() => _WorkoutPlanScreenState();
}

class _WorkoutPlanScreenState extends State<WorkoutPlanScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<String, List<dynamic>> _formattedWorkoutPlan;
  Map<String, bool> _completedExercises = {};
  bool _isLoading = true;
  TimeOfDay _reminderTime = TimeOfDay(hour: 8, minute: 0); // Default 8:00 AM
  
  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.week;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    
    // Format the workout plan data for consistent access
    _formatWorkoutPlanData();
    
    // Find the first day with exercises and select it
    _selectInitialDay();
    
    // Load completion status for exercises
    _loadCompletionStatus();
    
    // Schedule notifications for all workout days
    _scheduleNotifications();
  }
  
  void _formatWorkoutPlanData() {
    // Convert the workout plan data to a consistent format
    _formattedWorkoutPlan = {};
    if (widget.workoutPlan.isNotEmpty) {
      // Iterate through the dates in the workout plan
      widget.workoutPlan.forEach((dateStr, exercises) {
        // Format the exercises list
        if (exercises is List) {
          _formattedWorkoutPlan[dateStr] = exercises;
        }
      });
    }
    print('Formatted workout plan: ${_formattedWorkoutPlan.keys.length} days');
  }
  
  void _selectInitialDay() {
    // First try to select today if it has exercises
    final today = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(today);
    
    // Check if today has exercises
    if (_formattedWorkoutPlan.containsKey(todayStr) && 
        (_formattedWorkoutPlan[todayStr]?.isNotEmpty ?? false)) {
      _selectedDay = today;
      _focusedDay = today;
      return;
    }
    
    // If no exercises today, find the closest day with exercises
    if (_formattedWorkoutPlan.isNotEmpty) {
      try {
        List<DateTime> datesWithExercises = _formattedWorkoutPlan.keys
            .map((dateStr) => DateTime.parse(dateStr))
            .toList();
        
        // Sort dates
        datesWithExercises.sort();
        
        // Find the first date after today (or the last date before today if none after)
        DateTime? selectedDate;
        for (var date in datesWithExercises) {
          if (date.isAfter(today) || date.year == today.year && 
              date.month == today.month && date.day == today.day) {
            selectedDate = date;
            break;
          }
        }
        
        // If no date after today, take the most recent date
        if (selectedDate == null && datesWithExercises.isNotEmpty) {
          selectedDate = datesWithExercises.last;
        }
        
        if (selectedDate != null) {
          _selectedDay = selectedDate;
          _focusedDay = selectedDate;
          print('Selected initial day: ${DateFormat('yyyy-MM-dd').format(selectedDate)}');
        }
      } catch (e) {
        print('Error finding initial day: $e');
      }
    }
  }
  
  Future<void> _loadCompletionStatus() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load completion status for all exercises in the plan
      for (String dateStr in _formattedWorkoutPlan.keys) {
        final exercises = _formattedWorkoutPlan[dateStr] ?? [];
        for (var exercise in exercises) {
          if (exercise is Map && exercise.containsKey('name')) {
            final exerciseName = exercise['name'] as String;
            final isCompleted = await widget.databaseService.isExerciseCompleted(dateStr, exerciseName);
            _completedExercises['$dateStr-$exerciseName'] = isCompleted;
          }
        }
      }
    } catch (e) {
      print('Error loading completion status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _toggleExerciseCompletion(String dateStr, String exerciseName) async {
    final key = '$dateStr-$exerciseName';
    final isCurrentlyCompleted = _completedExercises[key] ?? false;
    
    setState(() {
      _completedExercises[key] = !isCurrentlyCompleted;
    });
    
    try {
      if (isCurrentlyCompleted) {
        await widget.databaseService.markExerciseAsIncomplete(dateStr, exerciseName);
      } else {
        await widget.databaseService.markExerciseAsCompleted(dateStr, exerciseName);
      }
    } catch (e) {
      print('Error toggling exercise completion: $e');
      // Revert state if an error occurs
      setState(() {
        _completedExercises[key] = isCurrentlyCompleted;
      });
    }
  }
  
  void _scheduleNotifications() {
    // TODO: Implement notification scheduling for workout days
  }
  
  Future<void> _setReminderTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    
    if (pickedTime != null && pickedTime != _reminderTime) {
      setState(() {
        _reminderTime = pickedTime;
      });
      
      _scheduleReminderNotifications();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workout reminder set for ${pickedTime.format(context)} daily'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  
  void _scheduleReminderNotifications() async {
    try {
      // Cancel existing notifications
      await widget.notificationService.cancelAllNotifications();
      
      // Get next 7 days
      final now = DateTime.now();
      
      // Schedule notifications for each day with exercises
      for (int i = 0; i < 7; i++) {
        final day = now.add(Duration(days: i));
        final dateStr = DateFormat('yyyy-MM-dd').format(day);
        final exercises = _formattedWorkoutPlan[dateStr] ?? [];
        
        if (exercises.isNotEmpty) {
          // Create a DateTime for the reminder with the selected time
          final reminderDateTime = DateTime(
            day.year,
            day.month,
            day.day,
            _reminderTime.hour,
            _reminderTime.minute,
          );
          
          // Only schedule if the time is in the future
          if (reminderDateTime.isAfter(now)) {
            await widget.notificationService.scheduleWorkoutReminder(
              i,
              'Time for your workout!',
              'You have ${exercises.length} exercises planned for today',
              reminderDateTime,
            );
            
            print('Scheduled notification for $dateStr at ${_reminderTime.format(context)}');
          }
        }
      }
    } catch (e) {
      print('Error scheduling notifications: $e');
    }
  }
  
  List<dynamic> _getExercisesForDay(DateTime day) {
    // Format the date as a string
    final dateStr = DateFormat('yyyy-MM-dd').format(day);
    
    // Get the exercises for the date
    return _formattedWorkoutPlan[dateStr] ?? [];
  }
  
  Widget _buildExerciseList() {
    final exercises = _getExercisesForDay(_selectedDay);
    
    if (exercises.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No exercises planned for this day',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select a different day or check your workout plan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
        final exerciseName = exercise['name'] as String? ?? 'Unknown Exercise';
        final isCompleted = _completedExercises['$dateStr-$exerciseName'] ?? false;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    exerciseName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    exercise['target_muscle_group'] as String? ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildExerciseDetail('Sets', exercise['sets']),
                _buildExerciseDetail('Reps', exercise['reps']),
                if (exercise['duration_seconds'] != null)
                  _buildExerciseDetail('Duration', '${exercise['duration_seconds']} seconds'),
                _buildExerciseDetail('Difficulty', exercise['difficulty_level']),
                const SizedBox(height: 8),
                Text(
                  exercise['benefit'] as String? ?? 'No description available',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                isCompleted ? Icons.check_circle : Icons.circle_outlined,
                color: isCompleted ? Colors.green : Colors.grey,
                size: 30,
              ),
              onPressed: () {
                _toggleExerciseCompletion(dateStr, exerciseName);
              },
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildExerciseDetail(String label, dynamic value) {
    if (value == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _navigateToGenerateWorkoutPlan() async {
    final userProfile = await widget.databaseService.getUserProfile();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserDataScreen(
          notificationService: widget.notificationService,
          databaseService: widget.databaseService,
          existingProfile: userProfile,
        ),
      ),
    ).then((_) {
      // Reload current screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WorkoutPlanScreen(
            workoutPlan: {},
            notificationService: widget.notificationService,
            databaseService: widget.databaseService,
          ),
        ),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Workout Plan'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show empty state if no workout plan available
    if (_formattedWorkoutPlan.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Your Workout Plan'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.fitness_center,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              const Text(
                'No Workout Plan Yet',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Generate your personalized workout plan to get started on your fitness journey',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _navigateToGenerateWorkoutPlan,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Generate Workout Plan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Workout Plan'),
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 30)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
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
            eventLoader: (day) {
              // Show dots on days with exercises
              final exercises = _getExercisesForDay(day);
              return exercises.isNotEmpty ? [true] : [];
            },
            calendarStyle: CalendarStyle(
              markersMaxCount: 1,
              markerDecoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Selected day info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMM dd, yyyy').format(_selectedDay),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${_getExercisesForDay(_selectedDay).length} Exercises',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _buildExerciseList(),
          ),
        ],
      ),
      // Floating action button for setting reminders
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _setReminderTime,
        icon: Icon(Icons.alarm),
        label: Text('Set Reminder'),
        tooltip: 'Set a daily reminder for your workouts',
      ),
    );
  }
} 