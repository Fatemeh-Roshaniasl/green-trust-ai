# =============================================================
# 05c_analyse_two_coders.R
# Step 5: two naive coders, compared with the true labels, with each
# other, and with the AI rater (Steps 4 and 4b).
#
# Both coders were naive and did round 1 (persuasiveness) before round 2
# (cue). Two people are still a very small sample: tests compare
# messages, and persuasiveness results are a signal, not a finding
# about people in general.
#
# Agreement measures:
#   cues (categories)       -> Cohen's kappa
#   persuasiveness (1 to 7) -> intraclass correlation (ICC), computed
#                              from a two-way ANOVA (Shrout & Fleiss 1979)
#   ICC consistency: do the coders rank the messages alike?
#   ICC agreement:   do they also give the same numbers?
# =============================================================

library(tidyverse)
library(readxl)

kappa <- function(a, b) {
  lv <- union(a, b); t <- table(factor(a, lv), factor(b, lv))
  po <- sum(diag(t)) / sum(t); pe <- sum(rowSums(t) * colSums(t)) / sum(t)^2
  (po - pe) / (1 - pe)
}
icc <- function(m) {                      # m: messages x raters matrix
  n <- nrow(m); k <- ncol(m); g <- mean(m)
  msr <- k * sum((rowMeans(m) - g)^2) / (n - 1)
  msc <- n * sum((colMeans(m) - g)^2) / (k - 1)
  mse <- (sum((m - g)^2) - msr * (n - 1) - msc * (k - 1)) / ((n - 1) * (k - 1))
  c(consistency = (msr - mse) / (msr + (k - 1) * mse),
    agreement   = (msr - mse) / (msr + (k - 1) * mse + k * (msc - mse) / n))
}

key <- read_csv("coding/answer_key.csv", show_col_types = FALSE)
read_coder <- function(i) {
  r1 <- read_excel(sprintf("coding/responses/round1_persuasiveness_coder%d.xlsx", i), sheet = "Messages") |>
    transmute(round1_item = item, p = as.numeric(persuasiveness))
  r2 <- read_excel(sprintf("coding/responses/round2_cues_coder%d.xlsx", i), sheet = "Messages") |>
    transmute(round2_item = item, cue = cue)
  key |> select(round1_item, round2_item, message_id) |>
    left_join(r1, by = "round1_item") |> left_join(r2, by = "round2_item") |>
    select(message_id, p, cue) |> rename_with(~ paste0(.x, i), c(p, cue))
}

model <- read_csv("output/ratings.csv", show_col_types = FALSE) |> group_by(message_id) |>
  summarise(ai_cue = names(which.max(table(rated_cue))), ai_p_primed = mean(persuasiveness))
model_u <- read_csv("output/ratings_persuasion_only.csv", show_col_types = FALSE) |>
  group_by(message_id) |> summarise(ai_p_unprimed = mean(persuasiveness))

d <- key |> left_join(read_coder(1), by = "message_id") |> left_join(read_coder(2), by = "message_id") |>
  left_join(model, by = "message_id") |> left_join(model_u, by = "message_id") |>
  mutate(human_p = (p1 + p2) / 2, cue_group = if_else(framing == "neutral", "neutral", "cue"))
stopifnot(nrow(d) == 60, !anyNA(select(d, p1, p2, cue1, cue2)))
write_csv(d, "output/05_two_coders_results.csv")

cat("\n== 1. Cue recognition: each coder vs the true labels ==\n")
for (i in 1:2) {
  cue <- d[[paste0("cue", i)]]
  cat(sprintf("Coder %d: accuracy %.2f | kappa %.2f\n", i, mean(cue == d$framing), kappa(cue, d$framing)))
}
cat("AI on the same 60: accuracy", round(mean(d$ai_cue == d$framing), 2),
    "| kappa", round(kappa(d$ai_cue, d$framing), 2), "\n")
