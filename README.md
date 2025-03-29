# Workout Scheduler ML Model

This project contains a machine learning model for scheduling personalized multi-day workout plans based on user data. It's designed to be integrated with a Flutter app that collects user input, uses the ML model to generate workout plans, and displays the schedule with reminders via local push notifications.

## Components

1. **ML Model**: A RandomForest classifier that recommends workout types based on user characteristics.
2. **Workout Scheduler**: Generates personalized multi-day workout plans.
3. **Flask API**: Provides endpoints for the Flutter app to interact with the ML model.

## Getting Started

### Prerequisites

- Python 3.8 or higher
- pip (Python package manager)

### Installation

1. Clone the repository:
```
git clone <repository-url>
cd <repository-directory>
```

2. Install the required dependencies:
```
pip install -r requirements.txt
```

3. Train the model (if not already trained):
```
python workout_scheduler_model.py
```

4. Start the Flask API:
```
python app.py
```

The API will be available at http://localhost:5000.

## API Endpoints

### 1. Health Check

- **URL**: `/health`
- **Method**: `GET`
- **Description**: Check if the API is running.
- **Response**: `{"status": "healthy"}`

### 2. Generate Workout Plan

- **URL**: `/generate_plan`
- **Method**: `POST`
- **Description**: Generate a personalized workout plan based on user profile.
- **Request Body**:
  ```json
  {
    "user_profile": {
      "Age": 30,
      "Gender": "Male",
      "Weight (kg)": 75,
      "Height (m)": 1.75,
      "Max_BPM": 185,
      "Avg_BPM": 140,
      "Resting_BPM": 65,
      "Session_Duration (hours)": 1.2,
      "Calories_Burned": 800,
      "Fat_Percentage": 20,
      "Water_Intake (liters)": 2.5,
      "Workout_Frequency (days/week)": 4,
      "Fitness_Level": "Intermediate",
      "BMI": 24.5
    },
    "start_date": "2023-05-15",
    "plan_duration_days": 7
  }
  ```
- **Response**: JSON containing the workout plan with dates as keys and exercises as values.

### 3. Adjust Workout Plan

- **URL**: `/adjust_plan`
- **Method**: `POST`
- **Description**: Adjust a workout plan based on user feedback.
- **Request Body**:
  ```json
  {
    "workout_plan": {
      "2023-05-15": [
        {
          "name": "Push-ups",
          "sets": 3,
          "reps": 15,
          "benefit": "Builds upper body strength",
          "target_muscle_group": "Chest, Triceps, Shoulders",
          "equipment_needed": "None",
          "difficulty_level": "Intermediate",
          "workout_type": "Strength"
        }
      ]
    },
    "user_feedback": {
      "difficulty": 4,
      "enjoyment": 3
    }
  }
  ```
- **Response**: JSON containing the adjusted workout plan.

## Flutter App Integration

To integrate this model with your Flutter app:

1. Make HTTP requests to the API endpoints from your Flutter app.
2. Display the workout plans in your app's UI.
3. Implement local push notifications to remind users of their scheduled workouts.

## Example Flutter API Service

Here's a starting point for creating an API service in your Flutter app:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class WorkoutApiService {
  final String baseUrl = 'http://your-api-url:5000';
  
  Future<Map<String, dynamic>> generateWorkoutPlan(Map<String, dynamic> userProfile, 
                                                 String startDate, 
                                                 int planDurationDays) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate_plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_profile': userProfile,
        'start_date': startDate,
        'plan_duration_days': planDurationDays
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate workout plan');
    }
  }
  
  Future<Map<String, dynamic>> adjustWorkoutPlan(Map<String, dynamic> workoutPlan, 
                                               Map<String, dynamic> userFeedback) async {
    final response = await http.post(
      Uri.parse('$baseUrl/adjust_plan'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'workout_plan': workoutPlan,
        'user_feedback': userFeedback
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to adjust workout plan');
    }
  }
}
```

## Next Steps for Flutter App Development

1. Create user input forms to collect user data
2. Implement API calls to the workout scheduler model
3. Design UI to display the workout plans
4. Implement local notifications for workout reminders
5. Add feedback mechanisms for users to adjust their plans

## License

This project is licensed under the MIT License - see the LICENSE file for details. 