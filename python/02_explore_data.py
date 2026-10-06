import pandas as pd
import os


# ============================================================
# 1. PROJECT PATH
# ============================================================

BASE_DIR = os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))
)

DATA_FILE = os.path.join(
    BASE_DIR,
    "data",
    "master_songs.csv"
)


# ============================================================
# 2. LOAD DATA
# ============================================================

print("==========================================")
print("MUSIC RECOMMENDATION SYSTEM")
print("EXPLORATORY DATA ANALYSIS")
print("==========================================")

df = pd.read_csv(DATA_FILE)

print("\nDataset loaded successfully.")

print("Number of songs:", len(df))
print("Number of columns:", len(df.columns))


# ============================================================
# 3. DATASET INFORMATION
# ============================================================

print("\n==========================================")
print("DATASET INFORMATION")
print("==========================================")

print(df.info())


# ============================================================
# 4. LANGUAGE ANALYSIS
# ============================================================

print("\n==========================================")
print("SONGS BY LANGUAGE")
print("==========================================")

language_count = df["language"].value_counts()

print(language_count)


# ============================================================
# 5. ARTIST ANALYSIS
# ============================================================

print("\n==========================================")
print("TOP 20 ARTISTS")
print("==========================================")

top_artists = df["artist"].value_counts().head(20)

print(top_artists)


# ============================================================
# 6. POPULAR SONGS
# ============================================================

print("\n==========================================")
print("TOP 20 POPULAR SONGS")
print("==========================================")

popular_songs = (
    df[
        [
            "title",
            "artist",
            "language",
            "popularity"
        ]
    ]
    .sort_values(
        "popularity",
        ascending=False
    )
    .head(20)
)

print(popular_songs.to_string(index=False))


# ============================================================
# 7. AUDIO FEATURE ANALYSIS
# ============================================================

audio_features = [
    "energy",
    "danceability",
    "valence",
    "acousticness",
    "instrumentalness",
    "speechiness",
    "tempo",
    "loudness"
]

print("\n==========================================")
print("AUDIO FEATURE STATISTICS")
print("==========================================")

print(
    df[audio_features].describe()
)


# ============================================================
# 8. MISSING VALUES
# ============================================================

print("\n==========================================")
print("MISSING VALUES")
print("==========================================")

missing_values = df.isnull().sum()

print(
    missing_values[
        missing_values > 0
    ]
)


# ============================================================
# 9. DUPLICATE ANALYSIS
# ============================================================

print("\n==========================================")
print("DUPLICATE ANALYSIS")
print("==========================================")

duplicates = df.duplicated().sum()

print(
    "Duplicate rows:",
    duplicates
)


# ============================================================
# 10. LANGUAGE SUMMARY
# ============================================================

print("\n==========================================")
print("LANGUAGE SUMMARY")
print("==========================================")

language_summary = (
    df.groupby("language")
    .agg(
        songs=("title", "count"),
        average_popularity=("popularity", "mean"),
        average_energy=("energy", "mean"),
        average_danceability=("danceability", "mean"),
        average_valence=("valence", "mean")
    )
    .sort_values(
        "songs",
        ascending=False
    )
)

print(
    language_summary.round(2)
)


# ============================================================
# 11. SAVE ANALYSIS
# ============================================================

OUTPUT_DIR = os.path.join(
    BASE_DIR,
    "outputs"
)

os.makedirs(
    OUTPUT_DIR,
    exist_ok=True
)

language_summary.to_csv(
    os.path.join(
        OUTPUT_DIR,
        "language_analysis.csv"
    )
)


print("\n==========================================")
print("EXPLORATION COMPLETED")
print("==========================================")

print(
    "\nAnalysis saved to:"
)

print(
    os.path.join(
        OUTPUT_DIR,
        "language_analysis.csv"
    )
)