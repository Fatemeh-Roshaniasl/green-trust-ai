# =============================================================
# 03_test_generation.R
# Step 3 (test run 6, rules version 6, gpt-6.1-terra): generate advice messages for ONE
# product (jeans): 3 framings x 2 advice qualities x 3 variants = 18
# messages on the chosen model, then check every message against the rules
# automatically and check how different the variants are.
#
# Why a test run first? If a rule is unclear, the LLM breaks it.
# Finding that on 12 messages is cheap; finding it on 200 is not.
#
# The rules are read straight from prompts/prompts.md, so the
# documented rules and the rules the model gets are always the same.
# =============================================================

library(ellmer)
library(tidyverse)

stopifnot(nzchar(Sys.getenv("OPENAI_API_KEY")))

# --- 1. Inputs ----------------------------------------------------------
rules    <- read_file("prompts/prompts.md")      # the whole rule document
products <- read_csv("data/products.csv", show_col_types = FALSE)
jeans    <- filter(products, product_id == "P08")

# Chosen model (decision 9 Nov, after test run 2): gpt-5.5-2026-04-23.
# It is frozen at a fixed date, so it never changes and the generation can
# be reproduced. (gpt-6.1-terra wrote equally well but can be updated
# silently.)
models <- "gpt-6.1-terra"   # changed 9 Nov for cost (see decisions table)

# --- 2. One message = one fresh chat ------------------------------------
# A new chat for every message, so no message can be influenced by the
# previous one (and no earlier text is re-sent and paid for).
# Angles (rules version 4): each variant of a cue expresses a different
# aspect of it, so the 3 variants differ by design. Neutral has none.
angles <- list(
  competence = c("1, experience", "2, method", "3, track record"),
  integrity  = c("1, independence", "2, no agenda", "3, truthfulness")
)
angle_for <- function(framing, variant) {
  if (framing == "neutral") "none" else angles[[framing]][variant]
}

make_message <- function(model, framing, quality, product, variant) {
  angle  <- angle_for(framing, variant)
  advice <- if (quality == "accurate") product$advice_accurate else product$advice_wrong
  chat <- chat_openai(system_prompt = rules, model = model, echo = "none")
  prompt <- paste0(
    "Write the advice message for this product.\n",
    "Product: ", product$fictional_name, " (", product$functional_unit, ")\n",
    "Footprint estimate to state: about ", advice, " kg CO2e\n",
    "Framing: ", framing, " (follow the description of the ", framing,
    " framing in the rules)\n",
    "Angle: ", angle, "\n",
    "Follow every fixed content rule. Reply with the message only."
  )
  text <- chat$chat(prompt, echo = "none")
  tok  <- chat$get_tokens()
  tibble(model, framing, quality, variant, angle, advice,
         message = as.character(text),
         input_tokens = sum(tok$input), output_tokens = sum(tok$output),
         created = Sys.time())
}

# --- 3. Generate: 3 framings x 2 qualities x 3 variants = 18 messages ----
# Each variant is a separate fresh chat with the same instructions, so
# differences between variants show the model's natural variation.
design <- expand_grid(model   = models,
                      framing = c("neutral", "competence", "integrity"),
                      quality = c("accurate", "wrong"),
                      variant = 1:3)

messages <- pmap(design, \(model, framing, quality, variant)
                 make_message(model, framing, quality, jeans, variant)) |>
  list_rbind()

# --- 4. Automatic rule checks --------------------------------------------
shared_sentence <- "CO2e means that all greenhouse gases are counted as the equivalent amount of carbon dioxide."
hedges   <- "\\b(may|might|roughly|uncertain|vary|varies|approximately|around|range)\\b"
identity <- "\\b(AI|artificial intelligence|assistant|expert|model|chatbot|I am a|as an)\\b"
# Phrases from the rule document (version 1 or 2) or comments about the
# message itself: if they appear, the model copied instead of writing.
copied   <- "nothing held back|commercial interest|published data|plain|factual|for your reference|as requested|specified unit|recognised|carefully|as it stands|better or worse|either direction|personal or financial|highly capable|established way|proved accurate|keeps nothing|whatever it turned out|no link to the company|prior practice|calculation procedure|predictive success|absence of ties|preferred outcome|full disclosure|higher or a lower figure|stating only what|believes is correct"

messages <- messages |>
  mutate(
    words           = str_count(message, "\\S+"),
    ok_length       = between(words, 45, 60),
    ok_number       = str_detect(message, fixed(paste0("about ", advice, " kg CO2e"))),
    ok_name         = str_detect(message, fixed(jeans$fictional_name)),
    ok_shared       = str_detect(message, fixed(shared_sentence)),
    ok_plain_text   = !str_detect(message, "[*#_`]|^\\s*[-•]"),
    ok_no_hedging   = !str_detect(message, regex(hedges, ignore_case = TRUE)),
    ok_no_identity  = !str_detect(message, regex(identity, ignore_case = TRUE)),
    ok_first_person = str_detect(message, regex("\\b(I|I'll|I've|I'm|my)\\b", ignore_case = TRUE)),
    ok_no_brackets  = !str_detect(message, fixed("(")),
    ok_no_biography = !str_detect(message, regex("\\b(years?|decades?|career|trained|training|my job|profession)\\b", ignore_case = TRUE)),
    ok_no_copying   = !str_detect(message, regex(copied, ignore_case = TRUE)),
    passes_all      = ok_length & ok_number & ok_name & ok_shared &
                      ok_plain_text & ok_no_hedging & ok_no_identity &
                      ok_first_person & ok_no_brackets & ok_no_copying &
                      ok_no_biography
  )

# --- 5. Show and save ----------------------------------------------------
print(select(messages, framing, quality, variant, words, starts_with("ok_"), passes_all),
      width = Inf)

# Length by framing: the gap should now be small
print(messages |> group_by(framing) |>
        summarise(mean_words = mean(words), min = min(words), max = max(words)))

# How different are the 3 variants of each message?
# Jaccard similarity = shared words / all words used, between two texts
# (1 = identical wording, 0 = no words in common). We compare the cue part
# only, by removing the shared CO2e sentence first.
jaccard <- function(a, b) {
  wa <- unique(str_extract_all(str_to_lower(a), "[a-z']+")[[1]])
  wb <- unique(str_extract_all(str_to_lower(b), "[a-z']+")[[1]])
  length(intersect(wa, wb)) / length(union(wa, wb))
}
similarity <- messages |>
  mutate(core = str_remove(message, fixed(shared_sentence))) |>
  group_by(framing, quality) |>
  summarise(mean_similarity = mean(combn(core, 2, \(x) jaccard(x[1], x[2]))),
            .groups = "drop")
print(similarity)

# Total tokens
print(summarise(messages, input = sum(input_tokens), output = sum(output_tokens)))

# Print every message in full so we can read them
walk(seq_len(nrow(messages)), \(i) cat(
  "\n----", messages$framing[i], "|", messages$quality[i], "| angle", messages$angle[i],
  "| words:", messages$words[i], "\n", messages$message[i], "\n"))

write_csv(messages, "output/03_test_messages_v6.csv")
cat("\nSaved: output/03_test_messages_v6.csv\n")
