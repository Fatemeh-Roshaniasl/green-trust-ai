# =============================================================
# 04b_llm_rater_persuasion_only.R
# Step 4b: priming check. The same rater rates persuasiveness ONLY.
#
# Why (decision 12 Nov): in Step 4 the rater answered "which cue?" and
# "how persuasive?" in the same call, so naming competence / integrity
# first may have primed its persuasiveness score (halo). Here the rater
# is never told about cues, framings or categories.
#
# Everything else is kept identical to Step 4 (one difference at a time):
# same model, same 216 messages, 3 ratings each, same random order
# (set.seed(2026)), fresh chat each time, same persuasiveness wording.
# Comparison: Step 4 (primed) vs Step 4b (unprimed) on the same messages.
# Saves after every rating and can be resumed.
# =============================================================

library(ellmer)
library(tidyverse)

stopifnot(nzchar(Sys.getenv("ANTHROPIC_API_KEY")))

rater_model <- "claude-haiku-4-5-20251001"
n_ratings   <- 3
out_file    <- "output/ratings_persuasion_only.csv"

messages <- read_csv("output/messages.csv", show_col_types = FALSE)

# --- 1. Instructions: the Step 4 persuasiveness question, nothing else ----
rater_rules <- "
You will read one short message in which someone gives a carbon footprint
estimate for a product.

How persuasive is the WORDING of the message, from 1 (not at all
persuasive) to 7 (extremely persuasive)? Judge only how convincing the text
would be to an ordinary reader. Do NOT judge whether the number itself is
correct, and do not use any knowledge you have about real carbon footprints.
"

rating_type <- type_object(
  persuasiveness = type_integer("Persuasiveness of the wording, 1 to 7")
)

rate_once <- function(text) {
  chat <- chat_anthropic(system_prompt = rater_rules, model = rater_model, echo = "none")
  res  <- chat$chat_structured(paste("Message:\n\n", text), type = rating_type)
  tok  <- chat$get_tokens()
  tibble(persuasiveness = res$persuasiveness,
         input_tokens = sum(tok$input), output_tokens = sum(tok$output))
}

# --- 2. Same plan and order as Step 4, skipping finished ratings ----------
set.seed(2026)
plan <- expand_grid(message_id = messages$message_id, rating = seq_len(n_ratings)) |>
  slice_sample(prop = 1) |>
  mutate(rating_id = paste(message_id, rating, sep = "_r"))

done <- if (file.exists(out_file)) read_csv(out_file, show_col_types = FALSE)$rating_id else character(0)
todo <- filter(plan, !rating_id %in% done)
cat("Ratings planned:", nrow(plan), "| done:", length(done), "| to do now:", nrow(todo), "\n")

for (i in seq_len(nrow(todo))) {
  t   <- todo[i, ]
  msg <- messages$message[messages$message_id == t$message_id]
  row <- bind_cols(t, rate_once(msg), tibble(model = rater_model, created = Sys.time()))
  write_csv(row, out_file, append = file.exists(out_file))
  if (i %% 25 == 0 || i == nrow(todo)) cat(sprintf("[%3d/%d] rated\n", i, nrow(todo)))
}

# --- 3. Results (conditions joined only now) -----------------------------
info <- messages |>
  select(message_id, product_id, framing, quality, words, message) |>
  mutate(variant = str_extract(message_id, "\\d$"),
         precise = str_detect(message, "\\bempty\\b|\\b\\d+\\s?(ml|g)\\b|\\b1 kg\\b"))

unprimed <- read_csv(out_file, show_col_types = FALSE) |> left_join(info, by = "message_id")

cat("\n== 1. How the scale was used (unprimed; Step 4 had 66% sixes, no 1s or 7s) ==\n")
print(table(unprimed$persuasiveness))

cat("\n== 2. Persuasiveness by framing and quality (unprimed) ==\n")
print(unprimed |> group_by(framing, quality) |>
        summarise(mean_p = round(mean(persuasiveness), 2), .groups = "drop") |>
        pivot_wider(names_from = quality, values_from = mean_p))

cat("\n== 3. Key test again: wrong minus accurate (unprimed) ==\n")
per_msg_u <- unprimed |> group_by(message_id, product_id, framing, quality, variant, precise) |>
  summarise(p_unprimed = mean(persuasiveness), sd_u = sd(persuasiveness), .groups = "drop")
paired_u <- per_msg_u |> select(product_id, framing, variant, quality, p_unprimed) |>
  pivot_wider(names_from = quality, values_from = p_unprimed) |> mutate(diff = wrong - accurate)
print(paired_u |> group_by(framing) |> summarise(mean_diff = round(mean(diff), 2), n_pairs = n()))
print(t.test(paired_u$wrong, paired_u$accurate, paired = TRUE))

cat("\n== 4. Priming check: primed (Step 4) vs unprimed (Step 4b), same messages ==\n")
per_msg_p <- read_csv("output/ratings.csv", show_col_types = FALSE) |>
  group_by(message_id) |> summarise(p_primed = mean(persuasiveness))
both <- per_msg_u |> left_join(per_msg_p, by = "message_id")
print(both |> group_by(framing) |>
        summarise(primed = round(mean(p_primed), 2), unprimed = round(mean(p_unprimed), 2),
                  change = round(unprimed - primed, 2)))
gap <- both |> mutate(cue = framing != "neutral") |> group_by(cue) |>
  summarise(primed = mean(p_primed), unprimed = mean(p_unprimed))
# gap rows are cue = FALSE (neutral), TRUE (cue); cue minus neutral = diff(), not diff(rev())
cat("Framing gap (cue minus neutral): primed",
    round(diff(gap$primed), 2), "| unprimed", round(diff(gap$unprimed), 2), "\n")
print(cor.test(both$p_primed, both$p_unprimed))   # do the two runs rank messages alike?

cat("\n== 5. Precision effect without priming (neutral messages only) ==\n")
print(both |> filter(framing == "neutral") |> group_by(precise) |>
        summarise(primed = round(mean(p_primed), 2), unprimed = round(mean(p_unprimed), 2), n = n()))

cat("\n== 6. Rater consistency (mean SD across the 3 ratings; Step 4 was 0.24) ==\n")
print(round(mean(per_msg_u$sd_u), 2))

cat("\n== Tokens and cost (Haiku 4.5: $1 in / $5 out per million) ==\n")
print(summarise(unprimed, input = sum(input_tokens), output = sum(output_tokens),
                cost_usd = round(input / 1e6 * 1 + output / 1e6 * 5, 2)))

cat("\nSaved:", out_file, "\n")
