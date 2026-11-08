# =============================================================
# 00_test_anthropic.R
# Step 0d: send one prompt to Anthropic Claude (the blind RATER) and
# get one reply back. Run after ANTHROPIC_API_KEY is in .Renviron.
# Run all at once: Cmd+Shift+Enter (or the Source button).
# =============================================================

library(ellmer)

# --- 1. Is the key visible to R? -------------------------------------
stopifnot("ANTHROPIC_API_KEY is missing: check .Renviron and restart R" =
            nzchar(Sys.getenv("ANTHROPIC_API_KEY")))

# --- 2. Which models can this key use? -------------------------------
print(models_anthropic()$id)

# --- 3. One test call, shaped like a rating task ----------------------
# The rater gets a short text and must answer with one word: this is
# the format we will use in Step 4, so the test already checks that
# the model follows a strict answer format.
rater <- chat_anthropic(
  system_prompt = "You rate short texts. Answer with one word only.",
  model = "claude-haiku-5-5"   # if this errors, copy an id containing "haiku" from the list printed above
)
test_text <- "Producing one cotton T-shirt causes roughly 2 to 7 kg of CO2."
reply_rate <- rater$chat(
  paste("Does this text mention a number? Answer yes or no.\n\n", test_text)
)

# --- 4. Cost and exact model ------------------------------------------
print(rater$get_tokens())
print(rater)

# --- 5. Save the evidence --------------------------------------------
writeLines(
  c(paste("Date:", Sys.time()),
    paste("Provider: Anthropic, model:", rater$get_model()),
    paste("Rated text:", test_text),
    paste("Reply:", reply_rate)),
  "output/00_test_anthropic_result.txt"
)
cat("\nSaved: output/00_test_anthropic_result.txt\n")
