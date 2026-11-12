# =============================================================
# 05_make_coding_sheets.R
# Step 5: materials for the naive human coder (decisions 12 Nov).
#
# Sample: 60 messages
#   - 20 per framing; competence and integrity angles balanced (6 or 7 each)
#   - neutral: 10 from products with a precise description (size, weight,
#     "empty") and 10 from products with a plain one
#   - every product 5 times
#   - ONE quality per product (6 always accurate, 6 always wrong, 3 + 3 in
#     each precision group), so the coder never sees two different numbers
#     for the same product (no contradictions; Fatima's point, 11 Nov)
#
# Two rounds, two files, sent one after the other:
#   Round 1: persuasiveness only (1-7), no mention of cues (unprimed)
#   Round 2: the same messages in a new order; cue classification with the
#            same definitions the AI rater got
# The answer key stays with Fatima and is never sent to the coder.
# =============================================================

library(tidyverse)
if (!requireNamespace("openxlsx", quietly = TRUE)) install.packages("openxlsx")
library(openxlsx)

messages <- read_csv("output/messages.csv", show_col_types = FALSE) |>
  mutate(precise = str_detect(message, "\\bempty\\b|\\b\\d+\\s?(ml|g)\\b|\\b1 kg\\b"))

# Precision is a property of the product description (same in all framings)
prod_info <- messages |> filter(framing == "neutral") |>
  group_by(product_id) |> summarise(precise = any(precise), .groups = "drop")
stopifnot(sum(prod_info$precise) == 6)

pick <- function(pid, q, nn, nc, ni) {
  m <- filter(messages, product_id == pid, quality == q)
  bind_rows(m |> filter(framing == "neutral")    |> slice_sample(n = nn),
            m |> filter(framing == "competence") |> slice_sample(n = nc),
            m |> filter(framing == "integrity")  |> slice_sample(n = ni))
}

# --- 1. Draw a sample that meets every balance rule ----------------------
set.seed(2026)
for (try in 1:5000) {
  prod <- prod_info |> group_by(precise) |>
    mutate(quality   = sample(rep(c("accurate", "wrong"), 3)),
           n_neutral = sample(c(2, 2, 2, 2, 1, 1))) |> ungroup()
  split <- rep(NA_character_, 12)
  split[prod$n_neutral == 2] <- sample(rep(c("2c1i", "1c2i"), 4))
  prod <- prod |> mutate(
    n_comp  = case_when(n_neutral == 1 ~ 2, split == "2c1i" ~ 2, TRUE ~ 1),
    n_integ = 5 - n_neutral - n_comp)

  s <- pmap_dfr(list(prod$product_id, prod$quality, prod$n_neutral,
                     prod$n_comp, prod$n_integ), pick)

  angles_ok  <- s |> filter(framing != "neutral") |> count(framing, angle) |>
    pull(n) |> between(6, 7) |> all()
  quality_ok <- s |> count(framing, quality) |> pull(n) |> between(8, 12) |> all()
  if (angles_ok && quality_ok) break
}
cat("Balanced sample found on try", try, "\n")

stopifnot(nrow(s) == 60,
          all(count(s, framing)$n == 20),
          all(count(s, product_id)$n == 5),
          all(count(filter(s, framing == "neutral"), precise)$n == 10),
          all(count(distinct(s, product_id, quality), product_id)$n == 1))

# --- 2. Two orders, separate item numbers --------------------------------
s <- s |>
  slice_sample(prop = 1) |> mutate(round1_item = sprintf("A%02d", row_number())) |>
  slice_sample(prop = 1) |> mutate(round2_item = sprintf("B%02d", row_number()))

# --- 3. Coder instructions (same wording as the AI rater) ----------------
instr1 <- c(
  "Round 1 of 2: How persuasive is the wording?",
  "",
  "Thank you for helping. You will read 60 short messages. In each one, someone gives a carbon footprint estimate for a product.",
  "",
  "For each message, rate how persuasive the WORDING is, from 1 (not at all persuasive) to 7 (extremely persuasive).",
  "Judge only how convincing the text would be to an ordinary reader.",
  "Do NOT judge whether the number itself is correct. You do not need any knowledge about carbon footprints.",
  "",
  "- There are no right or wrong answers. Go with your first impression.",
  "- Work from top to bottom and do not go back to change earlier answers.",
  "- Type a whole number from 1 to 7 in the 'persuasiveness' column.",
  "- It takes about 15 to 20 minutes.",
  "- Please do not discuss the messages with anyone until both rounds are finished.",
  "",
  "When you are done, save the file and send it back. You will then receive Round 2.")

