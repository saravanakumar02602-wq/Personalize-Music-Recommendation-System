import pandas as pd
import os


# ============================================================
# 1. PROJECT PATHS
# ============================================================

BASE_DIR = os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))
)

DATA_DIR = os.path.join(BASE_DIR, "data")

SPOTIFY_FILE = os.path.join(
    DATA_DIR, "spotify_tracks.csv"
)

TAMIL_FILE = os.path.join(
    DATA_DIR, "Tamil_songs.csv"
)

OUTPUT_FILE = os.path.join(
    DATA_DIR, "master_songs.csv"
)


# ============================================================
# 2. LOAD DATASETS
# ============================================================

print("==========================================")
print("MUSIC RECOMMENDATION SYSTEM")
print("DATA PREPARATION")
print("==========================================")

print("\nLoading datasets...")

spotify = pd.read_csv(SPOTIFY_FILE)
tamil = pd.read_csv(TAMIL_FILE)

print(f"Spotify dataset : {spotify.shape}")
print(f"Tamil dataset   : {tamil.shape}")


# ============================================================
# 3. CLEAN SPOTIFY DATASET
# ============================================================

print("\nCleaning Spotify dataset...")

spotify = spotify.rename(columns={
    "track_id": "song_id",
    "track_name": "title",
    "artist_name": "artist"
})


spotify_columns = [
    "song_id",
    "title",
    "artist",
    "language",
    "year",
    "popularity",
    "album_name",
    "acousticness",
    "danceability",
    "duration_ms",
    "energy",
    "instrumentalness",
    "key",
    "liveness",
    "loudness",
    "mode",
    "speechiness",
    "tempo",
    "time_signature",
    "valence",
    "track_url"
]

spotify = spotify[spotify_columns]


# Remove rows without important information

spotify = spotify.dropna(
    subset=[
        "title",
        "artist",
        "language"
    ]
)


# ============================================================
# 4. CLEAN TAMIL DATASET
# ============================================================

print("Cleaning Tamil dataset...")

# Remove repeated header rows

tamil = tamil[
    tamil["song_name"].astype(str).str.lower()
    != "song_name"
].copy()


# Rename columns

tamil = tamil.rename(columns={
    "song_name": "title",
    "singer": "artist",
    "Valence": "valence"
})


# ============================================================
# 5. CONVERT NUMERIC COLUMNS
# ============================================================

numeric_columns = [
    "danceability",
    "acousticness",
    "energy",
    "liveness",
    "loudness",
    "speechiness",
    "tempo",
    "mode",
    "key",
    "valence",
    "time_signature",
    "popularity",
    "Stream"
]

for column in numeric_columns:

    if column in tamil.columns:

        tamil[column] = pd.to_numeric(
            tamil[column],
            errors="coerce"
        )


# ============================================================
# 6. CREATE SONG IDs FOR TAMIL DATA
# ============================================================

tamil["song_id"] = [
    f"TAMIL_{i}"
    for i in range(len(tamil))
]


# ============================================================
# 7. ADD MISSING COLUMNS
# ============================================================

tamil["year"] = pd.NA
tamil["album_name"] = pd.NA
tamil["duration_ms"] = pd.NA
tamil["instrumentalness"] = pd.NA
tamil["track_url"] = pd.NA


# ============================================================
# 8. ADD LANGUAGE
# ============================================================

tamil["language"] = "Tamil"


# ============================================================
# 9. SELECT COMMON COLUMNS
# ============================================================

master_columns = [
    "song_id",
    "title",
    "artist",
    "language",
    "year",
    "popularity",
    "album_name",
    "acousticness",
    "danceability",
    "duration_ms",
    "energy",
    "instrumentalness",
    "key",
    "liveness",
    "loudness",
    "mode",
    "speechiness",
    "tempo",
    "time_signature",
    "valence",
    "track_url"
]


spotify = spotify[master_columns]

tamil = tamil[master_columns]


# ============================================================
# 10. COMBINE DATASETS
# ============================================================

print("\nCombining datasets...")

master = pd.concat(
    [spotify, tamil],
    ignore_index=True
)


# ============================================================
# 11. REMOVE INVALID RECORDS
# ============================================================

master = master.dropna(
    subset=[
        "title",
        "artist",
        "language"
    ]
)


# ============================================================
# 12. REMOVE DUPLICATES
# ============================================================

master = master.drop_duplicates(
    subset=[
        "title",
        "artist",
        "language"
    ]
)


# ============================================================
# 13. RESET INDEX
# ============================================================

master = master.reset_index(drop=True)


# ============================================================
# 14. SAVE MASTER DATASET
# ============================================================

master.to_csv(
    OUTPUT_FILE,
    index=False
)


# ============================================================
# 15. DISPLAY RESULTS
# ============================================================

print("\n==========================================")
print("DATA PREPARATION COMPLETED")
print("==========================================")

print(
    f"\nTotal songs in master dataset: {len(master)}"
)

print("\nSongs by language:")

print(
    master["language"]
    .value_counts()
)


print("\nMaster dataset columns:")

for column in master.columns:
    print(" -", column)


print("\nMaster dataset saved successfully:")

print(OUTPUT_FILE)

print("\n==========================================")
print("READY FOR NEXT STEP")
print("==========================================")