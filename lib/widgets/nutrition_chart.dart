import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class NutritionPieChart extends StatelessWidget {
  final Map<String, double> nutritionData;

  const NutritionPieChart({
    Key? key,
    required this.nutritionData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Define the nutrition map with specific colors
    final nutritionColors = {
      'proteins': Colors.redAccent,
      'carbs': Colors.blueAccent,
      'fats': Colors.yellowAccent,
    };

    // Calculate total calories
    final totalNutrition = nutritionData.values.fold(0.0, (sum, value) => sum + value);

    // Create pie chart sections
    final sections = nutritionData.entries.map((entry) {
      final percent = totalNutrition > 0 ? (entry.value / totalNutrition) * 100 : 0.0;
      final color = nutritionColors[entry.key.toLowerCase()] ?? Colors.grey;
      
      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percent.toStringAsFixed(1)}%',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 30,
          startDegreeOffset: 180,
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
} 