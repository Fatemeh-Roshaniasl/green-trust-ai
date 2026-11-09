# =============================================================
# 03_generate_messages.R
# Step 3 (full run): generate all advice messages with rules version 6.
#   12 products x 3 framings x 2 advice qualities x 3 variants = 216
#
# Every message is checked against the rules right after it is written.
# If it fails a check, it is regenerated (up to 3 attempts in total).
# The number of attempts and all failed attempts are saved, so the report
# can state exactly how often the model broke a rule.
#
# The run saves after EVERY message to output/messages.csv. If R stops
# halfway (internet drop, credit runs out), just run the script again:
# it skips the messages that are already done and continues.
#
# Model: gpt-6.1-terra (decision 9 Nov 2026, for cost; see the decisions
# table). It has no dated version, so the generation date is saved with
# every message and must be reported.
# =============================================================

library(ellmer)
library(tidyverse)

stopifnot(nzchar(Sys.getenv("OPENAI_API_KEY")))

# --- 1. Inputs ----------------------------------------------------------
rules    <- read_file("prompts/prompts.md")
products <- read_csv("data/products.csv", show_col_types = FALSE) |>
  # Unit without the weight in brackets, e.g. "one bag (about 230 g)" ->
  # "one bag": the weight is not needed and invites brackets (rule 12).
  mutate(unit_clean = str_trim(str_remove(functional_unit, "\\s*\\(.*\\)")))

model        <- "gpt-6.1-terra"
max_attempts <- 3
out_file     <- "output/messages.csv"
fail_file    <- "output/messages_failed_attempts.csv"

angles <- list(
  competence = c("1, experience", "2, method", "3, track record"),
  integrity  = c("1, independence", "2, no agenda", "3, truthfulness")
)
angle_for <- function(framing, variant) {
  if (framing == "neutral") "none" else angles[[framing]][variant]
}

# --- 2. The rule checks (same as in the test runs) -----------------------
shared_sentence <- "CO2e means that all greenhouse gases are counted as the equivalent amount of carbon dioxide."
hedges   <- "\\b(may|might|roughly|uncertain|vary|varies|approximately|around|range)\\b"
identity <- "\\b(AI|artificial intelligence|assistant|expert|model|chatbot|I am a|as an)\\b"
copied   <- "nothing held back|commercial interest|published data|plain|factual|for your reference|as requested|specified unit|recognised|carefully|as it stands|better or worse|either direction|personal or financial|highly capable|established way|proved accurate|keeps nothing|whatever it turned out|no link to the company|prior practice|calculation procedure|predictive success|absence of ties|preferred outcome|full disclosure|higher or a lower figure|stating only what|believes is correct"

check_message <- function(message, advice, name) {
  words <- str_count(message, "\\S+")
  checks <- c(
    ok_length       = between(words, 45, 60),
    ok_number       = str_detect(message, fixed(paste0("about ", advice, " kg CO2e"))),
    ok_name         = str_detect(message, fixed(name)),
    ok_shared       = str_detect(message, fixed(shared_sentence)),
    ok_plain_text   = !str_detect(message, "[*#_`]|^\\s*[-•]"),
    ok_no_hedging   = !str_detect(message, regex(hedges, ignore_case = TRUE)),
    ok_no_identity  = !str_detect(message, regex(identity, ignore_case = TRUE)),
    ok_first_person = str_detect(message, regex("\\b(I|I'll|I've|I'm|my)\\b", ignore_case = TRUE)),
    ok_no_brackets  = !str_detect(message, fixed("(")),
    ok_no_biography = !str_detect(message, regex("\\b(years?|decades?|career|trained|training|my job|profession)\\b", ignore_case = TRUE)),
    ok_no_copying   = !str_detect(message, regex(copied, ignore_case = TRUE))
  )
  list(words = words, checks = checks, pass = all(checks))
}

