import pandas as pd
import os
import json


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

PROFILE_FILE = os.path.join(
    OUTPUT_DIR,
    "user_profiles.json"
)

os.makedirs(
    OUTPUT_DIR,
    exist_ok=True
)


# ============================================================
# 2. LOAD SONG DATA
# ============================================================

print("==========================================")
print("STEP 9 - USER PROFILE SYSTEM")
print("==========================================")

df = pd.read_csv(DATA_FILE)

print(
    "\nSongs loaded:",
    len(df)
)


# ============================================================
# 3. LOAD EXISTING USER PROFILES
# ============================================================

if os.path.exists(PROFILE_FILE):

    with open(
        PROFILE_FILE,
        "r",
        encoding="utf-8"
    ) as file:

        profiles = json.load(file)

else:

    profiles = {}


# ============================================================
# 4. LANGUAGE OPTIONS
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
# 5. MOOD OPTIONS
# ============================================================

MOODS = {
    "1": "Happy",
    "2": "Sad",
    "3": "Relaxed",
    "4": "Energetic",
    "5": "Romantic"
}


# ============================================================
# 6. DISPLAY MENU
# ============================================================

print("\n1. Create / Update User Profile")
print("2. View User Profile")
print("3. Add Favorite Song")
print("4. Add Favorite Artist")
print("5. Add Song Rating")
print("6. Add Listening History")
print("7. Exit")


choice = input(
    "\nEnter your choice: "
).strip()


# ============================================================
# 7. CREATE / UPDATE PROFILE
# ============================================================

if choice == "1":

    print("\n==========================================")
    print("CREATE / UPDATE USER PROFILE")
    print("==========================================")


    user_id = input(
        "\nEnter User ID: "
    ).strip().upper()


    name = input(
        "Enter your name: "
    ).strip()


    # --------------------------------------------------------
    # LANGUAGE
    # --------------------------------------------------------

    print("\nPreferred Language:")

    for number, language in LANGUAGES.items():

        print(
            f"{number}. {language}"
        )


    language_choice = input(
        "\nSelect language: "
    ).strip()


    if language_choice not in LANGUAGES:

        print(
            "\nInvalid language."
        )

        exit()


    preferred_language = LANGUAGES[
        language_choice
    ]


    # --------------------------------------------------------
    # MOOD
    # --------------------------------------------------------

    print("\nFavorite Mood:")

    for number, mood in MOODS.items():

        print(
            f"{number}. {mood}"
        )


    mood_choice = input(
        "\nSelect mood: "
    ).strip()


    if mood_choice not in MOODS:

        print(
            "\nInvalid mood."
        )

        exit()


    favorite_mood = MOODS[
        mood_choice
    ]


    # --------------------------------------------------------
    # CREATE PROFILE
    # --------------------------------------------------------

    if user_id in profiles:

        profile = profiles[user_id]

        profile["name"] = name
        profile["preferred_language"] = (
            preferred_language
        )
        profile["favorite_mood"] = (
            favorite_mood
        )

        print(
            "\nProfile updated successfully."
        )

    else:

        profiles[user_id] = {

            "user_id":
                user_id,

            "name":
                name,

            "preferred_language":
                preferred_language,

            "favorite_mood":
                favorite_mood,

            "favorite_artists":
                [],

            "favorite_songs":
                [],

            "ratings":
                {},

            "listening_history":
                []
        }

        print(
            "\nProfile created successfully."
        )


# ============================================================
# 8. VIEW PROFILE
# ============================================================

