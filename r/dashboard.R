# ============================================================
# MUSICAI PRO - PROFESSIONAL MUSIC RECOMMENDATION DASHBOARD
# R SHINY DASHBOARD
# ============================================================

library(shiny)

# ------------------------------------------------------------
# 1. PROJECT PATH
# ------------------------------------------------------------

dashboard_file <- NULL

for (frame in rev(sys.frames())) {
  frame_file <- frame$ofile

  if (is.character(frame_file) &&
      length(frame_file) == 1 &&
      nzchar(frame_file) &&
      file.exists(frame_file)) {
    dashboard_file <- frame_file
    break
  }
}

if (is.null(dashboard_file) || !nzchar(dashboard_file)) {
  script_arg <- grep(
    "^--file=",
    commandArgs(trailingOnly = FALSE),
    value = TRUE
  )

  if (length(script_arg) > 0) {
    dashboard_file <- sub("^--file=", "", script_arg[[1]])
  }
}

if (is.null(dashboard_file) || !nzchar(dashboard_file)) {
  candidates <- file.path(
    getwd(),
    c("dashboard.R", file.path("r", "dashboard.R"))
  )
  existing_candidate <- candidates[file.exists(candidates)]

  if (length(existing_candidate) > 0) {
    dashboard_file <- existing_candidate[[1]]
  }
}

if (!file.exists(dashboard_file)) {
  stop(
    "Unable to locate dashboard.R; source it by its file path or run it from the project directory.",
    call. = FALSE
  )
}

PROJECT_PATH <- normalizePath(
  file.path(dirname(dashboard_file), ".."),
  winslash = "/",
  mustWork = TRUE
)

MASTER_FILE <- file.path(
  PROJECT_PATH,
  "data",
  "master_songs.csv"
)

HYBRID_FILE <- file.path(
  PROJECT_PATH,
  "outputs",
  "hybrid_recommendations.csv"
)

DASHBOARD_FILE <- file.path(
  PROJECT_PATH,
  "outputs",
  "dashboard_recommendations.csv"
)

# ------------------------------------------------------------
# 2. LOAD DATA
# ------------------------------------------------------------

if (!file.exists(MASTER_FILE)) {
  stop(
    sprintf("master_songs.csv not found at '%s'.", MASTER_FILE),
    call. = FALSE
  )
}