# --- 3. Write one message, with retries -----------------------------------
# Note: the input is called 'prod', not 'product', because the results
# table below has a column named 'product'; using one name for both made
# R read the column instead of the input (bug found on the first run).
generate_checked <- function(prod, framing, quality, variant) {
  angle  <- angle_for(framing, variant)
  advice <- if (quality == "accurate") prod$advice_accurate else prod$advice_wrong
  prompt <- paste0(
    "Write the advice message for this product.\n",
    "Product: ", prod$fictional_name, " (", prod$unit_clean, ")\n",
    "Footprint estimate to state: about ", advice, " kg CO2e\n",
    "Framing: ", framing, " (follow the description of the ", framing,
    " framing in the rules)\n",
    "Angle: ", angle, "\n",
    "Follow every fixed content rule. Reply with the message only."
  )
  for (attempt in seq_len(max_attempts)) {
    chat <- chat_openai(system_prompt = rules, model = model, echo = "none")
    text <- as.character(chat$chat(prompt, echo = "none"))
    tok  <- chat$get_tokens()
    res  <- check_message(text, advice, prod$fictional_name)
    row  <- tibble(
      message_id = paste(prod$product_id, framing, quality, variant, sep = "_"),
      product_id = prod$product_id, product = prod$product,
      fictional_name = prod$fictional_name, thesis_item = prod$thesis_item,
      framing, quality, variant, angle, advice,
      true_kgco2e = prod$true_kgco2e,
      message = text, words = res$words,
      !!!as.list(res$checks), passes_all = res$pass,
      attempt, model, created = Sys.time(),
      input_tokens = sum(tok$input), output_tokens = sum(tok$output)
    )
    if (res$pass) return(row)
    # keep a record of every failed attempt
    write_csv(row, fail_file, append = file.exists(fail_file))
    if (attempt == max_attempts) return(row)   # give up: kept, but flagged
  }
}

# --- 4. The full design, skipping messages that are already done ---------
design <- expand_grid(product_id = products$product_id,
                      framing = c("neutral", "competence", "integrity"),
                      quality = c("accurate", "wrong"),
                      variant = 1:3) |>
  mutate(message_id = paste(product_id, framing, quality, variant, sep = "_"))

done <- if (file.exists(out_file)) read_csv(out_file, show_col_types = FALSE)$message_id else character(0)
todo <- filter(design, !message_id %in% done)
cat("Messages in design:", nrow(design), "| already done:", length(done),
    "| to do now:", nrow(todo), "\n")

for (i in seq_len(nrow(todo))) {
  d   <- todo[i, ]
  row <- generate_checked(filter(products, product_id == d$product_id),
                          d$framing, d$quality, d$variant)
  write_csv(row, out_file, append = file.exists(out_file))
  cat(sprintf("[%3d/%d] %s  attempts: %d  %s\n", i, nrow(todo), row$message_id,
              row$attempt, if (row$passes_all) "ok" else "STILL FAILING (flagged)"))
}

# --- 5. Summary of the whole run -----------------------------------------
messages <- read_csv(out_file, show_col_types = FALSE)

cat("\n== Pass rate and attempts ==\n")
print(count(messages, passes_all))
print(count(messages, attempt))

cat("\n== Which checks failed (in failed attempts) ==\n")
if (file.exists(fail_file)) {
  fails <- read_csv(fail_file, show_col_types = FALSE)
  print(fails |> summarise(across(starts_with("ok_"), \(x) sum(!x))) |>
          pivot_longer(everything(), names_to = "check", values_to = "times_failed"))
}

cat("\n== Length by framing ==\n")
print(messages |> group_by(framing) |>
        summarise(mean_words = mean(words), min = min(words), max = max(words)))

cat("\n== Variant similarity by framing (Jaccard, CO2e sentence removed) ==\n")
jaccard <- function(a, b) {
  wa <- unique(str_extract_all(str_to_lower(a), "[a-z']+")[[1]])
  wb <- unique(str_extract_all(str_to_lower(b), "[a-z']+")[[1]])
  length(intersect(wa, wb)) / length(union(wa, wb))
}
print(messages |>
        mutate(core = str_remove(message, fixed(shared_sentence))) |>
        group_by(product_id, framing, quality) |>
        summarise(sim = mean(combn(core, 2, \(x) jaccard(x[1], x[2]))), .groups = "drop") |>
        group_by(framing) |>
        summarise(mean_similarity = mean(sim), min = min(sim), max = max(sim)))

cat("\n== Tokens and estimated cost (GPT-6.1 Terra: $1 in / $5 out per million) ==\n")
all_tokens <- bind_rows(messages, if (file.exists(fail_file)) fails else NULL)
print(summarise(all_tokens, input = sum(input_tokens), output = sum(output_tokens),
                cost_usd = round(input / 1e6 * 1 + output / 1e6 * 5, 2)))

cat("\nSaved: ", out_file, "\n")
