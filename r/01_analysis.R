# ============================================================
# MUSIC RECOMMENDATION SYSTEM
# STEP 12 - R DATA ANALYSIS
# BASE R VERSION
# No external packages required
# ============================================================


# ------------------------------------------------------------
# 1. PROJECT PATHS
# ------------------------------------------------------------

data_file <- "data/master_songs.csv"

output_folder <- "outputs"

if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}


# ------------------------------------------------------------
# 2. LOAD DATASET
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("       MUSIC DATA ANALYSIS USING R\n")
cat("============================================\n")

cat("\nLoading dataset...\n")

songs <- read.csv(
  data_file,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

cat("Dataset loaded successfully.\n")

cat("Total Songs:", nrow(songs), "\n")
cat("Total Columns:", ncol(songs), "\n")


# ------------------------------------------------------------
# 3. CLEAN DATA
# ------------------------------------------------------------

numeric_columns <- c(
  "popularity",
  "year",
  "energy",
  "danceability",
  "valence",
  "acousticness",
  "instrumentalness",
  "speechiness",
  "tempo",
  "loudness"
)


for (column in numeric_columns) {

  if (column %in% names(songs)) {

    songs[[column]] <- suppressWarnings(
      as.numeric(songs[[column]])
    )

  }
}


# ------------------------------------------------------------
# 4. BASIC DATA INFORMATION
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("             DATASET INFORMATION\n")
cat("============================================\n")

cat("Total Songs:", nrow(songs), "\n")

cat(
  "Total Artists:",
  length(unique(songs$artist)),
  "\n"
)

cat(
  "Total Languages:",
  length(unique(songs$language)),
  "\n"
)


# ------------------------------------------------------------
# 5. LANGUAGE ANALYSIS
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("           LANGUAGE DISTRIBUTION\n")
cat("============================================\n")

language_table <- table(
  songs$language,
  useNA = "ifany"
)

language_analysis <- data.frame(
  language = names(language_table),
  song_count = as.numeric(language_table),
  stringsAsFactors = FALSE
)


# Average popularity by language

average_popularity <- tapply(
  songs$popularity,
  songs$language,
  mean,
  na.rm = TRUE
)


language_analysis$average_popularity <- as.numeric(
  average_popularity[
    language_analysis$language
  ]
)


language_analysis <- language_analysis[
  order(
    -language_analysis$song_count
  ),
]


print(language_analysis)


# ------------------------------------------------------------
# 6. SAVE LANGUAGE ANALYSIS
# ------------------------------------------------------------

write.csv(
  language_analysis,
  "outputs/language_analysis.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 7. ARTIST ANALYSIS
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("              TOP ARTISTS\n")
cat("============================================\n")

artist_table <- sort(
  table(songs$artist),
  decreasing = TRUE
)

top_artists <- head(
  artist_table,
  20
)

artist_analysis <- data.frame(
  artist = names(top_artists),
  song_count = as.numeric(top_artists),
  stringsAsFactors = FALSE
)


artist_popularity <- tapply(
  songs$popularity,
  songs$artist,
  mean,
  na.rm = TRUE
)


artist_analysis$average_popularity <- as.numeric(
  artist_popularity[
    artist_analysis$artist
  ]
)


print(artist_analysis)


# ------------------------------------------------------------
# 8. SAVE ARTIST ANALYSIS
# ------------------------------------------------------------

write.csv(
  artist_analysis,
  "outputs/artist_analysis.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 9. POPULARITY ANALYSIS
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("           POPULARITY ANALYSIS\n")
cat("============================================\n")

popularity_analysis <- data.frame(

  metric = c(
    "Average Popularity",
    "Maximum Popularity",
    "Minimum Popularity",
    "Median Popularity"
  ),

  value = c(

    mean(
      songs$popularity,
      na.rm = TRUE
    ),

    max(
      songs$popularity,
      na.rm = TRUE
    ),

    min(
      songs$popularity,
      na.rm = TRUE
    ),

    median(
      songs$popularity,
      na.rm = TRUE
    )
  )
)


print(popularity_analysis)


write.csv(
  popularity_analysis,
  "outputs/popularity_analysis.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 10. AUDIO FEATURE ANALYSIS
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("           AUDIO FEATURE ANALYSIS\n")
cat("============================================\n")

audio_analysis <- data.frame(

  feature = c(
    "Energy",
    "Danceability",
    "Valence",
    "Acousticness",
    "Instrumentalness",
    "Speechiness",
    "Tempo",
    "Loudness"
  ),

  average_value = c(

    mean(songs$energy, na.rm = TRUE),

    mean(
      songs$danceability,
      na.rm = TRUE
    ),

    mean(
      songs$valence,
      na.rm = TRUE
    ),

    mean(
      songs$acousticness,
      na.rm = TRUE
    ),

    mean(
      songs$instrumentalness,
      na.rm = TRUE
    ),

    mean(
      songs$speechiness,
      na.rm = TRUE
    ),

    mean(
      songs$tempo,
      na.rm = TRUE
    ),

    mean(
      songs$loudness,
      na.rm = TRUE
    )
  )
)


print(audio_analysis)


write.csv(
  audio_analysis,
  "outputs/audio_analysis.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 11. MOOD CLASSIFICATION
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("              MOOD ANALYSIS\n")
cat("============================================\n")


songs$mood <- "Other"


# Energetic

songs$mood[
  songs$energy >= 0.75 &
  songs$danceability >= 0.65 &
  songs$valence >= 0.65
] <- "Energetic"


# Happy

songs$mood[
  songs$valence >= 0.70
] <- "Happy"


# Sad

songs$mood[
  songs$energy <= 0.35 &
  songs$valence <= 0.40
] <- "Sad"


# Relaxed

songs$mood[
  songs$energy <= 0.45 &
  songs$acousticness >= 0.50
] <- "Relaxed"


# Romantic

songs$mood[
  songs$valence >= 0.50 &
  songs$energy >= 0.35 &
  songs$energy <= 0.65
] <- "Romantic"


mood_table <- table(
  songs$mood
)

mood_analysis <- data.frame(

  mood = names(mood_table),

  song_count = as.numeric(
    mood_table
  ),

  stringsAsFactors = FALSE
)


mood_popularity <- tapply(
  songs$popularity,
  songs$mood,
  mean,
  na.rm = TRUE
)


mood_analysis$average_popularity <- as.numeric(
  mood_popularity[
    mood_analysis$mood
  ]
)


mood_analysis <- mood_analysis[
  order(
    -mood_analysis$song_count
  ),
]


print(mood_analysis)


# ------------------------------------------------------------
# 12. SAVE MOOD ANALYSIS
# ------------------------------------------------------------

write.csv(
  mood_analysis,
  "outputs/mood_analysis.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 13. YEAR ANALYSIS
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("              YEAR ANALYSIS\n")
cat("============================================\n")


valid_years <- songs[
  !is.na(songs$year),
]


year_table <- table(
  valid_years$year
)


year_analysis <- data.frame(

  year = as.numeric(
    names(year_table)
  ),

  song_count = as.numeric(
    year_table
  ),

  stringsAsFactors = FALSE
)


year_popularity <- tapply(
  valid_years$popularity,
  valid_years$year,
  mean,
  na.rm = TRUE
)


year_analysis$average_popularity <- as.numeric(
  year_popularity[
    as.character(year_analysis$year)
  ]
)


year_analysis <- year_analysis[
  order(year_analysis$year),
]


print(
  tail(
    year_analysis,
    15
  )
)


# ------------------------------------------------------------
# 14. SAVE YEAR ANALYSIS
# ------------------------------------------------------------

write.csv(
  year_analysis,
  "outputs/year_analysis.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 15. LANGUAGE + MOOD ANALYSIS
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("         LANGUAGE + MOOD ANALYSIS\n")
cat("============================================\n")


language_mood_table <- table(
  songs$language,
  songs$mood
)


language_mood_analysis <- as.data.frame(
  language_mood_table
)


names(language_mood_analysis) <- c(
  "language",
  "mood",
  "song_count"
)


language_mood_analysis <- language_mood_analysis[
  language_mood_analysis$song_count > 0,
]


print(
  head(
    language_mood_analysis,
    30
  )
)


# ------------------------------------------------------------
# 16. SAVE LANGUAGE + MOOD ANALYSIS
# ------------------------------------------------------------

write.csv(
  language_mood_analysis,
  "outputs/language_mood_analysis.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 17. TOP POPULAR SONGS
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("             TOP POPULAR SONGS\n")
cat("============================================\n")


top_songs <- songs[
  order(
    -songs$popularity,
    na.last = TRUE
  ),
]


top_songs <- head(
  top_songs,
  20
)


top_songs <- top_songs[
  c(
    "title",
    "artist",
    "language",
    "year",
    "popularity"
  )
]


print(top_songs)


# ------------------------------------------------------------
# 18. SAVE TOP SONGS
# ------------------------------------------------------------

write.csv(
  top_songs,
  "outputs/top_popular_songs.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 19. SUMMARY REPORT
# ------------------------------------------------------------

summary_report <- data.frame(

  metric = c(
    "Total Songs",
    "Total Artists",
    "Total Languages",
    "Average Popularity",
    "Average Energy",
    "Average Danceability",
    "Average Valence",
    "Average Tempo"
  ),

  value = c(

    nrow(songs),

    length(
      unique(songs$artist)
    ),

    length(
      unique(songs$language)
    ),

    mean(
      songs$popularity,
      na.rm = TRUE
    ),

    mean(
      songs$energy,
      na.rm = TRUE
    ),

    mean(
      songs$danceability,
      na.rm = TRUE
    ),

    mean(
      songs$valence,
      na.rm = TRUE
    ),

    mean(
      songs$tempo,
      na.rm = TRUE
    )
  )
)


# ------------------------------------------------------------
# 20. SAVE SUMMARY
# ------------------------------------------------------------

write.csv(
  summary_report,
  "outputs/music_analysis_summary.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 21. COMPLETION
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("       ANALYSIS COMPLETED SUCCESSFULLY\n")
cat("============================================\n")

cat("\nGenerated files:\n")

cat("1. language_analysis.csv\n")
cat("2. artist_analysis.csv\n")
cat("3. popularity_analysis.csv\n")
cat("4. audio_analysis.csv\n")
cat("5. mood_analysis.csv\n")
cat("6. year_analysis.csv\n")
cat("7. language_mood_analysis.csv\n")
cat("8. top_popular_songs.csv\n")
cat("9. music_analysis_summary.csv\n")

cat("\nNo external R packages were required.\n")
cat("Analysis files saved in outputs/.\n")