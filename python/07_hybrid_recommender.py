import os
import sys
import numpy as np
import pandas as pd
import joblib


# ============================================================
# PROJECT PATHS
# ============================================================

PROJECT_DIR = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

DATA_FILE = os.path.join(
    PROJECT_DIR,
    "data",
    "master_songs.csv"
)

OUTPUT_DIR = os.path.join(
    PROJECT_DIR,
    "outputs"
)

OUTPUT_FILE = os.path.join(
    OUTPUT_DIR,
    "hybrid_recommendations.csv"
)

INTERACTION_FILE = os.path.join(
    OUTPUT_DIR,
    "user_interactions.csv"
)

os.makedirs(OUTPUT_DIR, exist_ok=True)


# ============================================================
# LOAD DATA
# ============================================================

df = pd.read_csv(DATA_FILE)


# ============================================================
# LANGUAGE NORMALIZATION
# ============================================================

def normalize_language(value):

    if pd.isna(value):
        return "Unknown"

    value = str(value).strip().lower()

    mapping = {
        "tamil": "Tamil",
        "english": "English",
        "hindi": "Hindi",
        "telugu": "Telugu",
        "malayalam": "Malayalam",
        "kannada": "Kannada",
        "bengali": "Bengali",
        "korean": "Korean",
        "unknown": "Unknown"
    }

    return mapping.get(
        value,
        value.title()
    )


df["language_clean"] = df["language"].apply(
    normalize_language
)


# ============================================================
# MOOD PROFILES
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
# GET INPUT
# ============================================================

if len(sys.argv) >= 5:

    user_id = sys.argv[1].strip()

    mood = sys.argv[2].strip().lower()

    requested_language = sys.argv[3].strip()

    try:
        number_of_songs = int(sys.argv[4])
    except:
        number_of_songs = 10

else:

    user_id = input(
        "Enter User ID: "
    ).strip()

    mood = input(
        "Enter Mood: "
    ).strip().lower()

    requested_language = input(
        "Enter Language: "
    ).strip()

    try:

        number_of_songs = int(
            input(
                "Number of recommendations (10/20): "
            )
        )

    except:

        number_of_songs = 10


# ============================================================
# VALIDATE NUMBER
# ============================================================

if number_of_songs not in [10, 20]:

    number_of_songs = 10


# ============================================================
# VALIDATE MOOD
# ============================================================

if mood not in MOOD_PROFILES:

    print("Invalid mood:", mood)

    print(
        "Available:",
        ", ".join(
            MOOD_PROFILES.keys()
        )
    )

    sys.exit(1)


# ============================================================
# NORMALIZE REQUESTED LANGUAGE
# ============================================================

selected_language = normalize_language(
    requested_language
)


print("\n" + "=" * 60)
print("HYBRID MUSIC RECOMMENDATION SYSTEM")
print("=" * 60)

print("User ID :", user_id)
print("Mood    :", mood)
print("Language:", selected_language)
print("Songs   :", number_of_songs)

print("=" * 60)


# ============================================================
# STRICT LANGUAGE FILTER
# ============================================================

if selected_language.lower() == "all":

    filtered_df = df.copy()

else:

    filtered_df = df[
        df["language_clean"].str.strip().str.lower()
        ==
        selected_language.strip().lower()
    ].copy()


# ============================================================
# VERIFY LANGUAGE
# ============================================================

print(
    "\nAvailable songs for",
    selected_language,
    ":",
    len(filtered_df)
)


if len(filtered_df) == 0:

    print(
        "\nNo songs available for:",
        selected_language
    )

    print(
        "\nAvailable languages:"
    )

    print(
        sorted(
            df["language_clean"].unique()
        )
    )

    # Create empty output
    pd.DataFrame().to_csv(
        OUTPUT_FILE,
        index=False
    )

    sys.exit(0)


# ============================================================
# FEATURE COLUMNS
# ============================================================

FEATURE_COLUMNS = [
    "energy",
    "danceability",
    "valence",
    "acousticness",
    "instrumentalness",
    "speechiness",
    "tempo",
    "loudness"
]


# ============================================================
# CLEAN FEATURES
# ============================================================

for column in FEATURE_COLUMNS:

    df[column] = pd.to_numeric(
        df[column],
        errors="coerce"
    )

    df[column] = df[column].fillna(
        df[column].median()
    )


# Recreate filtered dataframe after cleaning

if selected_language.lower() == "all":

    filtered_df = df.copy()

else:

    filtered_df = df[
        df["language_clean"].str.strip().str.lower()
        ==
        selected_language.strip().lower()
    ].copy()


# ============================================================
# MOOD SCORE
# ============================================================

target = np.array([
    MOOD_PROFILES[mood]["energy"],
    MOOD_PROFILES[mood]["danceability"],
    MOOD_PROFILES[mood]["valence"]
])


candidate_mood_features = filtered_df[
    [
        "energy",
        "danceability",
        "valence"
    ]
].to_numpy()


distance = np.linalg.norm(
    candidate_mood_features - target,
    axis=1
)


mood_scores = (
    1 / (1 + distance)
) * 100


if mood_scores.max() > 0:

    mood_scores = (
        mood_scores /
        mood_scores.max()
    ) * 100


# ============================================================
# LOAD USER INTERACTIONS
# ============================================================

if os.path.exists(INTERACTION_FILE):

    interactions = pd.read_csv(
        INTERACTION_FILE
    )

else:

    interactions = pd.DataFrame()


# ============================================================
# CONTENT SCORE
# ============================================================

content_scores = np.zeros(
    len(filtered_df)
)


