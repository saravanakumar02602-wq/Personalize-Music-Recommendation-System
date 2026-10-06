import pandas as pd
import numpy as np
import os
import joblib

from sklearn.preprocessing import StandardScaler


# ============================================================
# 1. PROJECT PATHS
# ============================================================

BASE_DIR = os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))
)

DATA_FILE = os.path.join(
    BASE_DIR,
    "data",
    "master_songs.csv"
)

MODEL_DIR = os.path.join(
    BASE_DIR,
    "models"
)

os.makedirs(
    MODEL_DIR,
    exist_ok=True
)


# ============================================================
# 2. LOAD MASTER DATASET
# ============================================================

print("==========================================")
print("STEP 3 - DATA PREPROCESSING")
print("==========================================")

print("\nLoading master dataset...")

df = pd.read_csv(DATA_FILE)

print("Total songs:", len(df))


# ============================================================
# 3. SELECT MUSIC FEATURES
# ============================================================

features = [
    "energy",
    "danceability",
    "valence",
    "acousticness",
    "instrumentalness",
    "speechiness",
    "tempo",
    "loudness"
]

print("\nFeatures used for recommendation:")

for feature in features:
    print(" -", feature)


# ============================================================
# 4. CHECK MISSING VALUES
# ============================================================

print("\nChecking missing values...")

print(
    df[features].isnull().sum()
)


# ============================================================
# 5. CONVERT FEATURES TO NUMERIC
# ============================================================

print("\nConverting features to numeric...")

for feature in features:

    df[feature] = pd.to_numeric(
        df[feature],
        errors="coerce"
    )


# ============================================================
# 6. FILL MISSING VALUES
# ============================================================

print("\nHandling missing values...")

for feature in features:

    median_value = df[feature].median()

    df[feature] = df[feature].fillna(
        median_value
    )


print("Missing values handled.")


# ============================================================
# 7. CREATE FEATURE MATRIX
# ============================================================

print("\nCreating feature matrix...")

feature_matrix = df[features].values

print(
    "Feature matrix shape:",
    feature_matrix.shape
)


# ============================================================
# 8. STANDARDIZE FEATURES
# ============================================================

print("\nScaling music features...")

scaler = StandardScaler()

scaled_features = scaler.fit_transform(
    feature_matrix
)


print(
    "Scaled feature matrix shape:",
    scaled_features.shape
)


# ============================================================
# 9. SAVE SCALER
# ============================================================

scaler_file = os.path.join(
    MODEL_DIR,
    "feature_scaler.pkl"
)

joblib.dump(
    scaler,
    scaler_file
)

print(
    "\nScaler saved:"
)

print(scaler_file)


# ============================================================
# 10. SAVE FEATURE MATRIX
# ============================================================

feature_file = os.path.join(
    MODEL_DIR,
    "feature_matrix.pkl"
)

joblib.dump(
    scaled_features,
    feature_file
)

print(
    "\nFeature matrix saved:"
)

print(feature_file)


# ============================================================
# 11. SAVE SONG INFORMATION
# ============================================================

song_info = df[
    [
        "song_id",
        "title",
        "artist",
        "language"
    ]
].copy()

song_info_file = os.path.join(
    MODEL_DIR,
    "song_info.pkl"
)

joblib.dump(
    song_info,
    song_info_file
)

print(
    "\nSong information saved:"
)

print(song_info_file)


# ============================================================
# 12. FINAL OUTPUT
# ============================================================

print("\n==========================================")
print("PREPROCESSING COMPLETED")
print("==========================================")

print(
    "\nSongs processed:",
    len(df)
)

print(
    "Features processed:",
    len(features)
)

print(
    "Feature matrix:",
    scaled_features.shape
)

print("\nFiles created:")

print("1. feature_scaler.pkl")
print("2. feature_matrix.pkl")
print("3. song_info.pkl")

print("\nReady for Step 4.")