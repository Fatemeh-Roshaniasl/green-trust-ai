# =============================================================
# 06b_make_assignment.R
# Step 6: the assignment plan. For every future participant: which group
# (framing x label), which products get accurate vs wrong advice, which
# message variant, and the order of the 12 trials.
#
# Design (agreed 15 Nov):
#   - framing (neutral / competence / integrity) and source label
#     (AI assistant / human expert): between subjects, 6 groups, assigned
#     once; the same advisor for all 12 trials
#   - advice quality: within subjects, 6 accurate + 6 wrong products
#   - each product shown once (no contradictions)
#   - the label is shown as a heading above the message; it is not part of
#     the message text, so both label groups see identical messages
#
# Balancing (so nothing is left to luck):
#   - 2 quality lists: list A = a fixed set of 6 products accurate, the
#     other 6 wrong; list B = the reverse. Each list has 3 + 3 products
#     from the precise and plain descriptions (as in Step 5).
#   - Participants come in blocks of 12: each block contains every
#     group x list combination once (block randomisation).
#   - Variants rotate by block, so every message variant is used equally.
#   - Trial order is shuffled separately for each participant.
#
# Sample size from the Step 7 power analysis (18 Nov): 1,200 analysed gives
# 83% power for H3 at the smallest effect of interest (0.05); 111 blocks
# (1,332 participants) are recruited to allow ~10% exclusions.
# =============================================================

library(tidyverse)

n_blocks <- 111                     # 111 blocks = 1,332 recruited (1,200 analysed + ~10% exclusions; Step 7 power analysis, 18 Nov)
set.seed(2026)

messages <- read_csv("output/messages.csv", show_col_types = FALSE)

# --- 1. Two quality lists, balanced on precise vs plain descriptions -----
precise_products <- c("P02", "P03", "P04", "P05", "P09", "P10")
plain_products   <- c("P01", "P06", "P07", "P08", "P11", "P12")
accurate_in_A    <- c(sample(precise_products, 3), sample(plain_products, 3))

lists <- expand_grid(list = c("A", "B"), product_id = sort(c(precise_products, plain_products))) |>
  mutate(quality = case_when(
    list == "A" &  product_id %in% accurate_in_A ~ "accurate",
    list == "A"                                  ~ "wrong",
    list == "B" &  product_id %in% accurate_in_A ~ "wrong",
    TRUE                                         ~ "accurate"))

# --- 2. Participants in balanced blocks of 12 ----------------------------
cells <- expand_grid(framing = c("neutral", "competence", "integrity"),
                     label   = c("AI assistant", "human expert"),
                     list    = c("A", "B"))
participants <- map_dfr(seq_len(n_blocks), \(b) slice_sample(cells, prop = 1) |> mutate(block = b)) |>
  mutate(participant_id = sprintf("S%04d", row_number()), .before = 1)

# --- 3. Twelve trials per participant ------------------------------------
product_index <- setNames(1:12, sort(c(precise_products, plain_products)))
plan <- participants |>
  left_join(lists, by = "list", relationship = "many-to-many") |>
  mutate(variant = (block + product_index[product_id]) %% 3 + 1) |>
  group_by(participant_id) |>
  mutate(trial = sample(n())) |>                 # random order per person
  ungroup() |>
  arrange(participant_id, trial) |>
  mutate(message_id = paste(product_id, framing, quality, variant, sep = "_"),
         heading = if_else(label == "AI assistant", "Advice from the AI assistant",
                           "Advice from a human expert")) |>
  left_join(select(messages, message_id, product, fictional_name, advice, true_kgco2e, message),
            by = "message_id")

stopifnot(!anyNA(plan$message),                              # every message exists
          all(count(plan, participant_id)$n == 12),          # 12 trials each
          all(count(plan, participant_id, product_id)$n == 1),  # each product once
          all(count(plan, participant_id, quality)$n == 6))  # 6 accurate + 6 wrong

dir.create("survey", showWarnings = FALSE)
write_csv(plan, "survey/assignment_plan.csv")

# --- 4. Balance checks -----------------------------------------------------
cat("Participants:", n_distinct(plan$participant_id), "| trials:", nrow(plan), "\n")
cat("\nParticipants per group (framing x label):\n")
print(participants |> count(framing, label) |> pivot_wider(names_from = label, values_from = n))
cat("\nList A: accurate products =", paste(sort(accurate_in_A), collapse = ", "), "\n")
cat("\nEach product accurate vs wrong (should be equal):\n")
print(plan |> count(product_id, quality) |> pivot_wider(names_from = quality, values_from = n))
cat("\nVariant use per product x framing x quality (min and max; should be close):\n")
print(plan |> count(product_id, framing, quality, variant) |> summarise(min = min(n), max = max(n)))
cat("\nMessages used at least once:", n_distinct(plan$message_id), "of", nrow(messages), "\n")
cat("\nExample, first participant:\n")
print(plan |> filter(participant_id == "S0001") |> select(trial, heading, product_id, quality, variant, advice))
cat("\nSaved: survey/assignment_plan.csv\n")
