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

HYBRID_FILE = os.path.join(
    BASE_DIR,
    "outputs",
    "hybrid_recommendations.csv"
)

OUTPUT_DIR = os.path.join(
    BASE_DIR,
    "outputs"
)

os.makedirs(
    OUTPUT_DIR,
    exist_ok=True
)


# ============================================================
# 2. LOAD DATA
# ============================================================

print("==========================================")
print("STEP 8 - EXPLAINABLE RECOMMENDATION")
print("==========================================")

songs = pd.read_csv(DATA_FILE)

recommendations = pd.read_csv(
    HYBRID_FILE
)


# ============================================================
# 3. GET USER INFORMATION
# ============================================================

print("\nAvailable moods:")

print("1. Happy")
print("2. Sad")
print("3. Relaxed")
print("4. Energetic")
print("5. Romantic")


mood = input(
    "\nEnter your mood: "
).lower().strip()


MOOD_NAMES = {
    "happy": "Happy",
    "sad": "Sad",
    "relaxed": "Relaxed",
    "energetic": "Energetic",
    "romantic": "Romantic"
}


if mood not in MOOD_NAMES:

    print("\nInvalid mood.")

    exit()


# ============================================================
# 4. LANGUAGE
# ============================================================

print("\nEnter language:")

print("1. All")
print("2. Tamil")
print("3. English")
print("4. Hindi")
print("5. Telugu")
print("6. Malayalam")
print("7. Korean")
print("8. Bengali")


language_choice = input(
    "\nEnter language number: "
).strip()


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


if language_choice not in LANGUAGES:

    print("\nInvalid language.")

    exit()


language = LANGUAGES[
    language_choice
]


# ============================================================
# 5. USER ID
# ============================================================

print("\nAvailable users:")

print("U001")
print("U002")
print("U003")
print("U004")
print("U005")
print("U006")
print("U007")
print("U008")


user_id = input(
    "\nEnter user ID: "
).strip().upper()


# ============================================================
# 6. EXPLANATION FUNCTION
# ============================================================

def create_explanation(row):

    reasons = []


    # --------------------------------------------------------
    # Content-based explanation
    # --------------------------------------------------------

    content_score = (
        row["content_score"]
        * 100
    )


    if content_score >= 80:

        reasons.append(
            "matches the audio characteristics "
            "of songs you prefer"
        )

    elif content_score >= 60:

        reasons.append(
            "has similar audio characteristics "
            "to your preferences"
        )


    # --------------------------------------------------------
    # Mood explanation
    # --------------------------------------------------------

    mood_score = (
        row["mood_score"]
        * 100
    )


    if mood_score >= 80:

        reasons.append(
            f"strongly matches your "
            f"{MOOD_NAMES[mood]} mood"
        )

    elif mood_score >= 60:

        reasons.append(
            f"matches your "
            f"{MOOD_NAMES[mood]} mood"
        )


    # --------------------------------------------------------
    # Collaborative explanation
    # --------------------------------------------------------

    collaborative_score = (
        row["collaborative_score"]
        * 100
    )


    if collaborative_score >= 80:

        reasons.append(
            "is liked by users with "
            "similar listening preferences"
        )

    elif collaborative_score >= 50:

        reasons.append(
            "has some preference similarity "
            "with similar users"
        )


    # --------------------------------------------------------
    # Language explanation
    # --------------------------------------------------------

    song_language = str(
        row["language"]
    ).strip()


    if language != "All":

        if song_language.lower() == language.lower():

            reasons.append(
                f"matches your "
                f"{language} language preference"
            )


    # --------------------------------------------------------
    # Final explanation
    # --------------------------------------------------------

    if len(reasons) == 0:

        return (
            "Recommended based on the "
            "overall hybrid recommendation score."
        )


    if len(reasons) == 1:

        return (
            "Recommended because it "
            + reasons[0]
            + "."
        )


    return (
        "Recommended because it "
        + ", ".join(reasons[:-1])
        + " and "
        + reasons[-1]
        + "."
    )


# ============================================================
# 7. CREATE EXPLANATIONS
# ============================================================

recommendations[
    "explanation"
] = recommendations.apply(
    create_explanation,
    axis=1
)


# ============================================================
# 8. DISPLAY RESULTS
# ============================================================

print("\n==========================================")
print("EXPLAINABLE RECOMMENDATIONS")
print("==========================================")

print(
    "\nUser:",
    user_id
)

print(
    "Mood:",
    MOOD_NAMES[mood]
)

print(
    "Language:",
    language
)


print(
    "\nWhy these songs were recommended:\n"
)


# ============================================================
# 9. DISPLAY TOP 10
# ============================================================

for number, (_, row) in enumerate(
    recommendations.head(10).iterrows(),
    start=1
):

    print("------------------------------------------")

    print(
        f"{number}. "
        f"{row['title']}"
    )

    print(
        f"Artist: "
        f"{row['artist']}"
    )

    print(
        f"Language: "
        f"{row['language']}"
    )

    print(
        f"Hybrid Score: "
        f"{row['hybrid_score'] * 100:.2f}%"
    )

    print(
        f"Content Match: "
        f"{row['content_score'] * 100:.2f}%"
    )

    print(
        f"Mood Match: "
        f"{row['mood_score'] * 100:.2f}%"
    )

    print(
        f"Collaborative Match: "
        f"{row['collaborative_score'] * 100:.2f}%"
    )

    print(
        "Why recommended:"
    )

    print(
        row["explanation"]
    )


# ============================================================
# 10. SAVE EXPLANATIONS
# ============================================================

output_file = os.path.join(
    OUTPUT_DIR,
    "explainable_recommendations.csv"
)


recommendations[
    [
        "song_id",
        "title",
        "artist",
        "language",
        "content_score",
        "mood_score",
        "collaborative_score",
        "hybrid_score",
        "explanation"
    ]
].to_csv(
    output_file,
    index=False
)


# ============================================================
# 11. FINAL MESSAGE
# ============================================================

print("\n==========================================")
print("EXPLAINABLE RECOMMENDATION COMPLETED")
print("==========================================")

print(
    "\nResults saved to:"
)

print(output_file)