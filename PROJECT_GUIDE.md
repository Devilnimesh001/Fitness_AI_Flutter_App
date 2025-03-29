# Workout Scheduler Project Guide

This document provides a comprehensive overview of your workout scheduler project, including both the machine learning backend and the Flutter mobile app integration.

## Project Overview

The Workout Scheduler is a personalized workout planning system that:

1. Uses machine learning to analyze user data and recommend appropriate workout types
2. Generates multi-day workout plans based on the user's fitness level and preferences
3. Delivers these plans through a Flutter mobile app with reminder notifications

## Components

### 1. Machine Learning Backend

The ML backend consists of the following components:

- **Data Processing**: Preprocessing of user data for model training
- **ML Model**: A RandomForest classifier that predicts suitable workout types
- **Workout Scheduler**: Generates personalized workout plans based on model predictions
- **Flask API**: REST API endpoints that allow the Flutter app to interact with the ML model

### 2. Flutter Mobile App

The mobile app provides:

- **User Profile Management**: Collection and storage of user fitness data
- **Workout Plan Display**: Calendar-based visualization of workout schedules
- **Notifications**: Reminders for scheduled workouts
- **Feedback System**: Collection of user feedback to improve future plans

## Current Implementation Status

### Completed

- ✅ Machine learning model for workout type prediction
- ✅ Workout plan generation algorithm
- ✅ Flask API for model interaction
- ✅ Basic project structure and code templates for Flutter

### Next Steps

1. **Backend Deployment**:
   - Set up the Flask app on a cloud provider (AWS, Google Cloud, or Heroku)
   - Configure proper security and scalability settings

2. **Flutter App Development**:
   - Complete the implementation of all screens and widgets
   - Implement data persistence for user profiles
   - Integrate with the deployed API

3. **Testing and Refinement**:
   - Test the ML model with different user profiles
   - Gather feedback on workout plans
   - Refine the model based on feedback

## Implementation Instructions

### Setting Up the Backend

1. **Install the required Python dependencies**:

```bash
pip install -r requirements.txt
```

2. **Train the model** (if not already trained):

```bash
python workout_scheduler_model.py
```

3. **Start the Flask API**:

```bash
python app.py
```

4. **Test the API**:

```bash
python test_model.py
```

### Setting Up the Flutter App

1. **Create a new Flutter project**:

```bash
flutter create workout_scheduler_app
cd workout_scheduler_app
```

2. **Update the pubspec.yaml file** with the required dependencies as specified in the Flutter app guide.

3. **Implement the data models, services, and screens** as provided in the Flutter app guide.

4. **Configure the API endpoint** in `lib/services/api_service.dart` to point to your deployed backend.

5. **Test the app**:

```bash
flutter run
```

## API Documentation

### 1. Generate Workout Plan

- **Endpoint**: `/generate_plan`
- **Method**: `POST`
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
- **Response**: A workout plan with dates as keys and exercises as values.

### 2. Adjust Workout Plan

- **Endpoint**: `/adjust_plan`
- **Method**: `POST`
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
- **Response**: An adjusted workout plan based on user feedback.

## Enhancing the Model

To improve the ML model:

1. **Collect more data**: Gather more user data and workout outcomes to train the model with.
2. **Feature engineering**: Create new features that might better predict workout suitability.
3. **Experiment with different algorithms**: Try different ML algorithms (XGBoost, Neural Networks) to see if they provide better performance.
4. **Hyperparameter tuning**: Further optimize the model's hyperparameters.
5. **User feedback integration**: Incorporate user feedback into the training process.

## Deployment Considerations

### Backend Deployment

- **Server Requirements**: Python 3.8+, 2GB RAM minimum
- **Scaling**: Implement load balancing for high traffic
- **Security**: Use HTTPS, implement rate limiting and authentication
- **Monitoring**: Set up logging and performance monitoring

### App Deployment

- **Platform-specific considerations**: Test on both iOS and Android
- **Performance optimization**: Minimize API calls, implement caching
- **Error handling**: Add comprehensive error handling throughout the app
- **Analytics**: Consider adding analytics to track user engagement

## Conclusion

This project combines machine learning with mobile app development to create a personalized workout scheduling system. By following the implementation instructions and considering the enhancement suggestions, you can create a robust and user-friendly workout planning application.

If you need further assistance or have questions about specific components, refer to the code comments and documentation within each file. 