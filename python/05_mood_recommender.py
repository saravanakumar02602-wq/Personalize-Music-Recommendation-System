import pandas as pd
import numpy as np
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

OUTPUT_DIR = os.path.join(
    BASE_DIR,
    "outputs"
)

os.makedirs(OUTPUT_DIR, exist_ok=True)


# ============================================================
# 2. LOAD DATA
# ============================================================

print("==========================================")
print("MOOD + LANGUAGE MUSIC RECOMMENDER")
print("==========================================")

df = pd.read_csv(DATA_FILE)

print("\nSongs loaded:", len(df))


# ============================================================
# 3. PREPARE MOOD FEATURES
# ============================================================

features = [
    "energy",
    "danceability",
    "valence"
]

for feature in features:

    df[feature] = pd.to_numeric(
        df[feature],
        errors="coerce"
    )

    df[feature] = df[feature].fillna(
        df[feature].median()
    )


# ============================================================
# 4. CLEAN LANGUAGE COLUMN
# ============================================================

df["language"] = (
    df["language"]
    .astype(str)
    .str.strip()
)


# ============================================================
# 5. MOOD PROFILES
# ============================================================

MOOD_PROFILES = {

    "happy": {
        "energy": 0.75,
        "danceability": 0.75,
        "valence": 0.85
    },

    "sad": {
        "energy": 0.30,
        "danceability": 0.35,
        "valence": 0.25
    },

    "relaxed": {
        "energy": 0.35,
        "danceability": 0.40,
        "valence": 0.55
    },

    "energetic": {
        "energy": 0.90,
        "danceability": 0.85,
        "valence": 0.75
    },

    "romantic": {
        "energy": 0.45,
        "danceability": 0.50,
        "valence": 0.65
    }
}


# ============================================================
# 6. LANGUAGE OPTIONS
# ============================================================

LANGUAGES = {
    "1": "All",
    "2": "Tamil",
    "3": "English",
    "4": "Hindi",
    "5": "Telugu",
    "6": "Malayalam",
    "7": "Korean",
    "8": "Bengali"
}


# ============================================================
# 7. DISPLAY MOODS
# ============================================================

print("\nAvailable moods:")

print("1. Happy")
print("2. Sad")
print("3. Relaxed")
print("4. Energetic")
print("5. Romantic")


# ============================================================
# 8. GET MOOD FROM USER
# ============================================================

mood = input(
    "\nEnter your mood: "
).lower().strip()


# ============================================================
# 9. CHECK MOOD
# ============================================================

if mood not in MOOD_PROFILES:

    print("\nInvalid mood.")

    print(
        "Please enter: "
        "happy, sad, relaxed, energetic or romantic"
    )

    exit()


print("\nSelected mood:", mood)


# ============================================================
# 10. DISPLAY LANGUAGE OPTIONS
# ============================================================

print("\nEnter language:")

for number, language in LANGUAGES.items():

    print(f"{number}. {language}")


# ============================================================
# 11. GET LANGUAGE SELECTION
# ============================================================

language_choice = input(
    "\nEnter language number: "
).strip()


# ============================================================
# 12. CHECK LANGUAGE SELECTION
# ============================================================

if language_choice not in LANGUAGES:

    print("\nInvalid language selection.")

    print(
        "Please enter a number from 1 to 8."
    )

    exit()


selected_language = LANGUAGES[language_choice]


print(
    "\nSelected language:",
    selected_language
)


# ============================================================
# 13. FILTER SONGS BY LANGUAGE
# ============================================================

if selected_language != "All":

    filtered_df = df[
        df["language"].str.lower()
        ==
        selected_language.lower()
    ].copy()

else:

    filtered_df = df.copy()


# ============================================================
# 14. CHECK WHETHER SONGS ARE AVAILABLE
# ============================================================

if len(filtered_df) == 0:

    print(
        "\nNo songs found for:",
        selected_language
    )

    print(
        "\nTry selecting another language."
    )

    exit()


print(
    "\nSongs available for recommendation:",
    len(filtered_df)
)


# ============================================================
# 15. GET MOOD PROFILE
# ============================================================

target = MOOD_PROFILES[mood]


print("\nMood profile:")

print(
    "Energy:",
    target["energy"]
)

print(
    "Danceability:",
    target["danceability"]
)

print(
    "Valence:",
    target["valence"]
)


# ============================================================
# 16. CREATE TARGET MOOD VECTOR
# ============================================================

mood_vector = np.array([
    target["energy"],
    target["danceability"],
    target["valence"]
])


# ============================================================
# 17. CREATE SONG FEATURE MATRIX
# ============================================================

song_vectors = filtered_df[
    features
].to_numpy(dtype=float)


# ============================================================
# 18. CALCULATE DISTANCE
# ============================================================

distances = np.linalg.norm(
    song_vectors - mood_vector,
    axis=1
)


filtered_df["mood_distance"] = distances


# ============================================================
# 19. CALCULATE MOOD MATCH SCORE
# ============================================================

filtered_df["mood_score"] = (

    1 /
    (
        1 +
        filtered_df["mood_distance"]
    )

) * 100


# ============================================================
# 20. SORT RECOMMENDATIONS
# ============================================================

recommendations = (
    filtered_df
    .sort_values(
        "mood_score",
        ascending=False
    )
    .head(10)
)


# ============================================================
# 21. DISPLAY RECOMMENDATIONS
# ============================================================

print("\n==========================================")
print("MOOD BASED RECOMMENDATIONS")
print("==========================================")

print(
    "\nMood:",
    mood.upper()
)

print(
    "Language:",
    selected_language.upper()
)

print()


for number, (_, row) in enumerate(
    recommendations.iterrows(),
    start=1
):

    print(
        f"{number}. "
        f"{row['title']} - "
        f"{row['artist']} "
        f"({row['language']}) "
        f"-> "
        f"{row['mood_score']:.2f}% mood match"
    )


# ============================================================
# 22. SAVE RECOMMENDATIONS
# ============================================================

output_file = os.path.join(
    OUTPUT_DIR,
    "mood_recommendations.csv"
)


recommendations[
    [
        "title",
        "artist",
        "language",
        "energy",
        "danceability",
        "valence",
        "mood_score"
    ]
].to_csv(
    output_file,
    index=False
)


# ============================================================
# 23. FINAL MESSAGE
# ============================================================

print("\n==========================================")
print("RECOMMENDATION COMPLETED")
print("==========================================")

print(
    "\nResults saved to:"
)

print(output_file)