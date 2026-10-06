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

os.makedirs(
    OUTPUT_DIR,
    exist_ok=True
)


# ============================================================
# 2. LOAD SONG DATA
# ============================================================

print("==========================================")
print("STEP 6 - COLLABORATIVE RECOMMENDER")
print("==========================================")

df = pd.read_csv(DATA_FILE)

print("\nSongs loaded:", len(df))


# ============================================================
# 3. CREATE USER INTERACTION DATA
# ============================================================
#
# In a real application, these values will come from:
#
# Like
# Rating
# Listening history
# Play count
# Skip
#
# For now, we create sample user interactions
# so that we can test the recommendation algorithm.
# ============================================================

interaction_data = [

    ["U001", 0, 5],
    ["U001", 1, 4],
    ["U001", 2, 5],
    ["U001", 3, 3],
    ["U001", 4, 4],

    ["U002", 0, 5],
    ["U002", 1, 4],
    ["U002", 5, 5],
    ["U002", 6, 4],
    ["U002", 7, 3],

    ["U003", 2, 5],
    ["U003", 3, 4],
    ["U003", 4, 5],
    ["U003", 8, 4],
    ["U003", 9, 5],

    ["U004", 0, 4],
    ["U004", 2, 5],
    ["U004", 5, 4],
    ["U004", 8, 5],
    ["U004", 10, 4],

    ["U005", 1, 5],
    ["U005", 3, 4],
    ["U005", 6, 5],
    ["U005", 9, 4],
    ["U005", 11, 5],

    ["U006", 0, 5],
    ["U006", 2, 4],
    ["U006", 4, 5],
    ["U006", 8, 4],
    ["U006", 12, 5],

    ["U007", 3, 5],
    ["U007", 5, 4],
    ["U007", 7, 5],
    ["U007", 10, 4],
    ["U007", 13, 5],

    ["U008", 1, 4],
    ["U008", 4, 5],
    ["U008", 6, 4],
    ["U008", 11, 5],
    ["U008", 14, 4]
]


interactions = pd.DataFrame(
    interaction_data,
    columns=[
        "user_id",
        "song_index",
        "rating"
    ]
)


# ============================================================
# 4. CONNECT SONG INDEX WITH SONG INFORMATION
# ============================================================

interactions["song_id"] = interactions[
    "song_index"
].apply(
    lambda x: df.iloc[x]["song_id"]
)

interactions["title"] = interactions[
    "song_index"
].apply(
    lambda x: df.iloc[x]["title"]
)

interactions["artist"] = interactions[
    "song_index"
].apply(
    lambda x: df.iloc[x]["artist"]
)

interactions["language"] = interactions[
    "song_index"
].apply(
    lambda x: df.iloc[x]["language"]
)


# ============================================================
# 5. SAVE INTERACTION DATA
# ============================================================

interaction_file = os.path.join(
    OUTPUT_DIR,
    "user_interactions.csv"
)

interactions.to_csv(
    interaction_file,
    index=False
)


print(
    "\nUser interaction data created."
)

print(
    "Users:",
    interactions["user_id"].nunique()
)

print(
    "Interactions:",
    len(interactions)
)


# ============================================================
# 6. CREATE USER-SONG MATRIX
# ============================================================

user_song_matrix = interactions.pivot_table(
    index="user_id",
    columns="song_id",
    values="rating",
    fill_value=0
)


print("\nUser-Song Matrix:")
print(user_song_matrix)


# ============================================================
# 7. COSINE SIMILARITY FUNCTION
# ============================================================

def cosine_similarity(
    vector_a,
    vector_b
):

    numerator = np.dot(
        vector_a,
        vector_b
    )

    denominator = (
        np.linalg.norm(vector_a)
        *
        np.linalg.norm(vector_b)
    )

    if denominator == 0:
        return 0

    return numerator / denominator


# ============================================================
# 8. FIND SIMILAR USERS
# ============================================================

