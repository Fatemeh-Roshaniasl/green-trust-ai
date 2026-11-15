# =============================================================
# 06_rename_products.R
# Step 6 fix (decision 15 Nov): two fictional brand names sounded "green"
# and could act as a hidden sustainability cue:
#   Verdala  (tote bag, P01; contains "verde")  -> Brenik
#   Solmarka (tomatoes, P04; "sun field")       -> Gorvin
# Only the brand name changes; wording, numbers and checks are unchanged.
# Steps 4 and 5 were run with the old names (reported in the report).
# Old run logs (failed attempts, stopped run) are left as the record.
# Safe to run more than once: if the old names are gone, nothing changes.
# A copy of messages.csv with the old names: output/messages_old_names.csv
# =============================================================

library(tidyverse)

swap <- c("Verdala" = "Brenik", "Solmarka" = "Gorvin")
files <- c("output/messages.csv", "data/products.csv", "data/products_sources.csv")

if (!file.exists("output/messages_old_names.csv"))
  file.copy("output/messages.csv", "output/messages_old_names.csv")

for (f in files) {
  x <- read_lines(f)
  for (old in names(swap)) x <- str_replace_all(x, fixed(old), swap[[old]])
  write_lines(x, f)
}

# Checks: old names gone, new names present 18 times each in messages
m <- read_csv("output/messages.csv", show_col_types = FALSE)
stopifnot(!any(str_detect(read_lines(files), "Verdala|Solmarka")),
          sum(str_detect(m$message, "Brenik")) == 18,
          sum(str_detect(m$message, "Gorvin")) == 18)
cat("Renamed: Verdala -> Brenik, Solmarka -> Gorvin. All checks passed.\n")