if not interactions.empty:

    if (
        "user_id" in interactions.columns
        and
        "rating" in interactions.columns
    ):

        user_history = interactions[
            interactions["user_id"].astype(str)
            ==
            str(user_id)
        ]

        liked = user_history[
            user_history["rating"] >= 4
        ]

        if not liked.empty:

            if "song_index" in liked.columns:

                liked_indices = (
                    liked["song_index"]
                    .astype(int)
                    .to_numpy()
                )

                liked_indices = liked_indices[
                    (liked_indices >= 0)
                    &
                    (liked_indices < len(df))
                ]

                if len(liked_indices) > 0:

                    user_profile = df.iloc[
                        liked_indices
                    ][FEATURE_COLUMNS].mean().to_numpy()

                    candidate_matrix = filtered_df[
                        FEATURE_COLUMNS
                    ].to_numpy()

                    candidate_norm = np.linalg.norm(
                        candidate_matrix,
                        axis=1
                    )

                    profile_norm = np.linalg.norm(
                        user_profile
                    )

                    denominator = (
                        candidate_norm *
                        profile_norm
                    )

                    denominator[
                        denominator == 0
                    ] = 1

                    similarities = (
                        np.dot(
                            candidate_matrix,
                            user_profile
                        )
                        /
                        denominator
                    )

                    content_scores = (
                        (similarities + 1)
                        / 2
                    ) * 100


# ============================================================
# COLLABORATIVE SCORE
# ============================================================

collaborative_scores = np.zeros(
    len(filtered_df)
)


if not interactions.empty:

    if (
        "song_index" in interactions.columns
        and
        "rating" in interactions.columns
    ):

        highly_rated = interactions[
            interactions["rating"] >= 4
        ]

        rating_counts = (
            highly_rated
            .groupby("song_index")
            .size()
        )

        for position, original_index in enumerate(
            filtered_df.index
        ):

            collaborative_scores[position] = (
                rating_counts.get(
                    original_index,
                    0
                )
            )


        if collaborative_scores.max() > 0:

            collaborative_scores = (
                collaborative_scores /
                collaborative_scores.max()
            ) * 100


# ============================================================
# CREATE CANDIDATE DATAFRAME
# ============================================================

candidate_df = filtered_df.copy()

candidate_df["content_score"] = (
    content_scores
)

candidate_df["mood_score"] = (
    mood_scores
)

candidate_df["collaborative_score"] = (
    collaborative_scores
)


# ============================================================
# HYBRID SCORE
# ============================================================

candidate_df["hybrid_score"] = (

    candidate_df["content_score"] * 0.40

    +

    candidate_df["mood_score"] * 0.30

    +

    candidate_df["collaborative_score"] * 0.30

)


# ============================================================
# REMOVE ALREADY RATED SONGS
# ============================================================

rated_indices = set()

if not interactions.empty:

    if (
        "user_id" in interactions.columns
        and
        "song_index" in interactions.columns
    ):

        user_history = interactions[
            interactions["user_id"].astype(str)
            ==
            str(user_id)
        ]

        rated_indices = set(
            user_history[
                "song_index"
            ].astype(int)
        )


if rated_indices:

    candidate_df = candidate_df[
        ~candidate_df.index.isin(
            rated_indices
        )
    ]


# ============================================================
# SORT BY HYBRID SCORE
# ============================================================

candidate_df = candidate_df.sort_values(
    by="hybrid_score",
    ascending=False
)


# ============================================================
# SELECT REQUESTED NUMBER
# ============================================================

recommendations = candidate_df.head(
    number_of_songs
).copy()


# ============================================================
# FINAL LANGUAGE SAFETY CHECK
# ============================================================

if selected_language.lower() != "all":

    recommendations = recommendations[
        recommendations["language_clean"]
        .astype(str)
        .str.strip()
        .str.lower()
        ==
        selected_language.strip().lower()
    ].copy()


# ============================================================
# OUTPUT COLUMNS
# ============================================================

columns = [
    "song_id",
    "title",
    "artist",
    "language",
    "language_clean",
    "year",
    "popularity",
    "album_name",
    "hybrid_score",
    "content_score",
    "mood_score",
    "collaborative_score",
    "track_url"
]


columns = [
    column
    for column in columns
    if column in recommendations.columns
]


final_df = recommendations[
    columns
].copy()


# ============================================================
# FINAL VERIFICATION
# ============================================================

if selected_language.lower() != "all":

    wrong_language = final_df[
        final_df["language_clean"]
        .astype(str)
        .str.lower()
        !=
        selected_language.lower()
    ]

    if len(wrong_language) > 0:

        print(
            "\nERROR: Wrong language detected."
        )

        print(
            wrong_language[
                [
                    "title",
                    "language",
                    "language_clean"
                ]
            ]
        )

        sys.exit(1)


# ============================================================
# SAVE
# ============================================================

final_df.to_csv(
    OUTPUT_FILE,
    index=False
)


# ============================================================
# DISPLAY RESULTS
# ============================================================

print("\n" + "=" * 60)

print("FINAL RECOMMENDATIONS")

print("=" * 60)

print(
    "Requested language:",
    selected_language
)

print(
    "Requested songs:",
    number_of_songs
)

print(
    "Returned songs:",
    len(final_df)
)

print()


if len(final_df) > 0:

    print(
        final_df[
            [
                "title",
                "artist",
                "language",
                "hybrid_score"
            ]
        ].to_string(
            index=False
        )
    )

else:

    print(
        "No recommendations found."
    )


print("\nSaved to:")

print(
    OUTPUT_FILE
)

print("=" * 60)