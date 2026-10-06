import pandas as pd
import numpy as np
import os
import joblib


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

MODEL_DIR = os.path.join(
    BASE_DIR,
    "models"
)


# ============================================================
# 2. LOAD DATA
# ============================================================

print("==========================================")
print("STEP 4 - CONTENT BASED RECOMMENDER")
print("==========================================")

df = pd.read_csv(DATA_FILE)

feature_matrix = joblib.load(
    os.path.join(
        MODEL_DIR,
        "feature_matrix.pkl"
    )
)


print("\nSongs loaded:", len(df))

print(
    "Feature matrix:",
    feature_matrix.shape
)


# ============================================================
# 3. COSINE SIMILARITY FUNCTION
# ============================================================

def cosine_similarity_single(
    target_vector,
    matrix
):

    # Dot product
    dot_product = np.dot(
        matrix,
        target_vector
    )

    # Length of target vector
    target_norm = np.linalg.norm(
        target_vector
    )

    # Length of every song vector
    matrix_norm = np.linalg.norm(
        matrix,
        axis=1
    )

    # Prevent division by zero
    denominator = (
        matrix_norm * target_norm
    )

    denominator[
        denominator == 0
    ] = 1

    similarity = (
        dot_product / denominator
    )

    return similarity


# ============================================================
# 4. RECOMMEND FUNCTION
# ============================================================

def recommend_songs(
    song_name,
    number_of_recommendations=10
):

    # Search song
    search_text = song_name.lower().strip()
    matches = df[
        df["title"]
        .astype(str)
        .str.lower()
        .str.contains(
            search_text,
        na=False
    )
]


    # If song not found
    if matches.empty:

        print("\nSong not found.")

        return None


    # Get first matching song
    song_index = matches.index[0]


    # Get feature vector
    target_vector = feature_matrix[
        song_index
    ]


    # Calculate similarity
    similarity_scores = (
        cosine_similarity_single(
            target_vector,
            feature_matrix
        )
    )


    # Create result dataframe
    result = df[
        [
            "title",
            "artist",
            "language"
        ]
    ].copy()


    result["similarity"] = (
        similarity_scores
    )


    # Remove input song
    result = result.drop(
        index=song_index
    )


    # Sort by similarity
    result = result.sort_values(
        "similarity",
        ascending=False
    )


    # Select top recommendations
    result = result.head(
        number_of_recommendations
    )


    # Convert similarity to percentage
    result["similarity"] = (
        result["similarity"] * 100
    ).round(2)


    return result.reset_index(
        drop=True
    )


# ============================================================
# 5. USER INPUT
# ============================================================

print("\n==========================================")
print("SONG SEARCH")
print("==========================================")

song_name = input(
    "\nEnter a song name: "
)


# ============================================================
# 6. GET RECOMMENDATIONS
# ============================================================

recommendations = recommend_songs(
    song_name,
    10
)


# ============================================================
# 7. DISPLAY RESULTS
# ============================================================

if recommendations is not None:

    print("\n==========================================")
    print("RECOMMENDED SONGS")
    print("==========================================")

    for i, row in recommendations.iterrows():

        print(
            f"{i + 1}. "
            f"{row['title']} - "
            f"{row['artist']} "
            f"({row['language']}) "
            f"-> "
            f"{row['similarity']}% similar"
        )