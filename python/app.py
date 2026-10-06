import os
import sys
import subprocess


# ============================================================
# MUSIC RECOMMENDATION SYSTEM
# MAIN APPLICATION
# ============================================================

BASE_DIR = os.path.dirname(
    os.path.dirname(os.path.abspath(__file__))
)

PYTHON_DIR = os.path.join(BASE_DIR, "python")


# ============================================================
# HELPER FUNCTION
# ============================================================

def run_module(file_name):
    """
    Run another Python recommendation module.
    """

    file_path = os.path.join(
        PYTHON_DIR,
        file_name
    )

    if not os.path.exists(file_path):

        print("\nModule not found:")
        print(file_path)

        input("\nPress Enter to continue...")
        return

    print("\nStarting:", file_name)
    print("-" * 60)

    try:

        result = subprocess.run(
            [sys.executable, file_path],
            cwd=BASE_DIR
        )

        if result.returncode != 0:

            print(
                "\nThe module finished with an error."
            )

    except Exception as error:

        print(
            "\nError while running module:"
        )

        print(error)

    input("\nPress Enter to continue...")


# ============================================================
# SYSTEM INFORMATION
# ============================================================

def show_system_info():

    print("\n")
    print("=" * 70)
    print("          MUSIC RECOMMENDATION SYSTEM")
    print("=" * 70)

    print("\nSystem Features")
    print("------------------------------")

    print("1. Content-Based Recommendation")
    print("2. Mood-Based Recommendation")
    print("3. Collaborative Recommendation")
    print("4. Hybrid Recommendation")
    print("5. Explainable Recommendation")
    print("6. User Profile Management")
    print("7. Trending Song Discovery")
    print("8. New Song Discovery")
    print("9. Tamil and English Music Support")

    print("\nRecommendation Architecture")
    print("------------------------------")

    print(
        "Content + Mood + Collaborative"
    )

    print(
        "              ↓"
    )

    print(
        "        Hybrid Recommendation"
    )

    print(
        "              ↓"
    )

    print(
        "       Explainable Results"
    )

    print("\n")


# ============================================================
# MAIN MENU
# ============================================================

def main():

    while True:

        print("\n")
        print("=" * 70)
        print("             MUSIC RECOMMENDATION SYSTEM")
        print("=" * 70)

        print("\nMAIN MENU")
        print("-" * 40)

        print("1. Content-Based Recommendation")
        print("2. Mood-Based Recommendation")
        print("3. Collaborative Recommendation")
        print("4. Hybrid Recommendation")
        print("5. Explainable Recommendation")
        print("6. User Profile")
        print("7. Trending Songs")
        print("8. New Songs")
        print("9. System Information")
        print("10. Exit")

        choice = input(
            "\nEnter your choice: "
        ).strip()


        # ====================================================
        # CONTENT RECOMMENDATION
        # ====================================================

        if choice == "1":

            run_module(
                "04_content_recommender.py"
            )


        # ====================================================
        # MOOD RECOMMENDATION
        # ====================================================

        elif choice == "2":

            run_module(
                "05_mood_recommender.py"
            )


        # ====================================================
        # COLLABORATIVE RECOMMENDATION
        # ====================================================

        elif choice == "3":

            run_module(
                "06_collaborative_recommender.py"
            )


        # ====================================================
        # HYBRID RECOMMENDATION
        # ====================================================

        elif choice == "4":

            run_module(
                "07_hybrid_recommender.py"
            )


        # ====================================================
        # EXPLAINABLE RECOMMENDATION
        # ====================================================

        elif choice == "5":

            run_module(
                "08_explain_recommendation.py"
            )


        # ====================================================
        # USER PROFILE
        # ====================================================

        elif choice == "6":

            run_module(
                "09_user_profile.py"
            )


        # ====================================================
        # TRENDING SONGS
        # ====================================================

        elif choice == "7":

            run_module(
                "10_trending_recommender.py"
            )


        # ====================================================
        # NEW SONGS
        # ====================================================

        elif choice == "8":

            run_module(
                "10_trending_recommender.py"
            )


        # ====================================================
        # SYSTEM INFORMATION
        # ====================================================

        elif choice == "9":

            show_system_info()

            input(
                "Press Enter to continue..."
            )


        # ====================================================
        # EXIT
        # ====================================================

        elif choice == "10":

            print("\nThank you for using")
            print("Music Recommendation System!")

            break


        # ====================================================
        # INVALID OPTION
        # ====================================================

        else:

            print(
                "\nInvalid choice."
            )

            print(
                "Please select a number from 1 to 10."
            )


# ============================================================
# PROGRAM START
# ============================================================

if __name__ == "__main__":

    main()