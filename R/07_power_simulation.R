# =============================================================
# 07_power_simulation.R
# Step 7, part 4: how many participants are needed?
#
# Idea: invent realistic fake data many times, analyse each data set with
# the planned model, and count how often the model finds the effect we
# built in. That share is the power. Repeat for several sample sizes.
#
# Decisions (18 Nov): H3 sets the sample size (competence vs neutral on
# WRONG-advice trials, the hardest test); smallest effect of interest
# 0.05 in weight of advice, optimistic scenario 0.08; target power 80%,
# alpha 5%. Fatima chose sensitivity over cost.
#
# Assumptions (all stated so they can be questioned and varied):
#   b0        0.35  average weight of advice, neutral, accurate advice
#                   (advice research: typically about 0.3; a meta-analysis
#                   found 0.39, Bailey et al. 2023)
#   b_wrong  -0.02  people follow wrong advice slightly less (weak
#                   calibration, since they mostly cannot check)
#   delta           effect of a trust cue (competence AND integrity), the
#                   same on accurate and wrong advice (H1 and H3)
#   label     0     source label effect unknown (H2 two-sided); not used
#                   for the sample size
#   sd_person 0.20  people differ in how much they follow advice
#   sd_slope  0.10  people differ in their accurate-vs-wrong gap
#   sd_product 0.05 products differ a little
#   sd_resid  0.25  trial-to-trial noise
#   WOA is capped at 0 and 1, as planned (so observed effects are a bit
#   smaller than delta, which is realistic).
#
# Test: lmer(woa ~ framing * label * quality + (1 + quality | participant)
#            + (1 | product)); with neutral and wrong as reference levels
# and sum-coded label, the coefficient "framingcompetence" is exactly the
# H3 contrast. p-value from the normal approximation (large samples).
#
# Run first with quick_test = TRUE (a few fits, prints the time per fit),
# then set it to FALSE for the full run. Results are saved after every
# simulation and the script can be resumed.
# =============================================================

library(tidyverse)
library(lme4)

quick_test   <- FALSE                      # set to FALSE for the full run
n_sims       <- 500                       # per sample size and effect size
sample_sizes <- c(300, 600, 900, 1200, 1500)   # multiples of 12 (balanced blocks)
effects      <- c(0.05, 0.08)
out_file     <- "output/07_power_results.csv"

b0 <- 0.35; b_wrong <- -0.02
sd_person <- 0.20; sd_slope <- 0.10; sd_product <- 0.05; sd_resid <- 0.25

simulate_one <- function(n, delta) {
  cells  <- expand_grid(framing = c("neutral", "competence", "integrity"),
                        label = c("AI", "human"), list = c("A", "B"))
  people <- map_dfr(seq_len(n / 12), \(b) cells) |>
    mutate(pid = row_number(), u0 = rnorm(n, 0, sd_person), u1 = rnorm(n, 0, sd_slope))
  prods  <- tibble(product = 1:12, v = rnorm(12, 0, sd_product), in_A = product <= 6)

  d <- expand_grid(pid = people$pid, product = 1:12) |>
    left_join(people, by = "pid") |>
    left_join(prods, by = "product") |>
    mutate(wrong = if_else(list == "A", !in_A, in_A),     # 6 accurate + 6 wrong each
           cue   = framing != "neutral",
           mu    = b0 + wrong * b_wrong + cue * delta + u0 + wrong * u1 + v,
           woa   = pmin(pmax(mu + rnorm(n(), 0, sd_resid), 0), 1),
           framing = factor(framing, levels = c("neutral", "competence", "integrity")),
           quality = factor(if_else(wrong, "wrong", "accurate"), levels = c("wrong", "accurate")),
           label   = factor(label))
  contrasts(d$label) <- contr.sum(2)

  fit <- suppressMessages(suppressWarnings(
    lmer(woa ~ framing * label * quality + (1 + quality | pid) + (1 | product),
         data = d, control = lmerControl(calc.derivs = FALSE))))
  cf <- coef(summary(fit))["framingcompetence", ]
  tibble(estimate = cf[["Estimate"]], t = cf[["t value"]],
         p = 2 * pnorm(-abs(cf[["t value"]])))
}

# --- Quick test: time a few fits ------------------------------------------
if (quick_test) {
  set.seed(1)
  t0 <- Sys.time()
  print(map_dfr(1:3, \(i) simulate_one(600, 0.05)))
  secs <- as.numeric(difftime(Sys.time(), t0, units = "secs")) / 3
  cat(sprintf("\nAbout %.1f seconds per fit at n = 600.\n", secs))
  cat(sprintf("Full run (%d fits) would take very roughly %.0f minutes.\n",
              n_sims * length(sample_sizes) * length(effects),
              secs * n_sims * length(effects) * sum(sample_sizes / 600) / 60))
  cat("If that is acceptable, set quick_test <- FALSE and run again.\n")
} else {

# --- Full run (resumable) --------------------------------------------------
grid <- expand_grid(n = sample_sizes, delta = effects, sim = seq_len(n_sims)) |>
  mutate(run_id = paste(n, delta, sim, sep = "_"))
done <- if (file.exists(out_file)) read_csv(out_file, show_col_types = FALSE)$run_id else character(0)
todo <- filter(grid, !run_id %in% done)
cat("Simulations planned:", nrow(grid), "| done:", length(done), "| to do:", nrow(todo), "\n")

for (i in seq_len(nrow(todo))) {
  g <- todo[i, ]
  set.seed(2026 + match(g$run_id, grid$run_id))      # reproducible per simulation
  res <- bind_cols(g, simulate_one(g$n, g$delta))
  write_csv(res, out_file, append = file.exists(out_file))
  if (i %% 20 == 0 || i == nrow(todo)) cat(sprintf("[%4d/%d] done\n", i, nrow(todo)))
}

# --- Results: power curve --------------------------------------------------
results <- read_csv(out_file, show_col_types = FALSE)
power <- results |> group_by(n, delta) |>
  summarise(power = mean(p < .05), mean_estimate = mean(estimate), sims = n(), .groups = "drop")
cat("\n== Power for H3 (competence vs neutral on wrong advice) ==\n")
print(power |> mutate(power = round(power, 2), mean_estimate = round(mean_estimate, 3)))

p <- ggplot(power, aes(n, power, colour = factor(delta))) +
  geom_hline(yintercept = 0.8, linetype = "dashed") +
  geom_line() + geom_point(size = 2) +
  scale_y_continuous(limits = c(0, 1), labels = scales::percent) +
  labs(x = "Participants", y = "Power (share of simulations finding the effect)",
       colour = "True effect\n(weight of advice)",
       title = "Power for H3: competence vs neutral on wrong advice") +
  theme_minimal()
ggsave("output/plots/07_power_curve.png", p, width = 7, height = 4.5, dpi = 150)
print(p)
cat("\nSaved:", out_file, "and output/plots/07_power_curve.png\n")
}
