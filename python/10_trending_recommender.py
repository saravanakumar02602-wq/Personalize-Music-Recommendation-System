import pandas as pd
import numpy as np
import json
import os


# ============================================================
# FILE PATHS
# ============================================================

DATA_FILE = "data/master_songs.csv"
PROFILE_FILE = "outputs/user_profiles.json"
INTERACTION_FILE = "outputs/user_interactions.csv"
OUTPUT_FILE = "outputs/trending_recommendations.csv"


# ============================================================
# LANGUAGE OPTIONS
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
# LOAD SONG DATA
# ============================================================

print("\nLoading music dataset...")

df = pd.read_csv(DATA_FILE)

print("Total songs available:", len(df))


# ============================================================
# CLEAN DATA
# ============================================================

df["title"] = df["title"].fillna("").astype(str)
df["artist"] = df["artist"].fillna("").astype(str)
df["language"] = df["language"].fillna("Unknown").astype(str)

df["popularity"] = pd.to_numeric(
    df["popularity"],
    errors="coerce"
).fillna(0)

df["year"] = pd.to_numeric(
    df["year"],
    errors="coerce"
)


# ============================================================
# LOAD USER PROFILES
# ============================================================

if os.path.exists(PROFILE_FILE):

    with open(PROFILE_FILE, "r", encoding="utf-8") as file:
        user_profiles = json.load(file)

else:

    user_profiles = {}


# ============================================================
# GET USER ID
# ============================================================

user_id = input("\nEnter User ID: ").strip()

if user_id in user_profiles:

    profile = user_profiles[user_id]

    print("\nUser profile found.")
    print("Name:", profile.get("name", "Unknown"))
    print(
        "Preferred Language:",
        profile.get("preferred_language", "All")
    )

else:

    print("\nUser profile not found.")
    print("You can still use trending recommendations.")
    profile = {}


# ============================================================
# LANGUAGE SELECTION
# ============================================================

print("\nSelect Language")

for key, value in LANGUAGES.items():
    print(f"{key}. {value}")

language_choice = input("\nEnter language number: ").strip()

language = LANGUAGES.get(language_choice, "All")

print("\nSelected Language:", language)


# ============================================================
# RECOMMENDATION TYPE
# ============================================================

print("\nSelect Recommendation Type")

print("1. Trending Songs")
print("2. New Songs")

recommendation_type = input(
    "\nEnter option number: "
).strip()


# ============================================================
# FILTER LANGUAGE
# ============================================================

candidate_df = df.copy()

if language != "All":

    candidate_df = candidate_df[
        candidate_df["language"].str.lower()
        == language.lower()
    ].copy()


# ============================================================
# REMOVE SONGS FROM LISTENING HISTORY
# ============================================================

listening_history = profile.get(
    "listening_history",
    []
)

listening_history = [
    str(song).strip().lower()
    for song in listening_history
]


if len(listening_history) > 0:

    candidate_df = candidate_df[
        ~candidate_df["title"]
        .str.lower()
        .isin(listening_history)
    ].copy()


# ============================================================
# REMOVE SONGS FROM USER INTERACTIONS
# ============================================================

if os.path.exists(INTERACTION_FILE):

    interactions = pd.read_csv(INTERACTION_FILE)

    if "user_id" in interactions.columns:

        user_interactions = interactions[
            interactions["user_id"].astype(str) == str(user_id)
        ]

        if "song_id" in user_interactions.columns:

            rated_song_ids = set(
                user_interactions["song_id"]
                .astype(str)
            )

            if "song_id" in candidate_df.columns:

                candidate_df = candidate_df[
                    ~candidate_df["song_id"]
                    .astype(str)
                    .isin(rated_song_ids)
                ].copy()


# ============================================================
# CHECK DATA
# ============================================================

if candidate_df.empty:

    print("\nNo new songs are available for this selection.")

    print(
        "\nTry another language or recommendation type."
    )

    exit()


# ============================================================
# NORMALIZE POPULARITY
# ============================================================

pop_min = candidate_df["popularity"].min()

pop_max = candidate_df["popularity"].max()


if pop_max > pop_min:

    candidate_df["popularity_score"] = (
        (candidate_df["popularity"] - pop_min)
        / (pop_max - pop_min)
    ) * 100

else:

    candidate_df["popularity_score"] = 50


# ============================================================
# NORMALIZE YEAR
# ============================================================

valid_years = candidate_df["year"].dropna()


if len(valid_years) > 0:

    min_year = valid_years.min()
    max_year = valid_years.max()

    if max_year > min_year:

        candidate_df["recency_score"] = (
            (candidate_df["year"] - min_year)
            / (max_year - min_year)
        ) * 100

    else:

        candidate_df["recency_score"] = 50

else:

    candidate_df["recency_score"] = 50


# ============================================================
# TRENDING SCORE
# ============================================================

candidate_df["trend_score"] = (
    candidate_df["popularity_score"] * 0.70
    +
    candidate_df["recency_score"] * 0.30
)


# ============================================================
# NEW SONG DISCOVERY
# ============================================================

if recommendation_type == "2":

    # Find the newest year available
    latest_year = candidate_df["year"].max()

    if not pd.isna(latest_year):

        # Consider songs from the latest 2 years
        new_songs = candidate_df[
            candidate_df["year"] >= latest_year - 2
        ].copy()

        if not new_songs.empty:

            candidate_df = new_songs


# ============================================================
# SORT RESULTS
# ============================================================

candidate_df = candidate_df.sort_values(
    by="trend_score",
    ascending=False
)


# ============================================================
# TOP 10 RECOMMENDATIONS
# ============================================================

recommendations = candidate_df.head(10).copy()


# ============================================================
# DISPLAY RESULTS
# ============================================================

print("\n" + "=" * 70)

if recommendation_type == "1":

    print("           TRENDING SONG RECOMMENDATIONS")

else:

    print("             NEW SONG DISCOVERY")


print("=" * 70)

print(
    f"User: {user_id} | Language: {language}"
)

print("-" * 70)


for index, row in recommendations.iterrows():

    title = row["title"]
    artist = row["artist"]
    song_language = row["language"]

    popularity = row["popularity"]

    year = row["year"]

    trend_score = row["trend_score"]

    if pd.isna(year):
        year_text = "Unknown"
    else:
        year_text = str(int(year))

    print(
        f"\nSong: {title}"
    )

    print(
        f"Artist: {artist}"
    )

    print(
        f"Language: {song_language}"
    )

    print(
        f"Year: {year_text}"
    )

    print(
        f"Popularity: {popularity:.1f}"
    )

    print(
        f"Trend Score: {trend_score:.2f}"
    )


# ============================================================
# SAVE RESULTS
# ============================================================

output_columns = [
    "song_id",
    "title",
    "artist",
    "language",
    "year",
    "popularity",
    "popularity_score",
    "recency_score",
    "trend_score"
]


available_columns = [
    column
    for column in output_columns
    if column in recommendations.columns
]


recommendations[
    available_columns
].to_csv(
    OUTPUT_FILE,
    index=False,
    encoding="utf-8-sig"
)


# ============================================================
# FINAL MESSAGE
# ============================================================

print("\n" + "=" * 70)

print(
    "Recommendations generated successfully!"
)

print(
    "Saved to:",
    OUTPUT_FILE
)

print("=" * 70)