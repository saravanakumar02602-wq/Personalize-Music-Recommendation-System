# Music Recommendation System

A music discovery project combining a Python recommendation toolkit with an R Shiny dashboard. Explore a song catalogue and generate content-based, mood-based, collaborative, hybrid, explainable, user-profile, and trending recommendations.

## Features

- Content-based recommendations built from song and audio features.
- Mood-based and collaborative recommendation workflows.
- Hybrid recommendations that combine multiple approaches.
- Explanations for recommendations, user profiles, and trending-song discovery.
- An interactive Shiny dashboard and a Python command-line menu.
- Tamil and English music support in the supplied catalogue.

## Technology

- Python 3
- R and the `shiny` package
- pandas, NumPy, scikit-learn, matplotlib, seaborn, joblib, and Flask

## Project structure

| Path | Purpose |
| --- | --- |
| `data/` | Source datasets and the prepared song catalogue |
| `python/` | Data preparation, recommendation workflows, and CLI menu |
| `r/` | R analysis, visualizations, and Shiny dashboard |
| `models/` | Generated feature artifacts used by recommendation workflows |
| `outputs/` | Generated analyses, recommendations, and user-profile data |
| `tests/` | Placeholder test files; automated tests have not been implemented yet |
| `requirements.txt` | Python dependencies |
| `run.py` | Python application launcher |

## Getting started

Commands below use Windows PowerShell. Run them from the project directory.

### 1. Set up Python

Create a virtual environment and install the dependencies:

```powershell
py -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
```

### 2. Prepare the catalogue and model artifacts

The project uses `data/master_songs.csv` as its prepared catalogue. If that file is missing, recreate it from the source datasets:

```powershell
.\.venv\Scripts\python.exe python\01_prepare_data.py
```

Generate the feature artifacts required by the content-based recommender:

```powershell
.\.venv\Scripts\python.exe python\03_preprocess_features.py
```

### 3. Run the Python menu

```powershell
.\.venv\Scripts\python.exe run.py
```

Choose an option in the menu to launch a recommendation workflow. To run a workflow directly, for example:

```powershell
.\.venv\Scripts\python.exe python\07_hybrid_recommender.py
```

### 4. Run the Shiny dashboard

Install R and the `shiny` package if needed:

```powershell
Rscript -e "install.packages('shiny', repos='https://cloud.r-project.org')"
```

Start the dashboard:

```powershell
Rscript -e "shiny::runApp('r/dashboard.R', host='127.0.0.1', port=6399, launch.browser=TRUE)"
```

If the browser does not open automatically, visit <http://127.0.0.1:6399/>. Keep the PowerShell window open while using the dashboard; press `Ctrl+C` there to stop it. The dashboard uses `data/master_songs.csv` and can use recommendation files in `outputs/` when they have been generated.

If `Rscript` is not recognized, install R or invoke `Rscript.exe` using its full path. The dashboard locates the project from its own script path, so it does not require a machine-specific project directory.

## Data and generated files

The supplied data files are:

- `data/spotify_tracks.csv`
- `data/Tamil_songs.csv`
- `data/master_songs.csv` — the prepared catalogue used by the dashboard and recommendation workflows

`python/01_prepare_data.py` rebuilds the prepared catalogue from the two source files. Python and R workflows create analysis, recommendation, chart, model, and user-profile files in `outputs/` and `models/`. These artifacts can be regenerated and are intentionally excluded from the recommended GitHub upload; user-profile and interaction files may also contain local user data.

## Uploading this project to GitHub

For a clean repository, upload the project source and setup files:

- `README.md`, `.gitignore`, `requirements.txt`, and `run.py`
- `python/` and `r/`
- `data/` only if you have permission to redistribute every included dataset
- `tests/` if you intend to keep the placeholder test files
- `r/file.jpe` only if it is an intentional project asset

Do **not** upload:

- `.venv/` or any other local virtual environment
- `.RData` or `.Rhistory`
- Generated files from `outputs/` or `models/`
- The root-level `run` file: it contains a command with a local absolute path and is not a portable launcher
- Secrets, private data, or personal user-interaction/profile files

The CSV files in `data/` are needed to reproduce the project locally. Before publishing them, check their source terms, license, and redistribution permissions. If you cannot redistribute a dataset, leave it out and document how users can obtain it lawfully. GitHub repositories do not have an open-source license by default; add a `LICENSE` file before granting others permission to reuse your code.

## Python modules

| Module | Purpose |
| --- | --- |
| `python/01_prepare_data.py` | Prepare the combined song catalogue |
| `python/02_explore_data.py` | Explore the input data |
| `python/03_preprocess_features.py` | Generate model feature artifacts |
| `python/04_content_recommender.py` | Content-based recommendations |
| `python/05_mood_recommender.py` | Mood-based recommendations |
| `python/06_collaborative_recommender.py` | Collaborative recommendations |
| `python/07_hybrid_recommender.py` | Hybrid recommendations |
| `python/08_explain_recommendation.py` | Generate recommendation explanations |
| `python/09_user_profile.py` | User profile workflows |
| `python/10_trending_recommender.py` | Trending and new-song discovery |
| `python/11_dashboard_api.py` | Generate recommendation data for the dashboard |
| `python/app.py` | Interactive command-line menu |

## Troubleshooting

- **`Rscript` is not recognized:** Install R or use the full path to `Rscript.exe`.
- **The browser reports `ERR_CONNECTION_REFUSED`:** Start the Shiny app in PowerShell and leave that process running.
- **Shiny is missing:** Run the `install.packages('shiny', ...)` command above.
- **`master_songs.csv` is missing:** Run `python\01_prepare_data.py` after installing the Python dependencies.
- **Model files are missing:** Run `python\03_preprocess_features.py` to regenerate them.
- **Recommendation output is missing:** Run the relevant Python recommendation workflow; generated output files are not required to be committed.
