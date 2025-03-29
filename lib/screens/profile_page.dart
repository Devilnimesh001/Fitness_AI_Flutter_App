import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProfilePage extends StatefulWidget {
  final DatabaseService databaseService;
  final VoidCallback onProfileUpdated;

  const ProfilePage({
    Key? key,
    required this.databaseService,
    required this.onProfileUpdated,
  }) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isEditing = false;
  
  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  
  // Form values
  String _gender = 'Male';
  int _workoutFrequency = 3;
  String _fitnessLevel = 'Beginner';
  String _goal = 'Get Fit';
  
  // Gender options
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  
  // Fitness level options
  final List<String> _fitnessLevelOptions = ['Beginner', 'Intermediate', 'Advanced'];
  
  // Goal options
  final List<String> _goalOptions = [
    'Get Fit', 
    'Lose Weight', 
    'Build Muscle', 
    'Improve Endurance',
    'Increase Flexibility'
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController();
    _ageController = TextEditingController();
    _weightController = TextEditingController();
    _heightController = TextEditingController();
    
    // Load user profile
    _loadProfile();
  }

  @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userProfile = await widget.databaseService.getUserProfile();
      
      // Set values to controllers
      _nameController.text = userProfile['name'] ?? 'User';
      _ageController.text = (userProfile['age'] ?? 30).toString();
      _weightController.text = (userProfile['weight'] ?? 70.0).toString();
      _heightController.text = (userProfile['height'] ?? 1.75).toString();
      
      // Set other values
      setState(() {
        _gender = userProfile['gender'] ?? 'Male';
        _workoutFrequency = userProfile['workout_frequency'] ?? 3;
        _fitnessLevel = userProfile['fitness_level'] ?? 'Beginner';
        _goal = userProfile['goal'] ?? 'Get Fit';
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Build profile data
        final profileData = {
          'name': _nameController.text,
          'age': int.parse(_ageController.text),
          'gender': _gender,
          'weight': double.parse(_weightController.text),
          'height': double.parse(_heightController.text),
          'workout_frequency': _workoutFrequency,
          'fitness_level': _fitnessLevel,
          'goal': _goal,
        };
        
        // Save to database
        await widget.databaseService.saveUserProfile(profileData);
        
        // Notify parent that profile was updated
        widget.onProfileUpdated();
        
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        print('Error saving profile: $e');
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final mediaQuery = MediaQuery.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile header with gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.secondary,
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        _isEditing 
                          ? Row(
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isEditing = false;
                                      _loadProfile(); // Reset values
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: _saveProfile,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Theme.of(context).colorScheme.primary,
                                  ),
                                  child: const Text('Save'),
                                ),
                              ],
                            )
                          : IconButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              icon: const Icon(Icons.edit, color: Colors.white),
                              tooltip: 'Edit Profile',
                            ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Avatar with name
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white.withOpacity(0.9),
                            child: Text(
                              _nameController.text.isNotEmpty 
                                  ? _nameController.text[0].toUpperCase()
                                  : 'U',
                              style: TextStyle(
                                fontSize: 36,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nameController.text,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _fitnessLevel,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // BMI Card
              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Card(
                    margin: const EdgeInsets.only(top: 8),
                    elevation: 3,
                    shadowColor: Colors.black12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'BMI',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getBmiColor().withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getBmiCategory(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _getBmiColor(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _calculateBmi().toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: _getBmiColor(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'kg/m²',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _getBmiPercentage(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getBmiColor(),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // More responsive BMI scale
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildBmiScaleItem('16', 'Under'),
                                _buildBmiScaleItem('18.5', 'Normal'),
                                _buildBmiScaleItem('25', 'Over'),
                                _buildBmiScaleItem('30', 'Obese'),
                                _buildBmiScaleItem('40+', ''),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // Form
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.person, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),
                      ),
                      
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Colors.grey.shade300,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                          prefixIcon: const Icon(Icons.person_outline),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        enabled: _isEditing,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Row for Age and Gender
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Age
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              decoration: InputDecoration(
                                labelText: 'Age',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                                prefixIcon: const Icon(Icons.calendar_today_outlined),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your age';
                                }
                                if (int.tryParse(value) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Gender
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _gender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                                prefixIcon: const Icon(Icons.people_outline),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              items: _genderOptions.map((gender) {
                                return DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: _isEditing
                                ? (value) {
                                    setState(() {
                                      _gender = value!;
                                    });
                                  }
                                : null,
                              isExpanded: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Physical Information
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.accessibility_new, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text(
                              'Physical Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),
                      ),
                      
                      // Row for Weight and Height
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Weight
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              decoration: InputDecoration(
                                labelText: 'Weight (kg)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                                prefixIcon: const Icon(Icons.monitor_weight_outlined),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your weight';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Height
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              decoration: InputDecoration(
                                labelText: 'Height (m)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
                                prefixIcon: const Icon(Icons.height_outlined),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: _isEditing,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Enter your height';
                                }
                                if (double.tryParse(value) == null) {
                                  return 'Enter a valid number';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Workout Preferences
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.fitness_center, size: 20, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text(
                              'Workout Preferences',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Divider(color: Colors.grey.shade300),
                            ),
                          ],
                        ),
                      ),
                      
                      // Workout Frequency
                      Card(
                        elevation: 0,
                        color: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Workout Frequency',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$_workoutFrequency days/week',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Slider(
                                value: _workoutFrequency.toDouble(),
                                min: 1,
                                max: 7,
                                divisions: 6,
                                activeColor: Theme.of(context).colorScheme.primary,
                                inactiveColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                onChanged: _isEditing
                                  ? (value) {
                                      setState(() {
                                        _workoutFrequency = value.round();
                                      });
                                    }
                                  : null,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(7, (index) {
                                  return SizedBox(
                                    width: 24,
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Row for Fitness Level and Goal
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return constraints.maxWidth > 600
                            ? _buildWideLayoutForLevelAndGoal()
                            : _buildNarrowLayoutForLevelAndGoal();
                        }
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Edit button (when not editing)
                      if (!_isEditing)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit Profile'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildWideLayoutForLevelAndGoal() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fitness Level
        Expanded(
          child: _buildFitnessLevelDropdown(),
        ),
        const SizedBox(width: 16),
        // Goal
        Expanded(
          child: _buildGoalDropdown(),
        ),
      ],
    );
  }
  
  Widget _buildNarrowLayoutForLevelAndGoal() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fitness Level
        _buildFitnessLevelDropdown(),
        const SizedBox(height: 16),
        // Goal
        _buildGoalDropdown(),
      ],
    );
  }
  
  Widget _buildFitnessLevelDropdown() {
    return DropdownButtonFormField<String>(
      value: _fitnessLevel,
      decoration: InputDecoration(
        labelText: 'Fitness Level',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
        prefixIcon: const Icon(Icons.fitness_center_outlined),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: _fitnessLevelOptions.map((level) {
        return DropdownMenuItem(
          value: level,
          child: Text(
            level,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _isEditing
        ? (value) {
            setState(() {
              _fitnessLevel = value!;
            });
          }
        : null,
      isExpanded: true,
    );
  }
  
  Widget _buildGoalDropdown() {
    return DropdownButtonFormField<String>(
      value: _goal,
      decoration: InputDecoration(
        labelText: 'Fitness Goal',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
        prefixIcon: const Icon(Icons.flag_outlined),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: _goalOptions.map((goal) {
        return DropdownMenuItem(
          value: goal,
          child: Text(
            goal,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: _isEditing
        ? (value) {
            setState(() {
              _goal = value!;
            });
          }
        : null,
      isExpanded: true,
    );
  }

  double _calculateBmi() {
    double weight = double.tryParse(_weightController.text) ?? 70.0;
    double height = double.tryParse(_heightController.text) ?? 1.75;
    return weight / (height * height);
  }

  String _getBmiCategory() {
    double bmi = _calculateBmi();
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBmiColor() {
    double bmi = _calculateBmi();
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  double _getBmiPercentage() {
    double bmi = _calculateBmi();
    // Create a percentage that fits within 0-1 range for the indicator
    // BMI range from 16 to 40
    if (bmi < 16) return 0;
    if (bmi > 40) return 1;
    return (bmi - 16) / 24; // Normalize between 16 and 40
  }

  Widget _buildBmiScaleItem(String value, String label) {
    return SizedBox(
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
} 