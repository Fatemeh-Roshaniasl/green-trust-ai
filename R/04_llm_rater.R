# =============================================================
# 04_llm_rater.R
# Step 4: a second LLM (Claude) rates all 216 messages BLIND.
#
# For each message the rater answers two questions:
#   1. Which cue does the text contain? (neutral / competence / integrity)
#      -> manipulation check: can an independent reader tell them apart?
#   2. How persuasive is the WORDING? (1 to 7)
#      -> the rater is told to judge the wording only and NOT whether the
#         number is correct (decision 11 Nov: option A), so any difference
#         can only come from the text.
#
# Key test (plan, Step 4): is wrong advice rated as persuasive as
# accurate advice? The two versions differ only in the number.
#
# Blind: the rater never sees the framing, angle, quality or product
# data, only the message text. Messages are rated in random order, each
# in a fresh chat, 3 times each (to measure the rater's consistency).
#
# Rater model: claude-haiku-4-5-20251001 (dated, so it never changes;
# cheap; chosen 11 Nov). Saves after every rating and can be resumed.
# =============================================================

library(ellmer)
library(tidyverse)

stopifnot(nzchar(Sys.getenv("ANTHROPIC_API_KEY")))

rater_model <- "claude-haiku-4-5-20251001"
n_ratings   <- 3
out_file    <- "output/ratings.csv"

messages <- read_csv("output/messages.csv", show_col_types = FALSE)

# --- 1. The rater's instructions -------------------------------------------
# The categories are described in neutral terms; the rater is not told
# anything about the study, the hypotheses or which message is which.
rater_rules <- "
You will read one short message in which someone gives a carbon footprint
estimate for a product. Answer two questions about the message.

Question 1. Which kind of statement about the writer does the message contain?
- competence: the writer signals skill or expertise (for example experience,
  method or past success with such estimates)
- integrity: the writer signals honesty or independence (for example no ties
  to the seller, no preference for a high or low figure, or a commitment to
  saying only what they believe is correct)
- neutral: the message gives the estimate without saying anything about the
  writer's skill, honesty or independence
Choose exactly one.

Question 2. How persuasive is the WORDING of the message, from 1 (not at all
persuasive) to 7 (extremely persuasive)? Judge only how convincing the text
would be to an ordinary reader. Do NOT judge whether the number itself is
correct, and do not use any knowledge you have about real carbon footprints.
"

rating_type <- type_object(
  cue            = type_enum(c("neutral", "competence", "integrity"),
                             "Which kind of statement the message contains"),
  persuasiveness = type_integer("Persuasiveness of the wording, 1 to 7")
)

rate_once <- function(text) {
  chat <- chat_anthropic(system_prompt = rater_rules, model = rater_model, echo = "none")
  res  <- chat$chat_structured(paste("Message:\n\n", text), type = rating_type)
  tok  <- chat$get_tokens()
  tibble(rated_cue = res$cue, persuasiveness = res$persuasiveness,
         input_tokens = sum(tok$input), output_tokens = sum(tok$output))
}

# --- 2. Plan all ratings, in random order, skipping finished ones ---------
set.seed(2026)
plan <- expand_grid(message_id = messages$message_id, rating = seq_len(n_ratings)) |>
  slice_sample(prop = 1) |>                       # random order
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

# --- 3. Join the ratings with the true conditions (only now!) ------------
ratings <- read_csv(out_file, show_col_types = FALSE) |>
  left_join(select(messages, message_id, product_id, framing, angle, quality, words),
            by = "message_id")

cat("\n== 1. Manipulation check: does the rater recognise the framing? ==\n")
print(mean(ratings$rated_cue == ratings$framing))          # overall accuracy (chance = 0.33)
print(table(true = ratings$framing, rated = ratings$rated_cue))

cat("\n== 2. Persuasiveness by framing and advice quality (mean of all ratings) ==\n")
print(ratings |> group_by(framing, quality) |>
        summarise(mean_persuasive = round(mean(persuasiveness), 2), n = n(), .groups = "drop") |>
        pivot_wider(names_from = quality, values_from = c(mean_persuasive, n)))

cat("\n== 3. Key test: wrong minus accurate, per framing (0 = equally persuasive) ==\n")
# Average the 3 ratings per message first, then compare matched messages
# (same product, framing and variant; only the number differs).
per_msg <- ratings |>
  group_by(message_id, product_id, framing, angle, quality, words) |>
  summarise(p = mean(persuasiveness), .groups = "drop") |>
  mutate(variant = str_extract(message_id, "\\d$"))
paired <- per_msg |>
  select(product_id, framing, variant, quality, p) |>
  pivot_wider(names_from = quality, values_from = p) |>
  mutate(diff = wrong - accurate)
print(paired |> group_by(framing) |>
        summarise(mean_diff = round(mean(diff), 2), sd_diff = round(sd(diff), 2), n_pairs = n()))
print(t.test(paired$wrong, paired$accurate, paired = TRUE))

cat("\n== 4. Rater consistency across its 3 ratings of the same message ==\n")
consistency <- ratings |> group_by(message_id) |>
  summarise(same_cue_all3 = n_distinct(rated_cue) == 1, sd_persuasive = sd(persuasiveness))
print(summarise(consistency,
                share_same_cue = round(mean(same_cue_all3), 2),
                mean_sd_persuasive = round(mean(sd_persuasive), 2)))

cat("\n== 5. Does length go with persuasiveness? (correlation, messages) ==\n")
print(cor.test(per_msg$words, per_msg$p))

cat("\n== Tokens and cost (Haiku 4.5: $1 in / $5 out per million) ==\n")
print(summarise(ratings, input = sum(input_tokens), output = sum(output_tokens),
                cost_usd = round(input / 1e6 * 1 + output / 1e6 * 5, 2)))

cat("\nSaved:", out_file, "\n")