elif choice == "2":

    print("\n==========================================")
    print("VIEW USER PROFILE")
    print("==========================================")


    user_id = input(
        "\nEnter User ID: "
    ).strip().upper()


    if user_id not in profiles:

        print(
            "\nUser profile not found."
        )

        exit()


    profile = profiles[user_id]


    print(
        "\nUser ID:",
        profile["user_id"]
    )

    print(
        "Name:",
        profile["name"]
    )

    print(
        "Preferred Language:",
        profile["preferred_language"]
    )

    print(
        "Favorite Mood:",
        profile["favorite_mood"]
    )


    print(
        "\nFavorite Artists:"
    )

    if profile["favorite_artists"]:

        for artist in profile[
            "favorite_artists"
        ]:

            print(
                "-",
                artist
            )

    else:

        print(
            "No favorite artists."
        )


    print(
        "\nFavorite Songs:"
    )

    if profile["favorite_songs"]:

        for song in profile[
            "favorite_songs"
        ]:

            print(
                "-",
                song
            )

    else:

        print(
            "No favorite songs."
        )


    print(
        "\nRatings:"
    )

    if profile["ratings"]:

        for song, rating in profile[
            "ratings"
        ].items():

            print(
                f"- {song}: "
                f"{rating}/5"
            )

    else:

        print(
            "No ratings."
        )


    print(
        "\nListening History:"
    )

    if profile[
        "listening_history"
    ]:

        for song in profile[
            "listening_history"
        ]:

            print(
                "-",
                song
            )

    else:

        print(
            "No listening history."
        )


# ============================================================
# 9. ADD FAVORITE SONG
# ============================================================

elif choice == "3":

    user_id = input(
        "\nEnter User ID: "
    ).strip().upper()


    if user_id not in profiles:

        print(
            "\nCreate the user profile first."
        )

        exit()


    song_name = input(
        "Enter favorite song name: "
    ).strip()


    profiles[user_id][
        "favorite_songs"
    ].append(
        song_name
    )


    print(
        "\nFavorite song added successfully."
    )


# ============================================================
# 10. ADD FAVORITE ARTIST
# ============================================================

elif choice == "4":

    user_id = input(
        "\nEnter User ID: "
    ).strip().upper()


    if user_id not in profiles:

        print(
            "\nCreate the user profile first."
        )

        exit()


    artist_name = input(
        "Enter favorite artist name: "
    ).strip()


    profiles[user_id][
        "favorite_artists"
    ].append(
        artist_name
    )


    print(
        "\nFavorite artist added successfully."
    )


# ============================================================
# 11. ADD SONG RATING
# ============================================================

elif choice == "5":

    user_id = input(
        "\nEnter User ID: "
    ).strip().upper()


    if user_id not in profiles:

        print(
            "\nCreate the user profile first."
        )

        exit()


    song_name = input(
        "Enter song name: "
    ).strip()


    rating = input(
        "Enter rating (1-5): "
    ).strip()


    try:

        rating = int(rating)

    except ValueError:

        print(
            "\nRating must be a number."
        )

        exit()


    if rating < 1 or rating > 5:

        print(
            "\nRating must be between 1 and 5."
        )

        exit()


    profiles[user_id][
        "ratings"
    ][song_name] = rating


    print(
        "\nRating saved successfully."
    )


# ============================================================
# 12. ADD LISTENING HISTORY
# ============================================================

elif choice == "6":

    user_id = input(
        "\nEnter User ID: "
    ).strip().upper()


    if user_id not in profiles:

        print(
            "\nCreate the user profile first."
        )

        exit()


    song_name = input(
        "Enter song listened to: "
    ).strip()


    profiles[user_id][
        "listening_history"
    ].append(
        song_name
    )


    print(
        "\nListening history updated."
    )


# ============================================================
# 13. EXIT
# ============================================================

elif choice == "7":

    print(
        "\nExiting..."
    )

    exit()


# ============================================================
# 14. SAVE PROFILES
# ============================================================

with open(
    PROFILE_FILE,
    "w",
    encoding="utf-8"
) as file:

    json.dump(
        profiles,
        file,
        indent=4,
        ensure_ascii=False
    )


# ============================================================
# 15. FINAL MESSAGE
# ============================================================

print("\n==========================================")
print("USER PROFILE OPERATION COMPLETED")
print("==========================================")

print(
    "\nProfile data saved to:"
)

print(
    PROFILE_FILE
)