import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import 'workout_plan_screen.dart';

class UserDataScreen extends StatefulWidget {
  final NotificationService notificationService;
  final DatabaseService databaseService;
  final Map<String, dynamic>? existingProfile;
  
  const UserDataScreen({
    Key? key, 
    required this.notificationService,
    required this.databaseService,
    this.existingProfile,
  }) : super(key: key);

  @override
  _UserDataScreenState createState() => _UserDataScreenState();
}

class _UserDataScreenState extends State<UserDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Form values
  int _age = 30;
  String _gender = 'Male';
  double _weight = 70;
  double _height = 1.75;
  int _workoutFrequency = 4;
  String _fitnessLevel = 'Beginner';
  // Goal is still stored but not shown in UI
  String _goal = 'Get Fit';
  bool _isLoading = false;
  
  // Gender options
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  
  // Fitness level options
  final List<String> _fitnessLevelOptions = ['Beginner', 'Intermediate', 'Advanced'];
  
  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }
  
  void _loadExistingProfile() {
    if (widget.existingProfile != null) {
      setState(() {
        _age = widget.existingProfile!['age'] ?? 30;
        _gender = widget.existingProfile!['gender'] ?? 'Male';
        _weight = widget.existingProfile!['weight'] ?? 70.0;
        _height = widget.existingProfile!['height'] ?? 1.75;
        _workoutFrequency = widget.existingProfile!['workout_frequency'] ?? 4;
        _fitnessLevel = widget.existingProfile!['fitness_level'] ?? 'Beginner';
        _goal = widget.existingProfile!['goal'] ?? 'Get Fit';
      });
    }
  }
  
  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Calculate BMI
        final bmi = _weight / (_height * _height);
        
        // Create user profile
        final userProfile = {
          'name': widget.existingProfile?['name'] ?? 'User',
          'age': _age,
          'gender': _gender,
          'weight': _weight,
          'height': _height,
          'workout_frequency': _workoutFrequency,
          'fitness_level': _fitnessLevel,
          'goal': _goal, // Still save goal even though it's not in UI
          'bmi': bmi,
        };
        
        // Save to database
        await widget.databaseService.saveUserProfile(userProfile);
        
        // Get today's date
        final today = DateTime.now();
        final startDate = DateFormat('yyyy-MM-dd').format(today);
        
        // Generate workout plan
        final result = await _apiService.generateWorkoutPlan(
          userProfile,
          startDate,
          7, // 1 week plan
        );
        
        // Save the workout plan to the database for future reference
        await widget.databaseService.saveWorkoutPlan(
          result['workout_plan'],
          startDate,
          7, // 1 week plan
        );
        
        // Navigate to plan screen
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutPlanScreen(
              workoutPlan: result['workout_plan'],
              notificationService: widget.notificationService,
              databaseService: widget.databaseService,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Information'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Please enter your details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      
                      // Age
                      TextFormField(
                        initialValue: _age.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          border: OutlineInputBorder(),
                        ),
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
                      const SizedBox(height: 16),
                      
                      // Gender
                      DropdownButtonFormField<String>(
                        value: _gender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: _genderOptions.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(gender),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _gender = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Weight
                      TextFormField(
                        initialValue: _weight.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Weight (kg)',
                          border: OutlineInputBorder(),
                        ),
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
                      const SizedBox(height: 16),
                      
                      // Height
                      TextFormField(
                        initialValue: _height.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Height (m)',
                          border: OutlineInputBorder(),
                        ),
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
                      const SizedBox(height: 16),
                      
                      // Workout Frequency
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Workout Frequency: $_workoutFrequency days/week'),
                          Slider(
                            value: _workoutFrequency.toDouble(),
                            min: 1,
                            max: 7,
                            divisions: 6,
                            label: '$_workoutFrequency days/week',
                            onChanged: (value) {
                              setState(() {
                                _workoutFrequency = value.round();
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Fitness Level
                      DropdownButtonFormField<String>(
                        value: _fitnessLevel,
                        decoration: const InputDecoration(
                          labelText: 'Fitness Level',
                          border: OutlineInputBorder(),
                        ),
                        items: _fitnessLevelOptions.map((level) {
                          return DropdownMenuItem(
                            value: level,
                            child: Text(level),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _fitnessLevel = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Submit Button
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        child: const Text(
                          'Generate Workout Plan',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
} 