songs <- read.csv(
  MASTER_FILE,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

# ------------------------------------------------------------
# 3. CLEAN DATA
# ------------------------------------------------------------

required_columns <- c(
  "title",
  "artist",
  "language"
)

for (col in required_columns) {
  if (!col %in% names(songs)) {
    songs[[col]] <- ""
  }
}

if (!"popularity" %in% names(songs)) {
  songs$popularity <- 0
}

if (!"year" %in% names(songs)) {
  songs$year <- NA
}

if (!"track_url" %in% names(songs)) {
  songs$track_url <- ""
}

songs$title <- as.character(songs$title)
songs$artist <- as.character(songs$artist)
songs$language <- trimws(as.character(songs$language))
songs$track_url <- as.character(songs$track_url)

songs$popularity <- suppressWarnings(
  as.numeric(songs$popularity)
)

songs$popularity[is.na(songs$popularity)] <- 0

# ------------------------------------------------------------
# 4. LOAD RECOMMENDATION DATA
# ------------------------------------------------------------

if (file.exists(DASHBOARD_FILE)) {

  recommendation_data <- read.csv(
    DASHBOARD_FILE,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

} else if (file.exists(HYBRID_FILE)) {

  recommendation_data <- read.csv(
    HYBRID_FILE,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )

} else {

  recommendation_data <- songs

}

# ------------------------------------------------------------
# 5. PREPARE RECOMMENDATION DATA
# ------------------------------------------------------------

if (!"title" %in% names(recommendation_data)) {
  recommendation_data$title <- ""
}

if (!"artist" %in% names(recommendation_data)) {
  recommendation_data$artist <- ""
}

if (!"language" %in% names(recommendation_data)) {
  recommendation_data$language <- ""
}

if (!"hybrid_score" %in% names(recommendation_data)) {
  recommendation_data$hybrid_score <-
    recommendation_data$popularity
}

if (!"track_url" %in% names(recommendation_data)) {
  recommendation_data$track_url <- ""
}

if (!"mood" %in% names(recommendation_data)) {
  recommendation_data$mood <- "Music"
}

recommendation_data$title <-
  as.character(recommendation_data$title)

recommendation_data$artist <-
  as.character(recommendation_data$artist)

recommendation_data$language <-
  trimws(as.character(recommendation_data$language))

recommendation_data$track_url <-
  as.character(recommendation_data$track_url)

recommendation_data$hybrid_score <-
  suppressWarnings(
    as.numeric(recommendation_data$hybrid_score)
  )

recommendation_data$hybrid_score[
  is.na(recommendation_data$hybrid_score)
] <- 0

# ------------------------------------------------------------
# 6. RECOVER EXACT SPOTIFY LINKS
# ------------------------------------------------------------

if ("song_id" %in% names(recommendation_data) &&
    "song_id" %in% names(songs)) {

  index_match <- match(
    recommendation_data$song_id,
    songs$song_id
  )

  missing_links <-
    is.na(recommendation_data$track_url) |
    recommendation_data$track_url == ""

  recommendation_data$track_url[
    missing_links
  ] <- songs$track_url[
    index_match[missing_links]
  ]
}

audio_features <- intersect(
  c(
    "energy",
    "danceability",
    "valence",
    "acousticness",
    "instrumentalness",
    "speechiness"
  ),
  names(songs)
)

if (length(audio_features) > 0) {
  metadata_match <- if (
    "song_id" %in% names(recommendation_data) &&
    "song_id" %in% names(songs)
  ) {
    match(
      as.character(recommendation_data$song_id),
      as.character(songs$song_id)
    )
  } else {
    match(
      paste(
        tolower(trimws(recommendation_data$title)),
        tolower(trimws(recommendation_data$artist)),
        sep = "::"
      ),
      paste(
        tolower(trimws(songs$title)),
        tolower(trimws(songs$artist)),
        sep = "::"
      )
    )
  }

  for (feature in audio_features) {
    catalog_values <- suppressWarnings(
      as.numeric(songs[[feature]][metadata_match])
    )

    if (feature %in% names(recommendation_data)) {
      values <- suppressWarnings(
        as.numeric(recommendation_data[[feature]])
      )
      missing_values <- !is.finite(values)
      values[missing_values] <- catalog_values[missing_values]
      recommendation_data[[feature]] <- values
    } else {
      recommendation_data[[feature]] <- catalog_values
    }
  }
}

# ------------------------------------------------------------
# 7. LANGUAGE LIST
# ------------------------------------------------------------

available_languages <- sort(
  unique(
    songs$language[
      songs$language != "" &
      !is.na(songs$language)
    ]
  )
)

preferred_languages <- c(
  "Tamil",
  "English",
  "Hindi",
  "Telugu",
  "Malayalam",
  "Korean",
  "Bengali"
)

language_list <- c(
  "All Languages",
  intersect(
    preferred_languages,
    available_languages
  ),
  setdiff(
    available_languages,
    preferred_languages
  )
)

language_list <- unique(language_list)

# ------------------------------------------------------------
# 8. UI
# ------------------------------------------------------------

ui <- fluidPage(

  tags$head(

    tags$title("MusicAI Pro - Smart Music Intelligence"),

    tags$style(HTML("

      /* =====================================================
         GLOBAL
         ===================================================== */

      html, body {
        margin: 0;
        padding: 0;
        background: #07111f;
        color: #f8fafc;
        font-family: 'Segoe UI', Arial, sans-serif;
        font-size: 15px;
      }

      .container-fluid {
        padding: 0;
      }

      * {
        box-sizing: border-box;
      }

      /* =====================================================
         SIDEBAR
         ===================================================== */

      .music-sidebar {
        position: fixed;
        left: 0;
        top: 0;
        bottom: 0;
        width: 245px;
        background:
          linear-gradient(
            180deg,
            #081426 0%,
            #0b1729 50%,
            #07111f 100%
          );
        border-right: 1px solid #1d314a;
        padding: 28px 18px;
        z-index: 1000;
        overflow-y: auto;
      }

      .brand {
        display: flex;
        align-items: center;
        gap: 13px;
        margin-bottom: 35px;
        padding: 0 5px;
      }

      .brand-icon {
        width: 48px;
        height: 48px;
        border-radius: 14px;
        background:
          linear-gradient(
            135deg,
            #16e98a,
            #06b6d4
          );
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 25px;
        box-shadow:
          0 8px 25px rgba(22,233,138,.25);
      }

      .brand-name {
        font-size: 21px;
        font-weight: 800;
        color: white;
        letter-spacing: .2px;
      }

      .brand-sub {
        font-size: 9px;
        color: #7f93ad;
        margin-top: 2px;
        letter-spacing: 1px;
      }

      .side-section {
        margin-top: 24px;
      }

      .side-title {
        color: #627894;
        font-size: 10px;
        font-weight: 800;
        letter-spacing: 1.6px;
        text-transform: uppercase;
        margin: 0 10px 9px;
      }

      .side-link {
        width: 100%;
        border: none;
        background: transparent;
        color: #a9bad0;
        text-align: left;
        padding: 12px 13px;
        margin: 3px 0;
        border-radius: 11px;
        font-size: 14px;
        font-weight: 600;
        cursor: pointer;
      }

      .side-link:hover {
        background: #14263d;
        color: white;
      }

      .side-link.active {
        background:
          linear-gradient(
            90deg,
            rgba(22,233,138,.18),
            rgba(6,182,212,.08)
          );
        color: #ffffff;
        border-left: 3px solid #16e98a;
      }

      .system-status {
        position: absolute;
        left: 18px;
        right: 18px;
        bottom: 20px;
        background: #101f32;
        border: 1px solid #203650;
        border-radius: 14px;
        padding: 14px;
      }

      .status-dot {
        display: inline-block;
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: #16e98a;
        box-shadow: 0 0 12px #16e98a;
        margin-right: 7px;
      }

      .status-text {
        color: #c6d4e5;
        font-size: 11px;
      }

      /* =====================================================
         MAIN
         ===================================================== */

      .main-area {
        margin-left: 245px;
        min-height: 100vh;
        padding: 25px 30px 50px;
        background:
          radial-gradient(
            circle at 80% 0%,
            rgba(31,105,255,.14),
            transparent 35%
          ),
          #07111f;
      }

      /* =====================================================
         TOP BAR
         ===================================================== */

      .topbar {
        height: 60px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 20px;
      }

      .page-title {
        font-size: 13px;
        color: #7f93ad;
        letter-spacing: .8px;
      }

      .page-title strong {
        color: white;
        font-size: 15px;
      }

      .search-box input {
        background: #0d1c2f !important;
        border: 1px solid #263e59 !important;
        border-radius: 30px !important;
        color: white !important;
        height: 42px;
        padding-left: 20px;
      }

      .search-box input::placeholder {
        color: #657c96 !important;
      }

      /* =====================================================
         HERO
         ===================================================== */

      .hero {
        min-height: 240px;
        border-radius: 22px;
        padding: 38px 42px;
        position: relative;
        overflow: hidden;
        margin-bottom: 25px;

        background:
          linear-gradient(
            120deg,
            #12305e 0%,
            #1859a8 45%,
            #4c2e96 100%
          );

        border: 1px solid rgba(255,255,255,.12);

        box-shadow:
          0 20px 60px rgba(0,0,0,.25);
      }

      .hero:before {
        content: '';
        position: absolute;
        width: 330px;
        height: 330px;
        border-radius: 50%;
        right: -100px;
        top: -130px;
        background: rgba(22,233,138,.12);
      }

      .hero:after {
        content: '';
        position: absolute;
        width: 250px;
        height: 250px;
        border-radius: 50%;
        right: 150px;
        bottom: -170px;
        background: rgba(255,255,255,.08);
      }

      .hero-content {
        position: relative;
        z-index: 2;
        max-width: 760px;
      }

      .hero-label {
        color: #8fffe1;
        font-weight: 700;
        font-size: 12px;
        letter-spacing: 2px;
        text-transform: uppercase;
        margin-bottom: 10px;
      }

      .hero h1 {
        margin: 0;
        font-size: 38px;
        line-height: 1.15;
        font-weight: 900;
        color: white;
      }

      .hero h1 span {
        color: #75f7ca;
      }

      .hero p {
        color: #d8e9ff;
        font-size: 15px;
        line-height: 1.7;
        max-width: 680px;
        margin: 14px 0 22px;
      }

      .hero-badge {
        display: inline-block;
        padding: 9px 15px;
        border-radius: 30px;
        background: rgba(255,255,255,.12);
        color: white;
        border: 1px solid rgba(255,255,255,.18);
        font-size: 12px;
        font-weight: 700;
      }

      /* =====================================================
         CONTROL PANEL
         ===================================================== */

      .control-panel {
        background: #0c1b2d;
        border: 1px solid #1e354f;
        border-radius: 18px;
        padding: 23px;
        margin-bottom: 25px;
        box-shadow: 0 12px 35px rgba(0,0,0,.15);
      }

      .section-heading {
        font-size: 18px;
        color: white;
        font-weight: 800;
        margin: 0 0 17px;
      }

      .section-heading span {
        color: #16e98a;
      }

      .control-label {
        color: #91a6bd !important;
        font-size: 11px !important;
        font-weight: 800 !important;
        letter-spacing: .9px;
        text-transform: uppercase;
      }

      .form-control,
      .selectize-input {
        background: #101f32 !important;
        border: 1px solid #29415c !important;
        color: white !important;
        border-radius: 10px !important;
      }

      .selectize-dropdown {
        background: #101f32 !important;
        color: white !important;
        border: 1px solid #29415c !important;
      }

      .selectize-dropdown .option {
        color: white !important;
        padding: 10px;
      }

      .selectize-dropdown .option:hover {
        background: #19314b !important;
      }

      .btn-generate {
        background:
          linear-gradient(
            135deg,
            #16e98a,
            #00c896
          ) !important;
        color: #03130d !important;
        border: none !important;
        border-radius: 11px !important;
        height: 42px;
        font-weight: 900 !important;
        box-shadow: 0 8px 22px rgba(22,233,138,.18);
      }

      .btn-generate:hover {
        transform: translateY(-1px);
        box-shadow: 0 12px 28px rgba(22,233,138,.30);
      }

      /* =====================================================
         MOODS
         ===================================================== */

      .mood-row {
        display: flex;
        gap: 10px;
        flex-wrap: wrap;
        margin-bottom: 25px;
      }

      .mood-choice {
        flex: 1;
        min-width: 100px;
      }

      .mood-choice label {
        display: block;
        width: 100%;
        text-align: center;
        padding: 13px 8px;
        background: #101f32;
        border: 1px solid #243d58;
        border-radius: 12px;
        color: #a7b9cd;
        cursor: pointer;
        font-size: 12px;
        font-weight: 700;
      }

      .mood-choice label:hover {
        border-color: #16e98a;
        color: white;
      }

      /* =====================================================
         KPI
         ===================================================== */

      .kpi-grid {
        display: grid;
        grid-template-columns:
          repeat(4, minmax(0, 1fr));
        gap: 15px;
        margin-bottom: 25px;
      }

      .kpi-card {
        min-height: 125px;
        padding: 20px;
        border-radius: 17px;
        position: relative;
        overflow: hidden;
        border: 1px solid rgba(255,255,255,.08);
        box-shadow: 0 12px 30px rgba(0,0,0,.15);
      }

      .kpi-card.blue {
        background:
          linear-gradient(
            135deg,
            #1262aa,
            #17447b
          );
      }

      .kpi-card.green {
        background:
          linear-gradient(
            135deg,
            #087f67,
            #075443
          );
      }

      .kpi-card.purple {
        background:
          linear-gradient(
            135deg,
            #6840bc,
            #40246f
          );
      }

      .kpi-card.orange {
        background:
          linear-gradient(
            135deg,
            #bd6714,
            #71380c
          );
      }

      .kpi-icon {
        font-size: 21px;
        margin-bottom: 8px;
      }

      .kpi-label {
        color: rgba(255,255,255,.75);
        font-size: 11px;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: .8px;
      }

      .kpi-value {
        color: white;
        font-size: 28px;
        font-weight: 900;
        margin-top: 4px;
      }

      .kpi-small {
        color: rgba(255,255,255,.65);
        font-size: 10px;
        margin-top: 3px;
      }

      /* =====================================================
         CONTENT CARDS
         ===================================================== */

      .panel-card {
        background: #0c1b2d;
        border: 1px solid #1e354f;
        border-radius: 18px;
        padding: 20px;
        margin-bottom: 20px;
        box-shadow: 0 10px 30px rgba(0,0,0,.12);
      }

      .panel-title {
        color: white;
        font-size: 16px;
        font-weight: 800;
        margin-bottom: 15px;
      }

      .panel-subtitle {
        color: #71869f;
        font-size: 11px;
        margin-bottom: 15px;
      }

      /* =====================================================
         SONG CARDS
         ===================================================== */

      .song-grid {
        display: grid;
        grid-template-columns:
          repeat(2, minmax(0, 1fr));
        gap: 13px;
      }

      .song-card {
        background: linear-gradient(
          135deg,
          #101d35 0%,
          #142b49 55%,
          #10233d 100%
        );
        border: 1px solid rgba(0, 229, 255, 0.16);
        border-radius: 18px;
        padding: 22px 24px;
        margin-bottom: 15px;
        min-height: 125px;
        box-shadow: 0 8px 25px rgba(0, 0, 0, 0.28);
        transition: all 0.25s ease;
        position: relative;
      }

      .song-card:hover {
        transform: translateY(-4px);
        border-color: #00e5ff;
        box-shadow: 0 12px 35px rgba(0, 229, 255, 0.18);
      }

      .song-top {
        display: flex;
        gap: 13px;
        align-items: flex-start;
      }

      .song-icon {
        width: 54px;
        height: 54px;
        border-radius: 14px;
        background: linear-gradient(135deg, #1b3d66, #18304e);
        display: flex;
        align-items: center;
        justify-content: center;
        color: #00e5ff;
        font-size: 24px;
        flex-shrink: 0;
      }

      .song-main {
        min-width: 0;
        flex: 1;
      }

      .song-rank {
        color: #00e5ff;
        font-size: 13px;
        font-weight: 800;
        margin-bottom: 6px;
      }

      .song-title {
        color: #ffffff !important;
        font-size: 25px !important;
        font-weight: 800 !important;
        line-height: 1.3 !important;
        margin-top: 4px !important;
        margin-right: 50px;
        margin-bottom: 9px !important;
        overflow-wrap: anywhere;
      }

      .song-artist {
        color: #c5d4e8 !important;
        font-size: 15px !important;
        font-weight: 500 !important;
        line-height: 1.5;
        margin-bottom: 7px;
      }

      .song-meta {
        color: #7895b8 !important;
        font-size: 12px !important;
        font-weight: 600;
      }

      .song-score {
        position: absolute;
        right: 15px;
        top: 15px;
        color: #00f5a0 !important;
        font-size: 21px !important;
        font-weight: 800 !important;
      }

      .score-bar {
        height: 5px;
        background: #1a2b40;
        border-radius: 5px;
        overflow: hidden;
        margin-top: 12px;
      }

      .score-fill {
        height: 100%;
        background:
          linear-gradient(
            90deg,
            #16e98a,
            #00b7ff,
            #9b5cff
          );
        border-radius: 5px;
      }

      .song-actions {
        margin-top: 12px;
        display: flex;
        gap: 7px;
      }

      .spotify-btn {
        display: inline-block;
        padding: 9px 17px !important;
        border-radius: 10px !important;
        background: linear-gradient(135deg, #00d084, #00a86b) !important;
        border: none !important;
        color: #ffffff !important;
        font-size: 12px !important;
        font-weight: 800;
        text-decoration: none !important;
        box-shadow: 0 5px 15px rgba(0, 208, 132, 0.20);
        transition: all 0.2s ease;
      }

      .spotify-btn:hover {
        background: linear-gradient(135deg, #00f5a0, #00c878) !important;
        color: white !important;
        transform: scale(1.04);
      }

      .fav-btn {
        padding: 6px 10px;
        border-radius: 8px;
        border: 1px solid #344d67;
        background: #13243a;
        color: #d3dfeb;
        font-size: 10px;
      }

      .fav-btn.favorited {
        border-color: #16e98a;
        color: #16e98a;
      }

      .modal-content {
        background: #0c1b2d !important;
        color: #f8fafc !important;
        border: 1px solid #1e354f !important;
        border-radius: 14px !important;
        box-shadow: 0 20px 60px rgba(0, 0, 0, 0.45);
      }

      .modal-header,
      .modal-footer {
        border-color: #1e354f !important;
      }

      .modal-title,
      .modal-body,
      .modal-body p,
      .modal-body li,
      .modal-body h4 {
        color: #f8fafc !important;
      }

      .modal-body ul {
        padding-left: 20px;
        margin-bottom: 0;
      }

      .modal-header .close {
        color: #f8fafc;
        opacity: 0.8;
        text-shadow: none;
      }

      .modal-footer .btn {
        background: #16e98a !important;
        color: #03130d !important;
        border: none !important;
        border-radius: 8px !important;
        font-weight: 700;
      }

      /* =====================================================
         AI INTELLIGENCE
         ===================================================== */

      .ai-grid {
        display: grid;
        grid-template-columns:
          repeat(2, minmax(0, 1fr));
        gap: 13px;
      }

      .ai-card {
        background: #101f32;
        border: 1px solid #223b56;
        border-radius: 14px;
        padding: 17px;
        min-height: 120px;
      }

      .ai-icon {
        font-size: 19px;
        margin-bottom: 8px;
      }

      .ai-title {
        color: white;
        font-weight: 800;
        font-size: 13px;
        margin-bottom: 6px;
      }

      .ai-text {
        color: #7990aa;
        font-size: 10px;
        line-height: 1.55;
      }

      /* =====================================================
         CHARTS
         ===================================================== */

      .chart-container {
        background: linear-gradient(155deg, #102239 0%, #0b192a 100%);
        border: 1px solid #29445f;
        border-radius: 12px;
        padding: 22px;
        min-height: 420px;
        margin-bottom: 20px;
        box-shadow: 0 12px 30px rgba(0, 0, 0, .18);
      }

      .chart-title {
        color: white;
        font-size: 16px;
        font-weight: 800;
        margin-bottom: 6px;
      }

      .chart-info {
        color: #a9bad0;
        font-size: 12px;
        line-height: 1.45;
        margin-bottom: 12px;
      }

      .chart-container .shiny-plot-output {
        width: 100% !important;
      }

      /* =====================================================
         TABLE
         ===================================================== */

      .data-table {
        width: 100%;
        border-collapse: collapse;
        color: #dce8f4;
        font-size: 11px;
      }

      .data-table th {
        color: #16e98a;
        background: #101f32;
        padding: 12px;
        text-align: left;
      }

      .data-table td {
        padding: 11px;
        border-bottom: 1px solid #1b3048;
      }

      /* =====================================================
         FOOTER
         ===================================================== */

      .footer {
        text-align: center;
        color: #4f667e;
        font-size: 10px;
        padding: 25px 0 5px;
      }

      /* =====================================================
         RESPONSIVE
         ===================================================== */

      @media(max-width: 1000px) {

        .music-sidebar {
          width: 190px;
        }

        .main-area {
          margin-left: 190px;
        }

        .kpi-grid {
          grid-template-columns:
            repeat(2, 1fr);
        }

        .song-grid {
          grid-template-columns: 1fr;
        }
      }

      @media(max-width: 700px) {

        .music-sidebar {
          position: relative;
          width: 100%;
          height: auto;
        }

        .main-area {
          margin-left: 0;
          padding: 15px;
        }

        .system-status {
          position: relative;
          left: auto;
          right: auto;
          bottom: auto;
          margin-top: 20px;
        }

        .hero h1 {
          font-size: 28px;
        }

        .kpi-grid {
          grid-template-columns: 1fr;
        }

        .ai-grid {
          grid-template-columns: 1fr;
        }
      }

    ")),

    # JavaScript for scrolling/navigation
    tags$script(HTML("

      $(document).on('click', '.scroll-home', function(){
        $('html, body').animate({
          scrollTop: 0
        }, 500);
      });

      $(document).on('click', '.scroll-rec', function(){
        $('html, body').animate({
          scrollTop: $('#recommendations_section').offset().top - 20
        }, 500);
      });

      $(document).on('click', '.scroll-analysis', function(){
        $('html, body').animate({
          scrollTop: $('#analytics_section').offset().top - 20
        }, 500);
      });

      $(document).on('click', '.scroll-ai', function(){
        $('html, body').animate({
          scrollTop: $('#ai_section').offset().top - 20
        }, 500);
      });

      $(document).on('click', '.fav-btn', function(){
        Shiny.setInputValue(
          'favorite_click',
          this.id.replace('fav_', ''),
          {priority: 'event'}
        );
      });

      Shiny.addCustomMessageHandler('click-input', function(inputId){
        window.setTimeout(function(){
          var input = document.getElementById(inputId);
          if (input) input.click();
        }, 150);
      });

    "))

  ),

  # ==========================================================
  # SIDEBAR
  # ==========================================================

  div(
    class = "music-sidebar",

    div(
      class = "brand",

      div(
        class = "brand-icon",
        "♫"
      ),

      div(
        div(
          class = "brand-name",
          "MusicAI Pro"
        ),
        div(
          class = "brand-sub",
          "SMART MUSIC INTELLIGENCE"
        )
      )
    ),

    div(
      class = "side-section",

      div(
        class = "side-title",
        "Workspace"
      ),

      actionButton(
        "home_btn",
        "🏠   Dashboard",
        class = "side-link active scroll-home"
      ),

      actionButton(
        "rec_btn",
        "🎧   Recommendations",
        class = "side-link scroll-rec"
      ),

      actionButton(
        "trend_btn",
        "🔥   Trending Music",
        class = "side-link scroll-rec"
      ),

      actionButton(
        "new_btn",
        "✨   New Music",
        class = "side-link scroll-rec"
      ),

      actionButton(
        "analysis_btn",
        "📊   Analytics",
        class = "side-link scroll-analysis"
      ),

      actionButton(
        "profile_btn",
        "👤   My Profile",
        class = "side-link"
      )
    ),

    div(
      class = "side-section",

      div(
        class = "side-title",
        "AI Engine"
      ),

      div(
        class = "side-link",
        "🧠   Hybrid AI"
      ),

      div(
        class = "side-link",
        "💡   Explainable AI"
      ),

      div(
        class = "side-link",
        "🎭   Mood Intelligence"
      ),

      div(
        class = "side-link",
        "🌍   Language Intelligence"
      )
    ),

    div(
      class = "system-status",

      div(
        span(class = "status-dot"),
        span(
          class = "status-text",
          "Recommendation engine online"
        )
      ),

      div(
        style = "color:#526a83;font-size:9px;margin-top:7px;",
        "MusicAI Pro • R Shiny"
      )
    )
  ),

  # ==========================================================
  # MAIN
  # ==========================================================

  div(
    class = "main-area",

    # --------------------------------------------------------
    # TOP BAR
    # --------------------------------------------------------

    div(
      class = "topbar",

      div(
        class = "page-title",
        HTML(
          "<strong>AI Music Discovery</strong>
           &nbsp; / &nbsp; Personalized Dashboard"
        )
      ),

      div(
        class = "search-box",
        style = "width:300px;",
        textInput(
          "song_search",
          NULL,
          placeholder = "🔎  Search recommended songs..."
        )
      )
    ),

    # --------------------------------------------------------
    # HERO
    # --------------------------------------------------------

    div(
      class = "hero",

      div(
        class = "hero-content",

        div(
          class = "hero-label",
          "✦ AI POWERED MUSIC DISCOVERY"
        ),

        h1(
          "Discover Music ",
          span("Made For You"),
          " 🎧"
        ),

        p(
          "MusicAI Pro combines content similarity, mood intelligence, ",
          "collaborative preferences and language-aware recommendation ",
          "to create a personalized music discovery experience."
        ),

        span(
          class = "hero-badge",
          "⚡ Hybrid Recommendation Engine"
        ),

        span(
          class = "hero-badge",
          style = "margin-left:8px;",
          "🌍 Multi-Language Music"
        )
      )
    ),

    # --------------------------------------------------------
    # QUICK START
    # --------------------------------------------------------

    div(
      class = "control-panel",

      h2(
        class = "section-heading",
        "⚡ Quick Start ",
        span("•")
      ),

      div(
        class = "row",

        div(
          class = "col-md-4",

          selectInput(
            "language",
            "Language",
            choices = language_list,
            selected = "Tamil"
          )
        ),

        div(
          class = "col-md-3",

          selectInput(
            "mood",
            "Mood",
            choices = c(
              "All Moods",
              "Happy",
              "Sad",
              "Romantic",
              "Energetic",
              "Relaxed"
            ),
            selected = "All Moods"
          )
        ),

        div(
          class = "col-md-2",

          numericInput(
            "song_count",
            "Number of Recommendations",
            value = 10,
            min = 1,
            max = 1000,
            step = 1
          )
        ),

        div(
          class = "col-md-3",

          selectInput(
            "engine",
            "Recommendation Engine",
            choices = c(
              "Hybrid AI",
              "Content Based",
              "Mood Based",
              "Trending",
              "New Music"
            ),
            selected = "Hybrid AI"
          )
        )
      ),

      div(
        class = "row",

        div(
          class = "col-md-12",

          actionButton(
            "generate",
            "✨  Generate My Recommendations",
            class = "btn-generate",
            width = "100%"
          )
        )
      )
    ),

    # --------------------------------------------------------
    # MOOD SECTION
    # --------------------------------------------------------

    div(
      class = "panel-card",

      div(
        class = "panel-title",
        "🎭 How are you feeling today?"
      ),

      div(
        class = "panel-subtitle",
        "Choose a mood to personalize your music discovery."
      ),

      div(
        class = "mood-row",

        div(
          class = "mood-choice",
          actionButton(
            "happy_mood",
            "😊 Happy",
            width = "100%"
          )
        ),

        div(
          class = "mood-choice",
          actionButton(
            "sad_mood",
            "😔 Sad",
            width = "100%"
          )
        ),

        div(
          class = "mood-choice",
          actionButton(
            "romantic_mood",
            "❤️ Romantic",
            width = "100%"
          )
        ),

        div(
          class = "mood-choice",
          actionButton(
            "energetic_mood",
            "⚡ Energetic",
            width = "100%"
          )
        ),

        div(
          class = "mood-choice",
          actionButton(
            "relaxed_mood",
            "🌿 Relaxed",
            width = "100%"
          )
        )
      )
    ),

    # --------------------------------------------------------
    # KPI
    # --------------------------------------------------------

    uiOutput("kpi_section"),

    # --------------------------------------------------------
    # RECOMMENDATIONS
    # --------------------------------------------------------

    div(
      id = "recommendations_section",

      div(
        class = "panel-card",

        div(
          class = "panel-title",
          "🎵 Recommended For You"
        ),

        div(
          class = "panel-subtitle",
          textOutput(
            "recommendation_summary",
            inline = TRUE
          )
        ),

        uiOutput("song_cards")
      )
    ),

    # --------------------------------------------------------
    # ANALYTICS
    # --------------------------------------------------------

    div(
      id = "analytics_section",

      div(
        class = "row",

        div(
          class = "col-md-6",

          div(
            class = "chart-container",

            div(
              class = "chart-title",
              "📊 Recommendation Score"
            ),

            div(
              class = "chart-info",
              "Recommendations grouped by score range"
            ),

            plotOutput(
              "score_chart",
              height = "360px"
            )
          )
        ),

        div(
          class = "col-md-6",

          div(
            class = "chart-container",

            div(
              class = "chart-title",
              "🎧 Audio Profile"
            ),

            div(
              class = "chart-info",
              "Average audio profile on a 0 to 1 scale"
            ),

            plotOutput(
              "audio_chart",
              height = "360px"
            )
          )
        )
      ),

      div(
        class = "row",

        div(
          class = "col-md-6",

          div(
            class = "chart-container",

            div(
              class = "chart-title",
              "🌍 Language Distribution"
            ),

            div(
              class = "chart-info",
              "Share of recommendations by language"
            ),

            plotOutput(
              "language_chart",
              height = "340px"
            )
          )
        ),

        div(
          class = "col-md-6",

          div(
            class = "chart-container",

            div(
              class = "chart-title",
              "⭐ Popularity Analysis"
            ),

            div(
              class = "chart-info",
              "Songs grouped by popularity range"
            ),

            plotOutput(
              "popularity_chart",
              height = "340px"
            )
          )
        )
      )
    ),

    # --------------------------------------------------------
    # AI INTELLIGENCE
    # --------------------------------------------------------

    div(
      id = "ai_section",

      div(
        class = "panel-card",

        div(
          class = "panel-title",
          "🧠 Recommendation Intelligence"
        ),

        div(
          class = "panel-subtitle",
          "How MusicAI Pro creates personalized recommendations."
        ),

        div(
          class = "ai-grid",

          div(
            class = "ai-card",

            div(
              class = "ai-icon",
              "🎯"
            ),

            div(
              class = "ai-title",
              "Content Intelligence"
            ),

            div(
              class = "ai-text",
              "Compares musical characteristics such as energy, ",
              "danceability, valence, acousticness and speechiness ",
              "to identify songs with similar audio profiles."
            )
          ),

          div(
            class = "ai-card",

            div(
              class = "ai-icon",
              "😊"
            ),

            div(
              class = "ai-title",
              "Mood Intelligence"
            ),

            div(
              class = "ai-text",
              "Matches songs against the selected emotional profile ",
              "using audio characteristics associated with Happy, ",
              "Sad, Romantic, Energetic and Relaxed moods."
            )
          ),

          div(
            class = "ai-card",

            div(
              class = "ai-icon",
              "👥"
            ),

            div(
              class = "ai-title",
              "Collaborative Intelligence"
            ),

            div(
              class = "ai-text",
              "Uses user preference patterns and similar listening ",
              "behavior to identify songs that may be relevant to ",
              "the current listener."
            )
          ),

          div(
            class = "ai-card",

            div(
              class = "ai-icon",
              "🌍"
            ),

            div(
              class = "ai-title",
              "Language Intelligence"
            ),

            div(
              class = "ai-text",
              "Applies strict language filtering so that the displayed ",
              "recommendations match the selected language."
            )
          )
        )
      )
    ),

    # --------------------------------------------------------
    # SYSTEM OVERVIEW
    # --------------------------------------------------------

    div(
      class = "panel-card",

      div(
        class = "panel-title",
        "⚙️ MusicAI System Architecture"
      ),

      div(
        class = "panel-subtitle",
        "Recommendation pipeline used by the project."
      ),

      div(
        class = "row",

        div(
          class = "col-md-3",
          div(
            class = "ai-card",
            div(class = "ai-icon", "📥"),
            div(class = "ai-title", "User Input"),
            div(
              class = "ai-text",
              "Language, mood, recommendation count and user preferences."
            )
          )
        ),

        div(
          class = "col-md-3",
          div(
            class = "ai-card",
            div(class = "ai-icon", "🎵"),
            div(class = "ai-title", "Content Analysis"),
            div(
              class = "ai-text",
              "Audio features and song characteristics are analyzed."
            )
          )
        ),

        div(
          class = "col-md-3",
          div(
            class = "ai-card",
            div(class = "ai-icon", "🧠"),
            div(class = "ai-title", "Hybrid AI"),
            div(
              class = "ai-text",
              "Content, mood and collaborative scores are combined."
            )
          )
        ),

        div(
          class = "col-md-3",
          div(
            class = "ai-card",
            div(class = "ai-icon", "🎧"),
            div(class = "ai-title", "Final Recommendation"),
            div(
              class = "ai-text",
              "Personalized songs are displayed with Spotify access."
            )
          )
        )
      )
    ),

    # --------------------------------------------------------
    # FOOTER
    # --------------------------------------------------------

    div(
      class = "footer",
      "MusicAI Pro • Music Recommendation System • R Shiny Professional Dashboard • Hybrid AI"
    )
  )
)

# ============================================================
# SERVER
# ============================================================

server <- function(input, output, session) {

  # ----------------------------------------------------------
  # REACTIVE RECOMMENDATIONS
  # ----------------------------------------------------------

  current_recommendations <- reactiveVal(
    recommendation_data[
      seq_len(min(10, nrow(recommendation_data))),
      ,
      drop = FALSE
    ]
  )

  favorite_songs <- reactiveVal(
    data.frame(
      key = character(),
      title = character(),
      artist = character(),
      language = character(),
      stringsAsFactors = FALSE
    )
  )

  # ----------------------------------------------------------
  # MOOD BUTTONS
  # ----------------------------------------------------------

  observeEvent(input$happy_mood, {
    updateSelectInput(
      session,
      "mood",
      selected = "Happy"
    )
  })

  observeEvent(input$sad_mood, {
    updateSelectInput(
      session,
      "mood",
      selected = "Sad"
    )
  })

  observeEvent(input$romantic_mood, {
    updateSelectInput(
      session,
      "mood",
      selected = "Romantic"
    )
  })

  observeEvent(input$energetic_mood, {
    updateSelectInput(
      session,
      "mood",
      selected = "Energetic"
    )
  })

  observeEvent(input$relaxed_mood, {
    updateSelectInput(
      session,
      "mood",
      selected = "Relaxed"
    )
  })

  # ----------------------------------------------------------
  # GENERATE RECOMMENDATIONS
  # ----------------------------------------------------------

  observeEvent(input$generate, {

    req(input$song_count)

    count <- as.integer(input$song_count)

    if (is.na(count) || count < 1) {
      count <- 10
    }

    selected_language <- input$language
    selected_mood <- input$mood
    selected_engine <- input$engine

    data <- recommendation_data

    # --------------------------------------------------------
    # STRICT LANGUAGE FILTER
    # --------------------------------------------------------

    if (selected_language != "All Languages") {

      data <- data[
        tolower(trimws(data$language)) ==
          tolower(trimws(selected_language)),
        ,
        drop = FALSE
      ]
    }

    # --------------------------------------------------------
    # MOOD-BASED AUDIO FEATURE RANKING
    # --------------------------------------------------------

    if (selected_mood != "All Moods") {

      mood_profiles <- list(
        "Happy" = c(energy = 0.75, danceability = 0.75, valence = 0.85),
        "Sad" = c(energy = 0.30, danceability = 0.35, valence = 0.25),
        "Romantic" = c(energy = 0.45, danceability = 0.50, valence = 0.65),
        "Energetic" = c(energy = 0.90, danceability = 0.85, valence = 0.75),
        "Relaxed" = c(energy = 0.35, danceability = 0.40, valence = 0.55)
      )

      target_profile <- mood_profiles[[selected_mood]]
      data <- songs

      if (selected_language != "All Languages") {
        data <- data[
          tolower(trimws(data$language)) ==
            tolower(trimws(selected_language)),
          ,
          drop = FALSE
        ]
      }

      mood_features <- c(
        "energy",
        "danceability",
        "valence"
      )

      for (feature in mood_features) {
        values <- suppressWarnings(
          as.numeric(data[[feature]])
        )
        valid_values <- values[is.finite(values)]
        fallback <- if (length(valid_values) > 0) {
          median(valid_values)
        } else {
          0.5
        }
        values[!is.finite(values)] <- fallback
        data[[feature]] <- pmin(pmax(values, 0), 1)
      }

      feature_matrix <- as.matrix(
        data[, mood_features, drop = FALSE]
      )
      mood_distance <- sqrt(
        rowSums(
          sweep(feature_matrix, 2, target_profile, "-")^2
        )
      )
      data$mood_score <- 100 / (1 + 2 * mood_distance)

      popularity <- suppressWarnings(
        as.numeric(data$popularity)
      )
      popularity[!is.finite(popularity)] <- 0
      max_popularity <- max(popularity, 0)
      popularity_score <- if (max_popularity > 0) {
        popularity / max_popularity * 100
      } else {
        rep(0, nrow(data))
      }

      data$hybrid_score <-
        data$mood_score * 0.75 + popularity_score * 0.25
      data$mood <- selected_mood
    }

    # --------------------------------------------------------
    # IF RECOMMENDATION FILE DOES NOT HAVE ENOUGH DATA
    # GET DATA FROM MASTER DATASET
    # --------------------------------------------------------

    if (nrow(data) < count) {

      master_data <- songs

      if (
        selected_language != "All Languages"
      ) {

        master_data <- master_data[
          tolower(trimws(master_data$language)) ==
            tolower(trimws(selected_language)),
          ,
          drop = FALSE
        ]
      }

      # remove duplicate titles
      master_data <- master_data[
        !duplicated(
          tolower(
            trimws(master_data$title)
          )
        ),
        ,
        drop = FALSE
      ]

      if (nrow(master_data) > 0) {

        master_data$hybrid_score <-
          master_data$popularity

        master_data$mood <-
          ifelse(
            selected_mood == "All Moods",
            "Music",
            selected_mood
          )

        data <- rbind(
          data,
          master_data
        )
      }
    }

    # --------------------------------------------------------
    # REMOVE DUPLICATES
    # --------------------------------------------------------

    data <- data[
      !duplicated(
        paste(
          tolower(trimws(data$title)),
          tolower(trimws(data$artist))
        )
      ),
      ,
      drop = FALSE
    ]

    # --------------------------------------------------------
    # SORT
    # --------------------------------------------------------

    if (selected_mood != "All Moods") {

      data$display_score <- data$hybrid_score

      data <- data[
        order(
          data$hybrid_score,
          decreasing = TRUE
        ),
        ,
        drop = FALSE
      ]

    } else if (
      selected_engine == "Content Based" &&
      "content_score" %in% names(data)
    ) {

      content_scores <- suppressWarnings(
        as.numeric(data$content_score)
      )
      data$display_score <- content_scores

      data <- data[
        order(
          content_scores,
          decreasing = TRUE,
          na.last = TRUE
        ),
        ,
        drop = FALSE
      ]

    } else if (
      selected_engine == "Mood Based" &&
      "mood_score" %in% names(data)
    ) {

      mood_scores <- suppressWarnings(
        as.numeric(data$mood_score)
      )
      data$display_score <- mood_scores

      data <- data[
        order(
          mood_scores,
          decreasing = TRUE,
          na.last = TRUE
        ),
        ,
        drop = FALSE
      ]

    } else if (
      selected_engine == "Trending" &&
      "popularity" %in% names(data)
    ) {

      data$display_score <- suppressWarnings(
        as.numeric(data$popularity)
      )

      data <- data[
        order(
          data$popularity,
          decreasing = TRUE
        ),
        ,
        drop = FALSE
      ]

    } else if (
      selected_engine == "New Music" &&
      "year" %in% names(data)
    ) {

      year_numeric <-
        suppressWarnings(
          as.numeric(data$year)
        )
      data$display_score <- data$hybrid_score

      data <- data[
        order(
          year_numeric,
          decreasing = TRUE,
          na.last = TRUE
        ),
        ,
        drop = FALSE
      ]

    } else {

      data$display_score <- data$hybrid_score

      data <- data[
        order(
          data$hybrid_score,
          decreasing = TRUE
        ),
        ,
        drop = FALSE
      ]
    }

    # --------------------------------------------------------
    # FINAL LIMIT
    # --------------------------------------------------------

    count <- min(
      count,
      nrow(data)
    )

    if (count > 0) {

      data <- data[
        seq_len(count),
        ,
        drop = FALSE
      ]
    }

    # --------------------------------------------------------
    # FINAL LANGUAGE SECURITY CHECK
    # --------------------------------------------------------

    if (
      selected_language != "All Languages" &&
      nrow(data) > 0
    ) {

      data <- data[
        tolower(trimws(data$language)) ==
          tolower(trimws(selected_language)),
        ,
        drop = FALSE
      ]
    }

    current_recommendations(data)
  })

  # ----------------------------------------------------------
  # SEARCH FILTER
  # ----------------------------------------------------------

  searched_recommendations <- reactive({

    data <- current_recommendations()

    query <- trimws(
      tolower(
        input$song_search
      )
    )

    if (
      query == "" ||
      nrow(data) == 0
    ) {
      return(data)
    }

    text_data <- paste(
      tolower(data$title),
      tolower(data$artist),
      tolower(data$language)
    )

    data[
      grepl(
        query,
        text_data,
        fixed = TRUE
      ),
      ,
      drop = FALSE
    ]
  })

  observeEvent(input$favorite_click, {
    index <- suppressWarnings(
      as.integer(input$favorite_click)
    )
    data <- searched_recommendations()

    req(
      !is.na(index),
      index >= 1,
      index <= nrow(data)
    )

    row <- data[index, , drop = FALSE]
    song_id <- if ("song_id" %in% names(row)) {
      as.character(row$song_id[1])
    } else {
      ""
    }
    key <- if (!is.na(song_id) && nzchar(song_id)) {
      song_id
    } else {
      paste(row$title[1], row$artist[1], sep = "::")
    }

    saved <- favorite_songs()
    if (key %in% saved$key) {
      saved <- saved[saved$key != key, , drop = FALSE]
    } else {
      saved <- rbind(
        saved,
        data.frame(
          key = key,
          title = as.character(row$title[1]),
          artist = as.character(row$artist[1]),
          language = as.character(row$language[1]),
          stringsAsFactors = FALSE
        )
      )
    }

    favorite_songs(saved)
  }, ignoreInit = TRUE)

  # ----------------------------------------------------------
  # KPI SECTION
  # ----------------------------------------------------------

  output$kpi_section <- renderUI({

    data <- current_recommendations()

    total_songs <- nrow(data)
    scores <- if ("display_score" %in% names(data)) {
      suppressWarnings(as.numeric(data$display_score))
    } else {
      suppressWarnings(as.numeric(data$hybrid_score))
    }
    scores[!is.finite(scores)] <- 0

    score_label <- switch(
      input$engine,
      "Content Based" = "Average Content Score",
      "Mood Based" = "Average Mood Score",
      "Trending" = "Average Popularity Score",
      "New Music" = "Average Match Score",
      "Average Hybrid Score"
    )

    avg_score <- if (
      total_songs > 0
    ) {
      mean(scores)
    } else {
      0
    }

    top_score <- if (
      total_songs > 0
    ) {
      max(scores)
    } else {
      0
    }

    languages <- length(
      unique(
        data$language[
          data$language != ""
        ]
      )
    )

    div(
      class = "kpi-grid",

      div(
        class = "kpi-card blue",

        div(
          class = "kpi-icon",
          "🎵"
        ),

        div(
          class = "kpi-label",
          "Recommendations"
        ),

        div(
          class = "kpi-value",
          total_songs
        ),

        div(
          class = "kpi-small",
          "Current result set"
        )
      ),

      div(
        class = "kpi-card green",

        div(
          class = "kpi-icon",
          "⚡"
        ),

        div(
          class = "kpi-label",
          score_label
        ),

        div(
          class = "kpi-value",
          sprintf(
            "%.1f",
            avg_score
          )
        ),

        div(
          class = "kpi-small",
          "Hybrid recommendation score"
        )
      ),

      div(
        class = "kpi-card purple",

        div(
          class = "kpi-icon",
          "🏆"
        ),

        div(
          class = "kpi-label",
          "Top Score"
        ),

        div(
          class = "kpi-value",
          sprintf(
            "%.1f",
            top_score
          )
        ),

        div(
          class = "kpi-small",
          "Highest ranked song"
        )
      ),

      div(
        class = "kpi-card orange",

        div(
          class = "kpi-icon",
          "🌍"
        ),

        div(
          class = "kpi-label",
          "Languages"
        ),

        div(
          class = "kpi-value",
          languages
        ),

        div(
          class = "kpi-small",
          "Current recommendation set"
        )
      )
    )
  })

  # ----------------------------------------------------------
  # RECOMMENDATION SUMMARY
  # ----------------------------------------------------------

  output$recommendation_summary <- renderText({

    data <- current_recommendations()

    language_text <- input$language
    mood_text <- input$mood

    paste0(
      nrow(data),
      " songs • ",
      language_text,
      " • ",
      mood_text,
      " • ",
      input$engine,
      " engine"
    )
  })

  # ----------------------------------------------------------
  # SONG CARDS
  # ----------------------------------------------------------

  output$song_cards <- renderUI({

    data <- searched_recommendations()
    saved_favorites <- favorite_songs()

    if (nrow(data) == 0) {

      return(
        div(
          style = "
            padding:40px;
            text-align:center;
            color:#7d91a8;
          ",
          h3(
            "No songs found"
          ),
          p(
            "Try another language, mood or search term."
          )
        )
      )
    }

    cards <- lapply(
      seq_len(nrow(data)),
      function(i) {

        row <- data[i, ]

        song_id <- if ("song_id" %in% names(row)) {
          as.character(row$song_id[1])
        } else {
          ""
        }
        favorite_key <- if (!is.na(song_id) && nzchar(song_id)) {
          song_id
        } else {
          paste(row$title[1], row$artist[1], sep = "::")
        }
        is_favorite <- favorite_key %in% saved_favorites$key

        score <- suppressWarnings(as.numeric(
          if ("display_score" %in% names(row)) {
            row$display_score
          } else {
            row$hybrid_score
          }
        ))

        if (is.na(score)) {
          score <- 0
        }

        score <- max(
          0,
          min(
            100,
            score
          )
        )

        title <- as.character(
          row$title
        )

        artist <- as.character(
          row$artist
        )

        language <- as.character(
          row$language
        )

        mood_value <- if (
          "mood" %in% names(row)
        ) {
          as.character(
            row$mood
          )
        } else {
          "Music"
        }

        spotify_url <- ""

        if (
          "track_url" %in% names(row)
        ) {

          spotify_url <-
            as.character(
              row$track_url
            )
        }

        spotify_button <- NULL

        if (
          !is.na(spotify_url) &&
          spotify_url != "" &&
          grepl(
            "spotify.com",
            spotify_url,
            fixed = TRUE
          )
        ) {

          spotify_button <- tags$a(
            href = spotify_url,
            target = "_blank",
            class = "spotify-btn",
            "▶ Open Exact Song"
          )
        }

        div(
          class = "song-card",

          div(
            class = "song-top",

            div(
              class = "song-icon",
              "♫"
            ),

            div(
              class = "song-main",

              div(
                class = "song-rank",
                sprintf("#%02d", i)
              ),

              div(
                class = "song-title",
                title
              ),

              div(
                class = "song-artist",
                artist
              ),

              div(
                class = "song-meta",

                paste0(
                  "🌍 ",
                  language,
                  "   •   🎭 ",
                  mood_value
                )
              )
            )
          ),

          div(
            class = "song-score",
            paste0(
              round(score, 1),
              "%"
            )
          ),

          div(
            class = "score-bar",

            div(
              class = "score-fill",
              style = paste0(
                "width:",
                score,
                "%;"
              )
            )
          ),

          div(
            class = "song-actions",

            spotify_button,

            actionButton(
              paste0(
                "fav_",
                i
              ),
              if (is_favorite) "♥ Saved" else "♡ Favorite",
              class = if (is_favorite) {
                "fav-btn favorited"
              } else {
                "fav-btn"
              }
            )
          )
        )
      }
    )

    div(
      class = "song-grid",
      cards
    )
  })

  draw_bars <- function(values, labels, sort_values = FALSE) {
    values <- suppressWarnings(as.numeric(values))
    labels <- as.character(labels)
    keep <- is.finite(values) & values > 0
    values <- values[keep]
    labels <- labels[keep]

    if (length(values) == 0) {
      plot.new()
      text(0.5, 0.5, "No chart data", col = "#a9bad0", cex = 1)
      return(invisible(NULL))
    }

    if (sort_values) {
      order_index <- order(values, decreasing = TRUE)
      values <- values[order_index]
      labels <- labels[order_index]
    }

    colors <- c(
      "#36cfc9",
      "#38a9ff",
      "#7d8cff",
      "#bd70e8",
      "#f16f9b",
      "#ffad5c"
    )
    if (length(values) > length(colors)) {
      colors <- grDevices::colorRampPalette(colors)(length(values))
    } else {
      colors <- colors[seq_along(values)]
    }

    par(
      mar = c(4, 8, 1, 2),
      bg = "#0c1b2d",
      fg = "#91a6bd",
      col.axis = "#a9bad0",
      col.lab = "#a9bad0",
      xaxs = "i"
    )

    x_limit <- max(values) * 1.25
    bar_positions <- barplot(
      values,
      names.arg = labels,
      horiz = TRUE,
      las = 1,
      col = colors,
      border = NA,
      xlim = c(0, x_limit),
      axes = FALSE,
      cex.names = 0.82
    )
    axis(
      1,
      at = pretty(c(0, x_limit)),
      col = "#36516d",
      col.axis = "#a9bad0",
      lwd = 0.8,
      lwd.ticks = 0.8
    )
    text(
      values,
      bar_positions,
      labels = values,
      pos = 4,
      offset = 0.45,
      xpd = NA,
      col = "#f8fafc",
      cex = 0.82,
      font = 2
    )
    box(bty = "n")
  }

  # ----------------------------------------------------------
  # SCORE GRAPH
  # ----------------------------------------------------------

  output$score_chart <- renderPlot({

    data <- current_recommendations()

    if (nrow(data) == 0) {
      return(NULL)
    }

    plot_data <- data[
      seq_len(min(15, nrow(data))),
      ,
      drop = FALSE
    ]

    scores <- if ("display_score" %in% names(plot_data)) {
      plot_data$display_score
    } else {
      plot_data$hybrid_score
    }

    scores <- suppressWarnings(as.numeric(scores))
    valid_scores <- is.finite(scores)
    plot_data <- plot_data[valid_scores, , drop = FALSE]
    scores <- scores[valid_scores]

    if (length(scores) == 0) {
      return(NULL)
    }

    score_bands <- cut(
      pmin(pmax(scores, 0), 100),
      breaks = c(0, 50, 70, 80, 90, 101),
      labels = c("0-49", "50-69", "70-79", "80-89", "90-100"),
      include.lowest = TRUE,
      right = FALSE
    )
    band_counts <- table(score_bands)
    band_counts <- band_counts[band_counts > 0]

    draw_bars(
      as.numeric(band_counts),
      paste(names(band_counts), "score")
    )
  })

  # ----------------------------------------------------------
  # AUDIO PROFILE
  # ----------------------------------------------------------

  output$audio_chart <- renderPlot({

    data <- current_recommendations()

    if (nrow(data) == 0) {
      return(NULL)
    }

    features <- c(
      "energy",
      "danceability",
      "valence",
      "acousticness",
      "instrumentalness",
      "speechiness"
    )

    available <- features[
      features %in% names(data)
    ]

    if (length(available) == 0) {

      plot.new()

      text(
        0.5,
        0.5,
        "Audio feature data unavailable",
        col = "white"
      )

      return()
    }

    values <- sapply(
      available,
      function(x) {
        mean(
          suppressWarnings(
            as.numeric(
              data[[x]]
            )
          ),
          na.rm = TRUE
        )
      }
    )

    values[is.na(values)] <- 0

    values <- pmin(
      pmax(
        values,
        0
      ),
      1
    )

    names(values) <- c(
      "Energy",
      "Danceability",
      "Valence",
      "Acousticness",
      "Instrumentalness",
      "Speechiness"
    )[match(
      available,
      features
    )]

    feature_colors <- c(
      Energy = "#36cfc9",
      Danceability = "#38a9ff",
      Valence = "#7d8cff",
      Acousticness = "#bd70e8",
      Instrumentalness = "#f16f9b",
      Speechiness = "#ffad5c"
    )
    colors <- unname(feature_colors[names(values)])
    positions <- rev(seq_along(values))

    par(
      mar = c(3.5, 1, 1, 2),
      bg = "#0c1b2d",
      fg = "#91a6bd",
      xaxs = "i",
      yaxs = "i"
    )
    plot.new()
    plot.window(
      xlim = c(0, 1.18),
      ylim = c(0.5, length(values) + 0.5)
    )
    axis(
      1,
      at = seq(0, 1, by = 0.25),
      labels = c("0", "0.25", "0.50", "0.75", "1.00"),
      col = "#36516d",
      col.axis = "#a9bad0",
      lwd = 0.8,
      lwd.ticks = 0.8
    )
    for (tick in seq(0, 1, by = 0.25)) {
      segments(
        tick,
        0.5,
        tick,
        length(values) + 0.5,
        col = "#29415c",
        lty = 3
      )
    }
    text(
      -0.025,
      positions,
      labels = names(values),
      col = "#dce8f4",
      cex = 0.82,
      adj = 1,
      xpd = NA
    )
    rect(
      0,
      positions - 0.28,
      1,
      positions + 0.28,
      col = "#142840",
      border = NA
    )
    rect(0, positions - 0.28, values, positions + 0.28, col = colors, border = NA)
    text(
      values + 0.025,
      positions,
      labels = sprintf("%.2f", values),
      col = "#f8fafc",
      cex = 0.78,
      font = 2,
      adj = 0,
      xpd = NA
    )
    mtext(
      "Average audio-feature value",
      side = 1,
      line = 2.2,
      col = "#91a6bd",
      cex = 0.78
    )
  })

  # ----------------------------------------------------------
  # LANGUAGE GRAPH
  # ----------------------------------------------------------

  output$language_chart <- renderPlot({

    data <- current_recommendations()

    if (nrow(data) == 0) {
      return(NULL)
    }

    languages <- trimws(as.character(data$language))
    languages[is.na(languages) | languages == ""] <- "Unknown"
    counts <- sort(
      table(languages),
      decreasing = TRUE
    )

    draw_bars(
      as.numeric(counts),
      names(counts),
      sort_values = TRUE
    )
  })

  # ----------------------------------------------------------
  # POPULARITY GRAPH
  # ----------------------------------------------------------

  output$popularity_chart <- renderPlot({

    data <- current_recommendations()

    if (
      nrow(data) == 0 ||
      !"popularity" %in% names(data)
    ) {
      return(NULL)
    }

    popularity <- suppressWarnings(
      as.numeric(
        data$popularity
      )
    )

    popularity <- popularity[
      is.finite(popularity)
    ]

    if (length(popularity) == 0) {
      return(NULL)
    }

    popularity <- pmin(pmax(popularity, 0), 100)
    popularity_bands <- cut(
      popularity,
      breaks = c(0, 20, 40, 60, 80, 101),
      labels = c("0-19", "20-39", "40-59", "60-79", "80-100"),
      include.lowest = TRUE,
      right = FALSE
    )
    popularity_counts <- table(popularity_bands)
    popularity_counts <- popularity_counts[popularity_counts > 0]

    draw_bars(
      as.numeric(popularity_counts),
      paste(names(popularity_counts), "popularity")
    )
  })

  # ----------------------------------------------------------
  # NAVIGATION
  # ----------------------------------------------------------

  observeEvent(input$profile_btn, {
    saved <- favorite_songs()
    favorite_list <- if (nrow(saved) > 0) {
      tags$ul(
        lapply(
          seq_len(nrow(saved)),
          function(i) {
            tags$li(
              paste(saved$title[i], " - ", saved$artist[i])
            )
          }
        )
      )
    } else {
      tags$p("No saved songs in this session yet.")
    }

    showModal(
      modalDialog(
        title = "My Profile",
        tags$p("Current dashboard session"),
        tags$p(paste("Language:", input$language)),
        tags$p(paste("Mood:", input$mood)),
        tags$p(paste("Recommendation engine:", input$engine)),
        tags$p(paste("Saved songs:", nrow(saved))),
        tags$h4("Favorites"),
        favorite_list,
        easyClose = TRUE,
        footer = modalButton("Close")
      )
    )
  })

  observeEvent(
    input$trend_btn,
    {
      updateSelectInput(
        session,
        "engine",
        selected = "Trending"
      )

      updateNumericInput(
        session,
        "song_count",
        value = 10
      )

      updateSelectInput(
        session,
        "mood",
        selected = "All Moods"
      )

      updateTextInput(
        session,
        "song_search",
        value = ""
      )

      session$sendCustomMessage(
        "click-input",
        "generate"
      )
    }
  )

  observeEvent(
    input$new_btn,
    {
      updateSelectInput(
        session,
        "engine",
        selected = "New Music"
      )

      updateNumericInput(
        session,
        "song_count",
        value = 10
      )

      updateSelectInput(
        session,
        "mood",
        selected = "All Moods"
      )

      updateTextInput(
        session,
        "song_search",
        value = ""
      )

      session$sendCustomMessage(
        "click-input",
        "generate"
      )
    }
  )
}

# ============================================================
# RUN DASHBOARD
# ============================================================

shinyApp(
  ui = ui,
  server = server
)