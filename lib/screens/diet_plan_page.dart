import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import 'dart:math';
import 'dart:ui' as ui;

class DietPlanPage extends StatefulWidget {
  final DatabaseService databaseService;

  const DietPlanPage({
    Key? key,
    required this.databaseService,
  }) : super(key: key);

  @override
  _DietPlanPageState createState() => _DietPlanPageState();
}

class _DietPlanPageState extends State<DietPlanPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _progressData = [];
  Map<String, int> _progressStats = {'total': 0, 'completed': 0};
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProgressData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProgressData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get last 7 days progression data
      final progressData = await widget.databaseService.getCompletionByDay(7);
      
      // Get total progress stats for the same period
      final dates = progressData.map((e) => e['date'] as String).toList();
      final progressStats = await widget.databaseService.getProgressStats(dates);
      
      setState(() {
        _progressData = progressData;
        _progressStats = progressStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading progress data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Scaffold(
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 5, 16, 0),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                ' ',
                style: TextStyle(
                  fontSize: 5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 1),
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                tabs: const [
                  Tab(
                    text: 'Nutrition Plan',
                    icon: Icon(Icons.restaurant_menu, size: 25),
                  ),
                  Tab(
                    text: 'Progress',
                    icon: Icon(Icons.trending_up, size: 25),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
    Center(child: _buildNutritionTab()),  // Centered content
    Center(child: _buildProgressTab()),
        ],
      ),
    );
  }
  
  Widget _buildNutritionTab() {
    return RefreshIndicator(
      onRefresh: _loadProgressData,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Daily summary card
          _buildDailySummaryCard(),
          
          const SizedBox(height: 16),
          
          // Macronutrients section
          _buildNutritionCard(),
          
          const SizedBox(height: 16),
          
          // Meal title with button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Meal Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.sync, size: 14),
                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Meal suggestions
          _buildMealSuggestions(),
          
          const SizedBox(height: 16),
          
          // Set Reminder Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Implement meal reminder functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reminder set for your meals!'))
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Set Meal Reminders'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Tips and advice
          _buildNutritionTipsCard(),
        ],
      ),
    );
  }
  
  Widget _buildProgressTab() {
    return RefreshIndicator(
      onRefresh: _loadProgressData,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Stats overview
          _buildStatsOverview(),
          
          const SizedBox(height: 16),
          
          // Progress chart
          _buildProgressChart(),
          
          const SizedBox(height: 16),
          
          // Daily activity breakdown card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workout Distribution',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: 1.3,
                    child: _buildCustomPieChart(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDailySummaryCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Today\'s Plan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '2,150 kcal',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Calories progress
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Calories Consumed',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '1,450 / 2,150 kcal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: 0.67, // 1450/2150
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 14),
            
            // Water intake
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Water Intake',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '5 / 8 glasses',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: List.generate(8, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.water_drop,
                        color: index < 5 ? Colors.blue : Colors.grey.shade300,
                        size: 20,
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatsOverview() {
    // Calculate completion percentage
    double completionPercentage = 0;
    if (_progressStats['total'] != null && _progressStats['total']! > 0) {
      completionPercentage = (_progressStats['completed'] ?? 0) / _progressStats['total']! * 100;
    }
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Completion percentage
            Expanded(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: CircularProgressIndicator(
                          value: completionPercentage / 100,
                          strokeWidth: 10,
                          backgroundColor: Colors.grey.shade200,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Column(
                        children: [
                          Text(
                            '${completionPercentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Statistics
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatItem(
                    Icons.directions_run,
                    'Exercises',
                    '${_progressStats['completed'] ?? 0}/${_progressStats['total'] ?? 0}',
                    Colors.green,
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    Icons.calendar_today,
                    'Active Days',
                    '${_progressData.where((day) => (day['completion_rate'] as double) > 0).length}/7',
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  _buildStatItem(
                    Icons.local_fire_department,
                    'Calories Burned',
                    '3,240 kcal',
                    Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressChart() {
    // Order data by date (ascending)
    final orderedData = List<Map<String, dynamic>>.from(_progressData)
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Weekly Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Last 7 Days',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1.7,
              child: _progressData.isEmpty 
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart, 
                          size: 48, 
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No workout data available yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Complete workouts to see your progress',
                          style: TextStyle(
                            color: Colors.grey, 
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildBarChartModern(orderedData),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartModern(List<Map<String, dynamic>> data) {
    // Get only the most recent days if we have more than 7
    final recentData = data.length > 7 
        ? data.sublist(data.length - 7) 
        : data;
        
    return Column(
      children: [
        // Create the bar chart manually with simple widgets
        SizedBox(
          height: 150, // Reduced height container
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(recentData.length, (index) {
              final day = recentData[index];
              final completionRate = day['completion_rate'] as double;
              // Ensure minimum height of 4 pixels even if completion rate is 0
              final height = completionRate > 0 
                  ? 120 * completionRate // Reduced max height
                  : 4;
              
              // Determine bar color based on completion rate
              Color barColor;
              if (completionRate >= 0.8) {
                barColor = Colors.green;
              } else if (completionRate >= 0.5) {
                barColor = Colors.orange;
              } else {
                barColor = Colors.red;
              }
              
              final date = DateTime.parse(day['date'] as String);
              final dayName = DateFormat('E').format(date);
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Completion text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: Text(
                      '${((day['completion_rate'] as double) * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Bar
                  Container(
                    height: height.toDouble(),
                    width: 25, // Reduced width
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: barColor.withOpacity(0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  // Day name
                  Padding(
                    padding: const EdgeInsets.only(top: 2.0),
                    child: Text(
                      dayName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        // Legend
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green, '≥ 80%'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.orange, '≥ 50%'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.red, '< 50%'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
  
  Widget _buildNutritionCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Macronutrients',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Daily Target',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildMacroProgressBar(
              'Protein', 
              0.3, 
              '30%', 
              Colors.red.shade700,
              '150g',
            ),
            const SizedBox(height: 12),
            _buildMacroProgressBar(
              'Carbs', 
              0.5, 
              '50%', 
              Colors.amber.shade700,
              '250g',
            ),
            const SizedBox(height: 12),
            _buildMacroProgressBar(
              'Fats', 
              0.2, 
              '20%', 
              Colors.blue.shade700,
              '45g',
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionInfo('Fiber', '30g', Icons.grass_outlined, Colors.green),
                _buildNutritionInfo('Sugars', '< 50g', Icons.bubble_chart_outlined, Colors.pink),
                _buildNutritionInfo('Sodium', '< 2,300mg', Icons.opacity, Colors.amber),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutritionInfo(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMacroProgressBar(
    String label, 
    double value, 
    String percentage, 
    Color color,
    String grams,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              '$percentage ($grams)',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            color: color,
            backgroundColor: Colors.grey.shade200,
            minHeight: 10,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMealSuggestions() {
    final mealSuggestions = [
      {
        'name': 'Breakfast',
        'time': '7:00 - 8:00 AM',
        'suggestion': 'Oatmeal with berries and yogurt',
        'calories': 350,
        'icon': Icons.wb_sunny_outlined,
      },
      {
        'name': 'Morning Snack',
        'time': '10:00 - 10:30 AM',
        'suggestion': 'Apple with 2 tbsp peanut butter',
        'calories': 200,
        'icon': Icons.apple,
      },
      {
        'name': 'Lunch',
        'time': '12:30 - 1:30 PM',
        'suggestion': 'Grilled chicken salad with vinaigrette',
        'calories': 450,
        'icon': Icons.lunch_dining,
      },
      {
        'name': 'Afternoon Snack',
        'time': '3:30 - 4:00 PM',
        'suggestion': 'Greek yogurt with honey and nuts',
        'calories': 250,
        'icon': Icons.restaurant,
      },
      {
        'name': 'Dinner',
        'time': '7:00 - 8:00 PM',
        'suggestion': 'Baked salmon with quinoa and vegetables',
        'calories': 550,
        'icon': Icons.dinner_dining,
      },
    ];
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: mealSuggestions.map((meal) => _buildMealCard(meal)).toList(),
        ),
      ),
    );
  }
  
  Widget _buildMealCard(Map<String, dynamic> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: meal['name'] != 'Dinner' 
            ? Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              )
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              meal['icon'] as IconData,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      meal['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${meal['calories']} kcal',
                        style: TextStyle(
                          color: Colors.green.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  meal['time'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  meal['suggestion'] as String,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNutritionTipsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lightbulb_outline, 
                    color: Colors.amber.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Nutrition Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem(
              'Stay hydrated: Drink at least 8 glasses of water daily',
              Icons.water_drop_outlined,
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              'Protein helps muscle recovery after workouts',
              Icons.fitness_center_outlined,
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              'Eat complex carbs before exercise for sustained energy',
              Icons.bolt_outlined,
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              'Include a variety of colorful vegetables for essential vitamins',
              Icons.eco_outlined,
            ),
          ],
        ),
      ),
    );
  }

  
  
  Widget _buildTipItem(String tip, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            tip,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomPieChart() {
    final workoutTypes = [
      {'type': 'Cardio', 'percentage': 30, 'color': Colors.redAccent},
      {'type': 'Strength', 'percentage': 40, 'color': Colors.blueAccent},
      {'type': 'Flexibility', 'percentage': 20, 'color': Colors.greenAccent},
      {'type': 'Other', 'percentage': 10, 'color': Colors.purpleAccent},
    ];
    
    return Column(
      children: [
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: PieChartPainter(
              sections: workoutTypes.map((e) => 
                PieSection(
                  value: e['percentage'] as int, 
                  color: e['color'] as Color,
                )
              ).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: workoutTypes.map((type) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: type['color'] as Color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${type['type']}: ${type['percentage']}%',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class PieSection {
  final int value;
  final Color color;
  
  PieSection({required this.value, required this.color});
}

class PieChartPainter extends CustomPainter {
  final List<PieSection> sections;
  
  PieChartPainter({required this.sections});
  
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2.5 : size.height / 2.5;
    final innerRadius = radius * 0.4; // For center hole
    
    // Calculate total value for percentage calculations
    final total = sections.fold(0, (sum, item) => sum + item.value);
    
    // Start drawing from top (negative y-axis direction in canvas)
    double startAngle = -90 * (3.1415927 / 180); // Start from top (-90 degrees in radians)
    
    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      // Convert the section's percentage to radians
      final sweepAngle = (section.value / total) * 2 * 3.1415927;
      
      // Draw the pie section
      final paint = Paint()
        ..color = section.color
        ..style = PaintingStyle.fill;
      
      // Draw outer arc
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      // Draw hole in center (draw white circle on top)
      if (i == sections.length - 1) {
        canvas.drawCircle(
          center,
          innerRadius,
          Paint()..color = Colors.white,
        );
      }
      
      // Calculate position for text (in the middle of the arc)
      final arcCenterAngle = startAngle + sweepAngle / 2;
      final textRadius = radius * 0.7;
      
      final textX = center.dx + textRadius * cos(arcCenterAngle);
      final textY = center.dy + textRadius * sin(arcCenterAngle);
      
      // Draw text
      final percentage = ((section.value / total) * 100).round();
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$percentage%',
          style: TextStyle(
            color: percentage < 25 ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas, 
        Offset(textX - textPainter.width / 2, textY - textPainter.height / 2),
      );
      
      // Update start angle for next section
      startAngle += sweepAngle;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 