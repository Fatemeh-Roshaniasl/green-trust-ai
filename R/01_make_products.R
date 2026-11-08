# =============================================================
# 01_make_products.R
# Step 1: build the 12 products used in the advice task.
#
# Input : data/products_sources.csv  (typed by hand, one published
#         footprint per product, with its source and notes)
# Output: data/products.csv          (adds the wrong advice values)
#
# Design decisions (see "Decisions and reasoning" in the plan doc):
# - 6 products come from Fatima's thesis Phase 1 free-association task
#   (coal left out: consumers don't buy it), 6 are new everyday items.
# - Wrong advice is off by 40%: half the products too high (x 1.4),
#   half too low (x 0.6), balanced within thesis and new items, so
#   participants cannot learn that the advisor always over- or
#   under-states.
# - The split is random but reproducible: set.seed() fixes it, so
#   rerunning the script always gives the same assignment.
# =============================================================

library(tidyverse)

products <- read_csv("data/products_sources.csv", show_col_types = FALSE)

# --- 1. Checks on the input ------------------------------------------
stopifnot(nrow(products) == 12,               # exactly 12 products
          !anyDuplicated(products$product_id), # unique ids
          all(products$true_kgco2e > 0),       # footprints are positive
          sum(products$thesis_item) == 6)      # 6 thesis items, 6 new

# --- 2. Assign the direction of the wrong advice ----------------------
# Within each group (thesis / new) we shuffle three "high" and three
# "low" labels. group_by() + sample() does this separately per group.
set.seed(2026)
products <- products |>
  group_by(thesis_item) |>
  mutate(wrong_direction = sample(rep(c("high", "low"), each = 3))) |>
  ungroup()

# --- 3. Compute the advice values --------------------------------------
# signif(x, 2) rounds to 2 significant digits, which is how a real
# advisor would state a number ("about 3.9 kg", "about 170 kg").
products <- products |>
  mutate(
    wrong_factor     = if_else(wrong_direction == "high", 1.4, 0.6),
    advice_accurate  = signif(true_kgco2e, 2),
    advice_wrong     = signif(true_kgco2e * wrong_factor, 2),
    # check: how far the wrong advice really is from the truth after rounding
    wrong_error_pct  = round(100 * (advice_wrong - true_kgco2e) / true_kgco2e)
  )

# --- 4. Look at the result and save it ----------------------------------
print(products |>
        select(product_id, product, thesis_item, true_kgco2e,
               advice_accurate, wrong_direction, advice_wrong, wrong_error_pct),
      n = 12)

# The balance check: should show 3 high and 3 low in each group
print(count(products, thesis_item, wrong_direction))

write_csv(products, "data/products.csv")
cat("\nSaved: data/products.csv\n")
