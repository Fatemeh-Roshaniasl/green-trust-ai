# =============================================================
# 05b_analyse_coder.R
# Step 5: compare the naive human coder with the true labels and with
# the AI rater (Steps 4 and 4b).
#
# Coder 1: naive (had not seen the project), did round 1 (persuasiveness)
# completely before round 2 (cue), about 25 minutes in total (12 Nov).
#
# Note: with ONE coder, all tests below compare MESSAGES, not people.
# They describe how this person read these 60 messages; they do not
# generalise to people in general. Persuasiveness is one person's taste.
# =============================================================

library(tidyverse)
library(readxl)

kappa <- function(a, b) {                     # Cohen's kappa for two label vectors
  lv <- union(a, b)
  t  <- table(factor(a, lv), factor(b, lv))
  po <- sum(diag(t)) / sum(t)
  pe <- sum(rowSums(t) * colSums(t)) / sum(t)^2
  (po - pe) / (1 - pe)
}

key <- read_csv("coding/answer_key.csv", show_col_types = FALSE)
r1  <- read_excel("coding/responses/round1_persuasiveness_coder1.xlsx", sheet = "Messages") |>
  select(round1_item = item, human_p = persuasiveness)
r2  <- read_excel("coding/responses/round2_cues_coder1.xlsx", sheet = "Messages") |>
  select(round2_item = item, human_cue = cue)

# AI rater: majority cue and mean persuasiveness per message
model_primed <- read_csv("output/ratings.csv", show_col_types = FALSE) |>
  group_by(message_id) |>
  summarise(model_cue = names(which.max(table(rated_cue))),
            model_p_primed = mean(persuasiveness))
model_unprimed <- read_csv("output/ratings_persuasion_only.csv", show_col_types = FALSE) |>
  group_by(message_id) |> summarise(model_p_unprimed = mean(persuasiveness))

d <- key |> left_join(r1, by = "round1_item") |> left_join(r2, by = "round2_item") |>
  left_join(model_primed, by = "message_id") |> left_join(model_unprimed, by = "message_id") |>
  mutate(human_p = as.numeric(human_p))
stopifnot(nrow(d) == 60, !anyNA(d$human_p), !anyNA(d$human_cue))
write_csv(d, "output/05_coder1_results.csv")

cat("\n== 1. Can a naive person see the cues? (human vs true label) ==\n")
cat("Accuracy:", round(mean(d$human_cue == d$framing), 2), "(chance 0.33) | Cohen's kappa:",
    round(kappa(d$human_cue, d$framing), 2), "\n")
print(table(true = d$framing, human = d$human_cue))

cat("\n   By angle (share correct):\n")
print(d |> filter(framing != "neutral") |> group_by(framing, angle) |>
        summarise(correct = round(mean(human_cue == framing), 2), n = n(), .groups = "drop"))

cat("\n== 2. Does the person read the cues like the AI? (human vs AI majority label) ==\n")
cat("AI vs true on these 60:", round(mean(d$model_cue == d$framing), 2),
    "| agreement human vs AI:", round(mean(d$human_cue == d$model_cue), 2),
    "| kappa human vs AI:", round(kappa(d$human_cue, d$model_cue), 2), "\n")
print(table(AI = d$model_cue, human = d$human_cue))

cat("\n== 3. Precision: are precise neutral messages read as competence? ==\n")
print(d |> filter(framing == "neutral") |> group_by(precise) |>
        summarise(human_called_competence = sum(human_cue == "competence"),
                  AI_called_competence    = sum(model_cue == "competence"),
                  n = n()))

cat("\n== 4. How the person used the scale (AI: never 1 or 7) ==\n")
print(table(d$human_p))

cat("\n== 5. Persuasiveness by framing: human vs AI (unprimed and primed) ==\n")
print(d |> group_by(framing) |>
        summarise(human = round(mean(human_p), 2), AI_unprimed = round(mean(model_p_unprimed), 2),
                  AI_primed = round(mean(model_p_primed), 2), n = n()))
cat("Cue minus neutral gap, human:",
    round(mean(d$human_p[d$framing != "neutral"]) - mean(d$human_p[d$framing == "neutral"]), 2), "\n")
print(t.test(human_p ~ framing != "neutral", data = d))

cat("\n== 6. Wrong vs accurate advice (between products here, not twins) ==\n")
print(d |> group_by(quality) |> summarise(human = round(mean(human_p), 2), n = n()))
print(t.test(human_p ~ quality, data = d))

cat("\n== 7. Precision and persuasiveness (neutral messages only) ==\n")
print(d |> filter(framing == "neutral") |> group_by(precise) |>
        summarise(human = round(mean(human_p), 2), AI_unprimed = round(mean(model_p_unprimed), 2), n = n()))

cat("\n== 8. Do the person and the AI find the same messages persuasive? ==\n")
cat("r human vs AI unprimed:", round(cor(d$human_p, d$model_p_unprimed), 2),
    "| r human vs AI primed:", round(cor(d$human_p, d$model_p_primed), 2), "\n")
cat("r human vs message length:", round(cor(d$human_p, d$words), 2), "\n")

cat("\nSaved: output/05_coder1_results.csv\n")