def find_similar_users(
    target_user,
    matrix
):

    if target_user not in matrix.index:

        return []

    target_vector = matrix.loc[
        target_user
    ].to_numpy(
        dtype=float
    )

    similarities = []

    for user in matrix.index:

        if user == target_user:
            continue

        user_vector = matrix.loc[
            user
        ].to_numpy(
            dtype=float
        )

        similarity = cosine_similarity(
            target_vector,
            user_vector
        )

        similarities.append(
            (
                user,
                similarity
            )
        )

    similarities.sort(
        key=lambda x: x[1],
        reverse=True
    )

    return similarities


# ============================================================
# 9. GENERATE COLLABORATIVE RECOMMENDATIONS
# ============================================================

def recommend_songs(
    target_user,
    top_n=10
):

    # Find similar users

    similar_users = find_similar_users(
        target_user,
        user_song_matrix
    )

    if len(similar_users) == 0:

        return pd.DataFrame()


    print("\nSimilar users:")

    for user, similarity in similar_users[:5]:

        print(
            f"{user} -> "
            f"{similarity:.2f}"
        )


    # Songs already listened/rated
    # by target user

    user_history = interactions[
        interactions["user_id"]
        ==
        target_user
    ]

    listened_songs = set(
        user_history["song_id"]
    )


    # --------------------------------------------------------
    # Calculate recommendation scores
    # --------------------------------------------------------

    recommendation_scores = {}


    for similar_user, similarity in similar_users:

        user_history = interactions[
            interactions["user_id"]
            ==
            similar_user
        ]

        for _, row in user_history.iterrows():

            song_id = row["song_id"]

            rating = row["rating"]


            # Do not recommend songs
            # already used by target user

            if song_id in listened_songs:

                continue


            if song_id not in recommendation_scores:

                recommendation_scores[
                    song_id
                ] = 0


            recommendation_scores[
                song_id
            ] += (
                similarity
                *
                rating
            )


    # --------------------------------------------------------
    # Sort recommendations
    # --------------------------------------------------------

    sorted_songs = sorted(
        recommendation_scores.items(),
        key=lambda x: x[1],
        reverse=True
    )


    # --------------------------------------------------------
    # Create result
    # --------------------------------------------------------

    results = []


    for song_id, score in sorted_songs:

        song_rows = df[
            df["song_id"]
            ==
            song_id
        ]

        if len(song_rows) == 0:

            continue


        song = song_rows.iloc[0]


        results.append({

            "song_id":
                song["song_id"],

            "title":
                song["title"],

            "artist":
                song["artist"],

            "language":
                song["language"],

            "collaborative_score":
                score

        })


        if len(results) >= top_n:

            break


    return pd.DataFrame(results)


# ============================================================
# 10. ASK USER
# ============================================================

print("\n==========================================")
print("USER RECOMMENDATION")
print("==========================================")

print("\nAvailable users:")

for user in sorted(
    interactions["user_id"].unique()
):

    print(user)


target_user = input(
    "\nEnter user ID: "
).strip().upper()


# ============================================================
# 11. CHECK USER
# ============================================================

if target_user not in interactions[
    "user_id"
].unique():

    print(
        "\nUser not found."
    )

    print(
        "Please use U001 to U008."
    )

    exit()


# ============================================================
# 12. GET RECOMMENDATIONS
# ============================================================

recommendations = recommend_songs(
    target_user,
    top_n=10
)


# ============================================================
# 13. DISPLAY RESULTS
# ============================================================

print("\n==========================================")
print("COLLABORATIVE RECOMMENDATIONS")
print("==========================================")

print(
    "\nUser:",
    target_user
)


if recommendations.empty:

    print(
        "\nNo recommendations available."
    )

else:

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
            f"-> Score: "
            f"{row['collaborative_score']:.2f}"
        )


# ============================================================
# 14. SAVE RECOMMENDATIONS
# ============================================================

recommendation_file = os.path.join(
    OUTPUT_DIR,
    "collaborative_recommendations.csv"
)


recommendations.to_csv(
    recommendation_file,
    index=False
)


# ============================================================
# 15. FINAL MESSAGE
# ============================================================

print("\n==========================================")
print("COLLABORATIVE RECOMMENDATION COMPLETED")
print("==========================================")

print(
    "\nInteraction data saved to:"
)

print(interaction_file)

print(
    "\nRecommendations saved to:"
)

print(recommendation_file)