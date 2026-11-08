# =============================================================
# 00_test_openai.R
# Step 0c: send one prompt to OpenAI (the message WRITER) and get one
# reply back. This proves the key works before we build anything bigger.
# Run all at once: Cmd+Shift+Enter (or the Source button).
#
# The key is read from .Renviron. Never paste a key into a script:
# scripts go to GitHub, .Renviron does not (it is listed in .gitignore).
# =============================================================

library(ellmer)

# --- 1. Is the key visible to R? -------------------------------------
# nzchar() is TRUE if the variable is set. We print TRUE/FALSE only,
# never the key itself. stopifnot() halts the script with a clear
# message if the key is missing, instead of failing later.
stopifnot("OPENAI_API_KEY is missing: check .Renviron and restart R" =
            nzchar(Sys.getenv("OPENAI_API_KEY")))

# --- 2. Which models can this key use? -------------------------------
# Model names change over time, so we look them up instead of guessing.
# For the project we will pin one dated version and report it.
print(models_openai()$id)

# --- 3. One test call -------------------------------------------------
# system_prompt sets the role the model plays.
# model: GPT-6 Luna, the cheapest model, is enough for a test.
generator <- chat_openai(
  system_prompt = "You are a helpful assistant. Answer in one sentence.",
  model = "gpt-6-luna"   # if this errors, copy the exact id containing "luna" from the list printed above
)
reply_gen <- generator$chat(
  "Roughly how many kg of CO2 does producing one cotton T-shirt cause?"
)

# --- 4. What did it cost, and which exact model answered? -------------
# get_tokens() shows input/output tokens and the estimated cost in USD.
print(generator$get_tokens())
print(generator)   # shows the exact model id used

# --- 5. Save the evidence that the OpenAI part of Step 0 works --------
writeLines(
  c(paste("Date:", Sys.time()),
    paste("Provider: OpenAI, model:", generator$get_model()),
    paste("Reply:", reply_gen)),
  "output/00_test_openai_result.txt"
)
cat("\nSaved: output/00_test_openai_result.txt\n")
