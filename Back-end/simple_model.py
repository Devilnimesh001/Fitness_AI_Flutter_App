import pandas as pd
import numpy as np
import pickle
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

def train_simple_model():
    print("Loading data...")
    # Load datasets
    user_data = pd.read_csv('gym_members_exercise_tracking.csv')
    exercise_data = pd.read_csv('Top 50 Excerice for your body.csv')
    
    print("Preprocessing data...")
    # Define features
    numeric_features = ['Age', 'Weight (kg)', 'Height (m)', 'BMI']
    categorical_features = ['Gender', 'Fitness_Level'] 
    
    # Create a clean copy of the data
    user_data_clean = user_data.copy()
    
    # Clean numeric data
    for col in numeric_features:
        if col in user_data_clean.columns:
            user_data_clean[col] = pd.to_numeric(user_data_clean[col], errors='coerce')
            user_data_clean[col].fillna(user_data_clean[col].median(), inplace=True)
    
    # Get existing columns
    numeric_cols = [col for col in numeric_features if col in user_data_clean.columns]
    cat_cols = [col for col in categorical_features if col in user_data_clean.columns]
    
    # Create column transformer
    preprocessor = ColumnTransformer(
        transformers=[
            ('num', StandardScaler(), numeric_cols),
            ('cat', OneHotEncoder(handle_unknown='ignore'), cat_cols)
        ])
    
    # Create a simple pipeline
    pipeline = Pipeline([
        ('preprocessor', preprocessor),
        ('classifier', RandomForestClassifier(n_estimators=100, random_state=42))
    ])
    
    # Prepare data for model
    X_columns = numeric_cols + cat_cols
    X = user_data_clean[X_columns]
    y = user_data_clean['Workout_Type']
    
    # Split data
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    print("Training model...")
    # Train the model
    pipeline.fit(X_train, y_train)
    
    # Evaluate model
    train_score = pipeline.score(X_train, y_train)
    test_score = pipeline.score(X_test, y_test)
    
    print(f"Training score: {train_score:.4f}")
    print(f"Test score: {test_score:.4f}")
    
    # Save the model
    with open('simple_workout_model.pkl', 'wb') as f:
        pickle.dump(pipeline, f)
    
    print("Model saved to simple_workout_model.pkl")
    
    # Test prediction
    print("\nTesting prediction with first sample...")
    sample = X_test.iloc[0:1]
    prediction = pipeline.predict(sample)[0]
    print(f"Predicted workout type: {prediction}")
    
    return pipeline

if __name__ == "__main__":
    train_simple_model() 