cat("\nCoder 2 confusion table:\n"); print(table(true = d$framing, coder2 = d$cue2))

cat("\n== 2. Do the two coders agree with each other on the cues? ==\n")
cat("Agreement", round(mean(d$cue1 == d$cue2), 2), "| kappa coder 1 vs 2:", round(kappa(d$cue1, d$cue2), 2), "\n")
cat("Both coders correct on", sum(d$cue1 == d$framing & d$cue2 == d$framing), "of 60 messages\n")
cat("\nMessages BOTH coders got wrong (worth reading):\n")
print(d |> filter(cue1 != framing, cue2 != framing) |> select(message_id, framing, angle, cue1, cue2))

cat("\n   By angle (share correct, coder 1 | coder 2):\n")
print(d |> filter(framing != "neutral") |> group_by(framing, angle) |>
        summarise(coder1 = round(mean(cue1 == framing), 2), coder2 = round(mean(cue2 == framing), 2),
                  n = n(), .groups = "drop"))

cat("\n== 3. Precise neutral messages called competence ==\n")
print(d |> filter(framing == "neutral") |> group_by(precise) |>
        summarise(coder1 = sum(cue1 == "competence"), coder2 = sum(cue2 == "competence"),
                  AI = sum(ai_cue == "competence"), n = n()))

cat("\n== 4. Scale use ==\n")
print(rbind(coder1 = table(factor(d$p1, 1:7)), coder2 = table(factor(d$p2, 1:7))))
cat("Means: coder 1", round(mean(d$p1), 2), "| coder 2", round(mean(d$p2), 2), "\n")

cat("\n== 5. Do the two coders agree on persuasiveness? ==\n")
print(round(icc(cbind(d$p1, d$p2)), 2))
cat("r coder 1 vs coder 2:", round(cor(d$p1, d$p2), 2), "\n")

cat("\n== 6. Persuasiveness by framing: each coder, their average, and the AI ==\n")
print(d |> group_by(framing) |>
        summarise(coder1 = round(mean(p1), 2), coder2 = round(mean(p2), 2), humans = round(mean(human_p), 2),
                  AI_unprimed = round(mean(ai_p_unprimed), 2), AI_primed = round(mean(ai_p_primed), 2)))
gap <- function(x) mean(x[d$framing != "neutral"]) - mean(x[d$framing == "neutral"])
cat(sprintf("Cue minus neutral: coder 1 %.2f | coder 2 %.2f | humans %.2f | AI unprimed %.2f | AI primed %.2f\n",
            gap(d$p1), gap(d$p2), gap(d$human_p), gap(d$ai_p_unprimed), gap(d$ai_p_primed)))
print(t.test(human_p ~ cue_group, data = d))

cat("\n== 7. Wrong vs accurate (between products) ==\n")
print(d |> group_by(quality) |> summarise(coder1 = round(mean(p1), 2), coder2 = round(mean(p2), 2),
                                          humans = round(mean(human_p), 2)))

cat("\n== 8. Precision and persuasiveness (neutral only) ==\n")
print(d |> filter(framing == "neutral") |> group_by(precise) |>
        summarise(coder1 = round(mean(p1), 2), coder2 = round(mean(p2), 2),
                  AI_unprimed = round(mean(ai_p_unprimed), 2), n = n()))

cat("\n== 9. Do humans and the AI find the same messages persuasive? ==\n")
cat(sprintf("r with AI unprimed: coder 1 %.2f | coder 2 %.2f | humans' average %.2f\n",
            cor(d$p1, d$ai_p_unprimed), cor(d$p2, d$ai_p_unprimed), cor(d$human_p, d$ai_p_unprimed)))
cat(sprintf("r with message length: coder 1 %.2f | coder 2 %.2f\n", cor(d$p1, d$words), cor(d$p2, d$words)))

cat("\nSaved: output/05_two_coders_results.csv\n")
