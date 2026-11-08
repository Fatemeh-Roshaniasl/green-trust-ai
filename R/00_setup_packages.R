# =============================================================
# 00_setup_packages.R
# Step 0a: install the packages the project needs.
# Run this ONCE. After that, the other scripts only call library().
# =============================================================

# The packages and why we need them:
#   ellmer    - talks to an LLM from R (sends a prompt, gets text back)
#   tidyverse - data handling (dplyr, readr, tidyr) and plots (ggplot2)
#   irr       - inter-rater agreement, e.g. Cohen's kappa (Step 5)
#   usethis   - small helpers, e.g. opening the .Renviron file for the API key
needed <- c("ellmer", "tidyverse", "irr", "usethis")

# Install only the ones that are missing, so re-running is harmless
missing <- needed[!needed %in% rownames(installed.packages())]
if (length(missing) > 0) install.packages(missing)

# Check: load each one and print its version.
# If a line errors here, the install did not work.
for (pkg in needed) {
  library(pkg, character.only = TRUE)
  cat(pkg, as.character(packageVersion(pkg)), "\n")
}

# Record the R version for the report's methods section
cat("R version:", R.version.string, "\n")
