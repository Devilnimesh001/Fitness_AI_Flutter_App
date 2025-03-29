import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Use only the Render hosted URL
  final String baseUrl = 'https://fitnessfreaks-2oar.onrender.com';
  
  // Constructor - initialize and print URL
  ApiService() {
    print('ApiService initialized with URL: $baseUrl');
  }
  
  // Increased timeout for slower connections on Render free tier
  final Duration timeout = const Duration(seconds: 120); // Increased from 90 to 120 seconds
  
  // Maximum number of retries
  final int maxRetries = 5; // Increased from 2 to 5 retries
  
  Future<Map<String, dynamic>> generateWorkoutPlan(
    Map<String, dynamic> userProfile,
    String startDate,
    int planDurationDays
  ) async {
    print('\n======= GENERATING WORKOUT PLAN =======');
    print('User profile: $userProfile');
    print('Start date: $startDate');
    print('Duration: $planDurationDays days');
    print('Using server URL: $baseUrl');
    
    // Try to prepare the server (load model if needed)
    bool serverReady = await _prepareServer();
    if (!serverReady) {
      print('Server not ready (model not loaded), using mock data');
      return _getMockWorkoutPlan(userProfile, startDate, planDurationDays);
    }
    
    int retryCount = 0;
    Exception? lastException;
    
    while (retryCount < maxRetries) {
      try {
        // Build the request URI
        final Uri uri = Uri.parse('$baseUrl/generate_plan');
        
        // Transform the user profile to match the API's expected format
        final Map<String, dynamic> apiUserProfile = {
          'Age': userProfile['age'],
          'Gender': userProfile['gender'],
          'Weight (kg)': userProfile['weight'],
          'Height (m)': userProfile['height'],
          'Workout_Frequency (days/week)': userProfile['workout_frequency'],
          'Fitness_Level': userProfile['fitness_level'],
          'BMI': userProfile['bmi'] ?? (userProfile['weight'] / (userProfile['height'] * userProfile['height'])),
        };
        
        // Create request exactly like the working test.json format
        final Map<String, dynamic> requestMap = {
          'user_profile': apiUserProfile,
          'start_date': startDate,
          'plan_duration_days': planDurationDays
        };
        
        // Create and log the JSON request
        final String jsonString = jsonEncode(requestMap);
        print('REQUEST [${retryCount + 1}/$maxRetries]: POST $uri');
        print('REQUEST BODY: $jsonString');
        
        // Send the request with appropriate timeout
        final stopwatch = Stopwatch()..start();
        final response = await http.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonString,
        ).timeout(timeout);
        stopwatch.stop();
        
        // Log the response
        print('RESPONSE TIME: ${stopwatch.elapsedMilliseconds}ms');
        print('RESPONSE STATUS: ${response.statusCode}');
        if (response.body.isNotEmpty) {
          if (response.body.length > 300) {
            print('RESPONSE BODY (truncated): ${response.body.substring(0, 300)}...');
          } else {
            print('RESPONSE BODY: ${response.body}');
          }
        } else {
          print('RESPONSE BODY: <empty>');
        }
        
        // Check for model not loaded error
        if (response.statusCode == 500 && response.body.contains("Model or exercise data not loaded")) {
          print('ERROR: Model not loaded on server');
          if (retryCount == maxRetries - 1) {
            // If this is our last retry and model still not loaded, use mock data
            return _getMockWorkoutPlan(userProfile, startDate, planDurationDays);
          }
          // Try to trigger model loading and wait
          await _triggerModelLoading();
          await _retryDelay(retryCount);
          retryCount++;
          continue;
        }
        
        // Process successful responses
        if (response.statusCode == 200) {
          try {
            // Fix NaN values in JSON which cause parsing errors
            String cleanedResponse = _cleanJsonResponse(response.body);
            final Map<String, dynamic> result = jsonDecode(cleanedResponse);
            print('SUCCESS: API returned workout plan');
            return result;
          } catch (e) {
            print('ERROR: Failed to parse successful response: $e');
            if (retryCount == maxRetries - 1) {
              // If this is our last retry and parsing still fails, use mock data
              print('Falling back to mock data due to parsing error');
              return _getMockWorkoutPlan(userProfile, startDate, planDurationDays);
            }
            throw FormatException('Invalid response format: $e');
          }
        } else {
          // Handle error responses
          String errorMessage = 'Server error (${response.statusCode})';
          try {
            if (response.body.isNotEmpty) {
              final errorBody = jsonDecode(response.body);
              if (errorBody.containsKey('error')) {
                errorMessage = errorBody['error'];
              } else if (errorBody.containsKey('message')) {
                errorMessage = errorBody['message'];
              }
            }
          } catch (_) {
            if (response.body.isNotEmpty) {
              errorMessage = response.body;
            }
          }
          
          print('ERROR: $errorMessage');
          throw Exception(errorMessage);
        }
      } on SocketException catch (e) {
        print('ERROR: Socket Exception - ${e.message}');
        print('ERROR: Could not connect to $baseUrl');
        lastException = Exception('Connection failed: Could not connect to the server.');
        await _retryDelay(retryCount);
      } on http.ClientException catch (e) {
        print('ERROR: HTTP Client Exception - ${e.message}');
        lastException = Exception('Network error: ${e.message}');
        await _retryDelay(retryCount);
      } on FormatException catch (e) {
        print('ERROR: Format Exception - ${e.message}');
        lastException = Exception('Invalid response format');
        
        // If this is a NaN error in JSON, try again
        if (e.toString().contains('NaN') && retryCount < maxRetries - 1) {
          print('Retrying due to NaN error in JSON');
          await _retryDelay(retryCount);
          retryCount++;
          continue;
        }
        
        break; // Don't retry other format exceptions
      } on TimeoutException catch (_) {
        print('ERROR: Request timed out after ${timeout.inSeconds} seconds');
        lastException = Exception('Request timed out');
        await _retryDelay(retryCount);
      } on Exception catch (e) {
        print('ERROR: General Exception - $e');
        lastException = Exception('Failed to generate workout plan: $e');
        await _retryDelay(retryCount);
      }
      
      retryCount++;
    }
    
    // If we get here, all retries failed, use mock data as fallback
    print('FALLBACK: Using mock data after ${maxRetries} failed attempts');
    return _getMockWorkoutPlan(userProfile, startDate, planDurationDays);
  }
  
  // Fix JSON response with NaN values
  String _cleanJsonResponse(String jsonStr) {
    // Replace literal NaN values with null
    String cleaned = jsonStr.replaceAll(': NaN', ': null');
    
    // Log the cleaning
    if (jsonStr != cleaned) {
      print('Fixed invalid JSON: Replaced NaN values with null');
    }
    
    return cleaned;
  }
  
  // Try to prepare the server by checking model loading status
  Future<bool> _prepareServer() async {
    print('Checking if model is loaded on server...');
    
    // Try multiple times to see if the model loads
    for (int i = 0; i < 5; i++) { // Increased from 3 to 5 attempts
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/health'),
        ).timeout(const Duration(seconds: 15)); // Increased from 5 to 15 seconds
        
        if (response.statusCode == 200) {
          // Parse the response
          try {
            final Map<String, dynamic> healthData = jsonDecode(response.body);
            
            // Check model loaded status
            if (healthData.containsKey('model_loaded') && healthData['model_loaded'] == true) {
              print('Server ready: Model is loaded');
              return true;
            } else {
              print('Server up but model not loaded yet (attempt ${i+1}/5)');
              
              // Try to trigger model loading
              await _triggerModelLoading();
              
              // Wait longer before checking again
              await Future.delayed(const Duration(seconds: 15)); // Increased from 10 to 15 seconds
            }
          } catch (e) {
            print('Error parsing health data: $e');
          }
        } else {
          print('Health check failed with status ${response.statusCode}');
          await Future.delayed(const Duration(seconds: 10)); // Increased from 5 to 10 seconds
        }
      } catch (e) {
        print('Error checking server health: $e');
        await Future.delayed(const Duration(seconds: 10)); // Increased from 5 to 10 seconds
      }
    }
    
    // If we get here, model is still not loaded
    print('Model still not loaded after multiple attempts');
    return false;
  }
  
  // Try to trigger model loading on the server
  Future<void> _triggerModelLoading() async {
    print('Attempting to trigger model loading...');
    
    try {
      // Send a small test request to trigger model loading
      final response = await http.post(
        Uri.parse('$baseUrl/generate_plan'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_profile': {
            'Age': 30,
            'Gender': 'Male',
            'Weight (kg)': 70,
            'Height (m)': 1.75,
            'Workout_Frequency (days/week)': 3,
            'Fitness_Level': 'Beginner'
          },
          'start_date': DateTime.now().toString().substring(0, 10),
          'plan_duration_days': 1
        }),
      ).timeout(const Duration(seconds: 30)); // Increased from 20 to 30 seconds
      
      print('Model loading trigger attempt resulted in status: ${response.statusCode}');
    } catch (e) {
      print('Error triggering model load: $e');
    }
  }
  
  // Check if the server is reachable
  Future<bool> _isServerReachable() async {
    try {
      // Try simple GET request
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 20)); // Increased from 10 to 20 seconds
      
      print('$baseUrl response: ${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 500;
    } catch (e) {
      print('$baseUrl is not reachable: $e');
      return false;
    }
  }
  
  // Exponential backoff for retries
  Future<void> _retryDelay(int retryCount) async {
    final delayMs = 5000 * (retryCount + 1); // 5s, 10s, 15s, etc. - longer for model loading
    print('Retrying in ${delayMs}ms...');
    await Future.delayed(Duration(milliseconds: delayMs));
  }
  
  // Generate a mock workout plan as fallback - using the same format as the API response
  Map<String, dynamic> _getMockWorkoutPlan(
    Map<String, dynamic> userProfile,
    String startDate, 
    int planDurationDays
  ) {
    print('Generating mock workout plan...');
    final fitnessLevel = userProfile['Fitness_Level'] ?? 'Beginner';
    
    // Create a simple workout plan based on user profile
    Map<String, List<Map<String, dynamic>>> workoutPlanData = {};
    
    // Parse the start date
    DateTime currentDate = DateTime.parse(startDate);
    
    for (int i = 0; i < planDurationDays; i++) {
      final dateStr = "${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
      
      // Create exercises for this day
      List<Map<String, dynamic>> exercises = [
        {
          "name": "Jumping Jacks",
          "sets": 3,
          "reps": 30,
          "target_muscle_group": "Full Body",
          "workout_type": "Cardio",
          "difficulty_level": fitnessLevel,
          "benefit": "Improves coordination and cardiovascular health",
          "equipment_needed": null
        },
        {
          "name": "Push-ups",
          "sets": fitnessLevel == 'Beginner' ? 3 : 4,
          "reps": fitnessLevel == 'Beginner' ? 8 : 12,
          "target_muscle_group": "Chest, Triceps, Shoulders",
          "workout_type": "Strength",
          "difficulty_level": fitnessLevel,
          "benefit": "Builds upper body strength",
          "equipment_needed": null
        },
        {
          "name": "Squats",
          "sets": 3,
          "reps": 15,
          "target_muscle_group": "Quadriceps, Hamstrings, Glutes",
          "workout_type": "Strength",
          "difficulty_level": fitnessLevel,
          "benefit": "Builds lower body strength",
          "equipment_needed": null
        },
        {
          "name": "Plank",
          "sets": 3,
          "reps": null,
          "duration_seconds": 30,
          "target_muscle_group": "Core, Shoulders",
          "workout_type": "Strength",
          "difficulty_level": fitnessLevel,
          "benefit": "Improves core stability",
          "equipment_needed": null
        }
      ];
      
      workoutPlanData[dateStr] = exercises;
      currentDate = currentDate.add(const Duration(days: 1));
    }
    
    print('Mock workout plan generated for ${planDurationDays} days');
    
    // Mock data structure that matches the API's response format
    return {
      "status": "success",
      "workout_plan": workoutPlanData,
      "workout_type": "Mixed"
    };
  }
  
  // Helper function for min value
  int min(int a, int b) {
    return a < b ? a : b;
  }
} 