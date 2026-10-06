import os
import sys
import subprocess
import pandas as pd


# ============================================================
# PATHS
# ============================================================

PROJECT_DIR = os.path.dirname(
    os.path.dirname(
        os.path.abspath(__file__)
    )
)

PYTHON_DIR = os.path.join(
    PROJECT_DIR,
    "python"
)

OUTPUT_DIR = os.path.join(
    PROJECT_DIR,
    "outputs"
)

HYBRID_SCRIPT = os.path.join(
    PYTHON_DIR,
    "07_hybrid_recommender.py"
)

EXPLAIN_SCRIPT = os.path.join(
    PYTHON_DIR,
    "08_explain_recommendation.py"
)

HYBRID_OUTPUT = os.path.join(
    OUTPUT_DIR,
    "hybrid_recommendations.csv"
)

EXPLAIN_OUTPUT = os.path.join(
    OUTPUT_DIR,
    "explainable_recommendations.csv"
)

FINAL_OUTPUT = os.path.join(
    OUTPUT_DIR,
    "dashboard_recommendations.csv"
)


# ============================================================
# INPUTS
# ============================================================

if len(sys.argv) >= 5:

    user_id = sys.argv[1].strip()

    mood = sys.argv[2].strip().lower()

    language = sys.argv[3].strip()

    try:
        number_of_songs = int(sys.argv[4])
    except:
        number_of_songs = 10

else:

    user_id = "U001"
    mood = "happy"
    language = "Tamil"
    number_of_songs = 10


if number_of_songs not in [10, 20]:

    number_of_songs = 10


print("=" * 60)
print("MUSIC RECOMMENDATION DASHBOARD API")
print("=" * 60)

print("User ID :", user_id)
print("Mood    :", mood)
print("Language:", language)
print("Songs   :", number_of_songs)

print("=" * 60)


# ============================================================
# RUN HYBRID RECOMMENDER
# ============================================================

try:

    result = subprocess.run(

        [
            sys.executable,
            HYBRID_SCRIPT,
            user_id,
            mood,
            language,
            str(number_of_songs)
        ],

        text=True,

        capture_output=True

    )

    print(result.stdout)

    if result.returncode != 0:

        print(result.stderr)

        sys.exit(1)

except Exception as e:

    print(
        "Hybrid recommender error:",
        e
    )

    sys.exit(1)


# ============================================================
# CHECK HYBRID OUTPUT
# ============================================================

if not os.path.exists(
    HYBRID_OUTPUT
):

    print(
        "Hybrid output file was not created."
    )

    sys.exit(1)


recommendations = pd.read_csv(
    HYBRID_OUTPUT
)


if recommendations.empty:

    pd.DataFrame().to_csv(
        FINAL_OUTPUT,
        index=False
    )

    print(
        "No recommendations found."
    )

    sys.exit(0)


# ============================================================
# RUN EXPLANATION
# ============================================================

try:

    explain_result = subprocess.run(

        [
            sys.executable,
            EXPLAIN_SCRIPT
        ],

        input=(
            user_id
            + "\n"
            + mood
            + "\n"
            + language
            + "\n"
        ),

        text=True,

        capture_output=True

    )

    print(
        explain_result.stdout
    )

except Exception as e:

    print(
        "Explanation generation skipped:",
        e
    )


# ============================================================
# READ EXPLANATIONS
# ============================================================

if os.path.exists(
    EXPLAIN_OUTPUT
):

    try:

        explanations = pd.read_csv(
            EXPLAIN_OUTPUT
        )

        if (
            len(explanations)
            ==
            len(recommendations)
        ):

            if "explanation" in explanations.columns:

                recommendations[
                    "explanation"
                ] = explanations[
                    "explanation"
                ].astype(str)

    except Exception as e:

        print(
            "Explanation file could not be loaded:",
            e
        )


# ============================================================
# ADD DASHBOARD INFORMATION
# ============================================================

recommendations[
    "user_id"
] = user_id

recommendations[
    "selected_mood"
] = mood

recommendations[
    "selected_language"
] = language

recommendations[
    "requested_count"
] = number_of_songs


# ============================================================
# FINAL LANGUAGE SAFETY CHECK
# ============================================================

if language.lower() != "all":

    if "language_clean" in recommendations.columns:

        recommendations = recommendations[
            recommendations[
                "language_clean"
            ]
            .astype(str)
            .str.strip()
            .str.lower()
            ==
            language.strip().lower()
        ].copy()


# ============================================================
# LIMIT NUMBER
# ============================================================

recommendations = recommendations.head(
    number_of_songs
)


# ============================================================
# SAVE FINAL OUTPUT
# ============================================================

recommendations.to_csv(
    FINAL_OUTPUT,
    index=False
)


# ============================================================
# RESULT
# ============================================================

print("\n" + "=" * 60)

print("DASHBOARD RECOMMENDATIONS READY")

print("=" * 60)

print(
    "Language:",
    language
)

print(
    "Requested:",
    number_of_songs
)

print(
    "Returned:",
    len(recommendations)
)

print(
    "\nSaved:"
)

print(
    FINAL_OUTPUT
)

print("=" * 60)