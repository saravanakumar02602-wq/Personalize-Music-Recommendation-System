# ============================================================
# MUSIC RECOMMENDATION SYSTEM
# STEP 13 - R DATA VISUALIZATION
# BASE R VERSION
# No external packages required
# ============================================================

output_folder <- "outputs"
chart_folder <- "outputs/charts"

if (!dir.exists(chart_folder)) {
  dir.create(
    chart_folder,
    recursive = TRUE
  )
}

cat("\n")
cat("============================================\n")
cat("       MUSIC DATA VISUALIZATION USING R\n")
cat("============================================\n")

# ------------------------------------------------------------
# 1. LANGUAGE DISTRIBUTION
# ------------------------------------------------------------

cat("\nCreating language distribution chart...\n")

language_data <- read.csv(
  "outputs/language_analysis.csv",
  stringsAsFactors = FALSE
)

png(
  "outputs/charts/language_distribution.png",
  width = 1200,
  height = 700
)

barplot(
  language_data$song_count,
  names.arg = language_data$language,
  main = "Music Dataset - Language Distribution",
  xlab = "Language",
  ylab = "Number of Songs",
  las = 2,
  cex.names = 0.8
)

dev.off()


# ------------------------------------------------------------
# 2. TOP ARTISTS
# ------------------------------------------------------------

cat("Creating top artists chart...\n")

artist_data <- read.csv(
  "outputs/artist_analysis.csv",
  stringsAsFactors = FALSE
)

artist_data <- artist_data[
  order(
    artist_data$song_count,
    decreasing = TRUE
  ),
]

top_artist_data <- head(
  artist_data,
  10
)

png(
  "outputs/charts/top_artists.png",
  width = 1200,
  height = 700
)

barplot(
  top_artist_data$song_count,
  names.arg = top_artist_data$artist,
  main = "Top 10 Artists by Number of Songs",
  xlab = "Artist",
  ylab = "Number of Songs",
  las = 2,
  cex.names = 0.75
)

dev.off()


# ------------------------------------------------------------
# 3. MOOD DISTRIBUTION
# ------------------------------------------------------------

cat("Creating mood distribution chart...\n")

mood_data <- read.csv(
  "outputs/mood_analysis.csv",
  stringsAsFactors = FALSE
)

png(
  "outputs/charts/mood_distribution.png",
  width = 1000,
  height = 700
)

barplot(
  mood_data$song_count,
  names.arg = mood_data$mood,
  main = "Music Mood Distribution",
  xlab = "Mood",
  ylab = "Number of Songs",
  las = 2
)

dev.off()


# ------------------------------------------------------------
# 4. AVERAGE AUDIO FEATURES
# ------------------------------------------------------------

cat("Creating audio feature chart...\n")

audio_data <- read.csv(
  "outputs/audio_analysis.csv",
  stringsAsFactors = FALSE
)

png(
  "outputs/charts/audio_features.png",
  width = 1200,
  height = 700
)

barplot(
  audio_data$average_value,
  names.arg = audio_data$feature,
  main = "Average Audio Features",
  xlab = "Audio Feature",
  ylab = "Average Value",
  las = 2,
  cex.names = 0.75
)

dev.off()


# ------------------------------------------------------------
# 5. YEAR-WISE SONG DISTRIBUTION
# ------------------------------------------------------------

cat("Creating year-wise chart...\n")

year_data <- read.csv(
  "outputs/year_analysis.csv",
  stringsAsFactors = FALSE
)

png(
  "outputs/charts/year_distribution.png",
  width = 1200,
  height = 700
)

plot(
  year_data$year,
  year_data$song_count,
  type = "l",
  main = "Year-wise Number of Songs",
  xlab = "Year",
  ylab = "Number of Songs"
)

dev.off()


# ------------------------------------------------------------
# 6. YEAR-WISE POPULARITY
# ------------------------------------------------------------

cat("Creating popularity trend chart...\n")

png(
  "outputs/charts/year_popularity.png",
  width = 1200,
  height = 700
)

plot(
  year_data$year,
  year_data$average_popularity,
  type = "l",
  main = "Year-wise Average Popularity",
  xlab = "Year",
  ylab = "Average Popularity"
)

dev.off()


# ------------------------------------------------------------
# 7. TOP POPULAR SONGS
# ------------------------------------------------------------

cat("Creating top songs chart...\n")

top_songs <- read.csv(
  "outputs/top_popular_songs.csv",
  stringsAsFactors = FALSE
)

top_songs <- head(
  top_songs,
  10
)

song_labels <- paste(
  top_songs$title,
  "-",
  top_songs$artist
)

png(
  "outputs/charts/top_popular_songs.png",
  width = 1400,
  height = 800
)

barplot(
  top_songs$popularity,
  names.arg = song_labels,
  main = "Top 10 Popular Songs",
  xlab = "Song",
  ylab = "Popularity",
  las = 2,
  cex.names = 0.6
)

dev.off()


# ------------------------------------------------------------
# 8. LANGUAGE + MOOD
# ------------------------------------------------------------

cat("Creating language and mood chart...\n")

language_mood <- read.csv(
  "outputs/language_mood_analysis.csv",
  stringsAsFactors = FALSE
)

language_mood_matrix <- xtabs(
  song_count ~ language + mood,
  data = language_mood
)

png(
  "outputs/charts/language_mood.png",
  width = 1200,
  height = 800
)

barplot(
  language_mood_matrix,
  beside = FALSE,
  main = "Language and Mood Distribution",
  xlab = "Language",
  ylab = "Number of Songs",
  las = 2,
  legend.text = TRUE,
  args.legend = list(
    x = "topright",
    cex = 0.7
  )
)

dev.off()


# ------------------------------------------------------------
# 9. POPULARITY DISTRIBUTION
# ------------------------------------------------------------

cat("Creating popularity distribution...\n")

popularity_data <- read.csv(
  "outputs/popularity_analysis.csv",
  stringsAsFactors = FALSE
)

png(
  "outputs/charts/popularity_summary.png",
  width = 1000,
  height = 700
)

barplot(
  popularity_data$value,
  names.arg = popularity_data$metric,
  main = "Popularity Statistics",
  xlab = "Metric",
  ylab = "Popularity Value",
  las = 2
)

dev.off()


# ------------------------------------------------------------
# COMPLETION
# ------------------------------------------------------------

cat("\n")
cat("============================================\n")
cat("       VISUALIZATION COMPLETED SUCCESSFULLY\n")
cat("============================================\n")

cat("\nCharts created:\n")

cat("1. language_distribution.png\n")
cat("2. top_artists.png\n")
cat("3. mood_distribution.png\n")
cat("4. audio_features.png\n")
cat("5. year_distribution.png\n")
cat("6. year_popularity.png\n")
cat("7. top_popular_songs.png\n")
cat("8. language_mood.png\n")
cat("9. popularity_summary.png\n")

cat("\nAll charts are saved in:\n")
cat("outputs/charts/\n")

cat("\nNo external R packages were required.\n")