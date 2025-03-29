import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/database_service.dart';
import 'user_data_screen.dart';
import 'profile_page.dart';
import 'diet_plan_page.dart';
import 'workout_plan_screen.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  final NotificationService notificationService;
  final DatabaseService databaseService;

  const HomePage({
    Key? key,
    required this.notificationService,
    required this.databaseService,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  
  late List<Widget> _pages;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _savedWorkoutPlan;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load user profile
      final profile = await widget.databaseService.getUserProfile();
      
      // Load the latest workout plan
      final workoutPlan = await widget.databaseService.getLatestWorkoutPlan();
      
      setState(() {
        _userProfile = profile;
        _savedWorkoutPlan = workoutPlan;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Initialize pages once we have user profile
    if (!_isLoading && _userProfile != null) {
      _pages = [
        _buildHomeContent(),
        WorkoutPlanScreen(
          workoutPlan: _savedWorkoutPlan ?? {}, // Use saved plan or empty map if none exists
          notificationService: widget.notificationService,
          databaseService: widget.databaseService,
        ),
        DietPlanPage(
          databaseService: widget.databaseService,
        ),
        ProfilePage(
          databaseService: widget.databaseService,
          onProfileUpdated: _loadData,
        ),
      ];
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/app_icon.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text('Fitness App'),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            backgroundColor: Colors.white,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
            elevation: 0,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 0 ? Icons.home : Icons.home_outlined),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 1 ? Icons.fitness_center : Icons.fitness_center_outlined),
                label: 'Workouts',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 2 ? Icons.restaurant_menu : Icons.restaurant_menu_outlined),
                label: 'Diet',
              ),
              BottomNavigationBarItem(
                icon: Icon(_selectedIndex == 3 ? Icons.person : Icons.person_outline),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    String userName = _userProfile?['name'] ?? 'Fitness Enthusiast';
    String fitnessLevel = _userProfile?['fitness_level'] ?? 'Beginner';
    bool hasWorkoutPlan = _savedWorkoutPlan != null && _savedWorkoutPlan!.isNotEmpty;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome, $userName!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              fitnessLevel,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (hasWorkoutPlan) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.fitness_center,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Active Workout Plan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Continue where you left off',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedIndex = 1; // Switch to Workouts page
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('View'),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Today's overview
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
              ],
            ),
          ),
          
          // Action cards with modern design
          _buildActionCardModern(
            icon: Icons.fitness_center,
            title: hasWorkoutPlan ? 'Generate New Workout Plan' : 'Generate Workout Plan',
            description: hasWorkoutPlan 
              ? 'Create a new personalized workout plan based on your profile'
              : 'Create a personalized workout plan based on your profile',
            iconColor: Colors.orange,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserDataScreen(
                    notificationService: widget.notificationService,
                    databaseService: widget.databaseService,
                    existingProfile: _userProfile,
                  ),
                ),
              ).then((_) {
                // Reload data when returning from the workout generation
                _loadData();
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Check progress button
          _buildActionCardModern(
            icon: Icons.insights,
            title: 'Check Progress',
            description: 'View your workout completion statistics',
            iconColor: Colors.green,
            onTap: () {
              setState(() {
                _selectedIndex = 2; // Switch to Diet Plan page (which has stats)
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Edit Profile button
          _buildActionCardModern(
            icon: Icons.person,
            title: 'Edit Profile',
            description: 'Update your personal information and preferences',
            iconColor: Colors.purple,
            onTap: () {
              setState(() {
                _selectedIndex = 3; // Switch to Profile page
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Motivational quote with better design
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.format_quote,
                    size: 28,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'The only bad workout is the one that didn\'t happen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontStyle: FontStyle.italic,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start today, your future self will thank you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCardModern({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 