instr2 <- c(
  "Round 2 of 2: What does the message say about the writer?",
  "",
  "These are the same 60 messages in a new order. Please do not look back at Round 1.",
  "",
  "For each message, choose which kind of statement about the writer the message contains:",
  "- competence: the writer signals skill or expertise (for example experience, method or past success with such estimates)",
  "- integrity: the writer signals honesty or independence (for example no ties to the seller, no preference for a high or low figure, or a commitment to saying only what they believe is correct)",
  "- neutral: the message gives the estimate without saying anything about the writer's skill, honesty or independence",
  "",
  "- Choose exactly one for each message, from the drop-down list in the 'cue' column.",
  "- Work from top to bottom and go with your first impression.",
  "- It takes about 15 minutes.",
  "",
  "When you are done, save the file and send it back. Thank you!")

# --- 4. Build the Excel files -------------------------------------------
make_sheet <- function(items, msgs, answer_col, instr, file, list_values = NULL) {
  wb <- createWorkbook()
  addWorksheet(wb, "Instructions")
  writeData(wb, "Instructions", instr, colNames = FALSE)
  setColWidths(wb, "Instructions", cols = 1, widths = 120)
  addStyle(wb, "Instructions", createStyle(textDecoration = "bold", fontSize = 13), rows = 1, cols = 1)

  addWorksheet(wb, "Messages")
  df <- tibble(item = items, message = msgs, !!answer_col := NA)
  writeData(wb, "Messages", df, headerStyle = createStyle(textDecoration = "bold"))
  setColWidths(wb, "Messages", cols = 1:3, widths = c(8, 90, 16))
  addStyle(wb, "Messages", createStyle(wrapText = TRUE, valign = "top"),
           rows = 2:61, cols = 1:3, gridExpand = TRUE)
  freezePane(wb, "Messages", firstRow = TRUE)

  if (is.null(list_values)) {
    dataValidation(wb, "Messages", cols = 3, rows = 2:61, type = "whole",
                   operator = "between", value = c(1, 7))
  } else {
    addWorksheet(wb, "Options", visible = FALSE)
    writeData(wb, "Options", list_values, colNames = FALSE)
    dataValidation(wb, "Messages", cols = 3, rows = 2:61, type = "list",
                   value = sprintf("'Options'!$A$1:$A$%d", length(list_values)))
  }
  saveWorkbook(wb, file, overwrite = TRUE)
}

dir.create("coding/to_send", recursive = TRUE, showWarnings = FALSE)

r1 <- arrange(s, round1_item)
make_sheet(r1$round1_item, r1$message, "persuasiveness", instr1,
           "coding/to_send/round1_persuasiveness.xlsx")

r2 <- arrange(s, round2_item)
make_sheet(r2$round2_item, r2$message, "cue", instr2,
           "coding/to_send/round2_cues.xlsx",
           list_values = c("competence", "integrity", "neutral"))

# Answer key: NEVER send this to the coder
s |> select(round1_item, round2_item, message_id, product_id, framing, angle,
            quality, precise, words) |>
  arrange(round1_item) |>
  write_csv("coding/answer_key.csv")

# --- 5. Check the sample --------------------------------------------------
cat("\nFraming x quality:\n");  print(count(s, framing, quality) |> pivot_wider(names_from = quality, values_from = n))
cat("\nAngles:\n");             print(count(filter(s, framing != "neutral"), framing, angle))
cat("\nNeutral by precision:\n"); print(count(filter(s, framing == "neutral"), precise))
cat("\nProducts (quality, n):\n"); print(count(s, product_id, quality))
cat("\nSaved: coding/to_send/round1_persuasiveness.xlsx, coding/to_send/round2_cues.xlsx, coding/answer_key.csv\n")
