# green-trust-ai: trust in AI advice for sustainable choices

An independent research project by Fatemeh Roshaniasl. It builds and checks the materials for an online experiment on how people use carbon-footprint advice from an AI, and plans the experiment in a pre-registration draft. No participant data has been collected yet.

## Background and question

The project continues her MSc thesis, "The Structure of Sustainability Cognition in Consumers: A Psychological Network Analysis of Products and Companies" (Uppsala University, 2026). In that thesis, environmental value and green trust (belief that a company's environmental claims are credible) were tightly connected in people's judgements of companies. Carbon footprints are hard to check for yourself, so in this kind of choice people have to rely on whoever gives them the number. More and more often that will be an AI.

The question is: when an LLM gives advice about a product's carbon footprint, do trust cues in its wording, and knowing the advice comes from an AI, change how much people follow it? And does that trust help their estimates, or does it also make them follow advice that is wrong?

The full write-up is in [report/Roshaniasl_green-trust-ai_report.pdf](report/Roshaniasl_green-trust-ai_report.pdf) (7 pages). The planned analysis is in [prereg/preregistration_draft.md](prereg/preregistration_draft.md).

## Work so far

1. Twelve fictional products (for example a "Brenik tote bag") with carbon footprints based on published figures. Sources are in `data/products_sources.csv`.
2. Fixed content rules and three framings for the advice: neutral, competence and integrity (`prompts/prompts.md`).
3. 216 advice messages, generated in R with `ellmer` and an OpenAI model: 12 products, 3 framings, accurate or wrong advice (40% off), and 3 wordings of each. Every message passed automatic checks on length, the number and the product name.
4. An LLM rater (Claude Haiku 4.5) scored each message for persuasiveness and trust cues. When the rater was told which framing to look for, the gap between framings was inflated, so the check was rerun without that information.
5. Two human coders rated the messages blind. Agreement with the intended cue was kappa = .72 and .85; agreement between the coders was kappa = .57.
6. Final materials: two product names changed, a survey flow, and an assignment plan that gives every participant each product once.
7. A simulation-based power analysis for the mixed-effects model. With 1,200 participants after exclusions, power for the main trust-cue test is about 88% at the smallest effect of interest.

## Folders

- `R/` scripts, numbered in the order they are run
- `data/` the products and the sources for their footprints
- `prompts/` the content rules and framings given to the generator
- `output/` generated messages, rater scores, coder results, power results, and `plots/`
- `coding/` the coding sheets sent to the human coders and the answer key. The coders' filled-in files are not included, because the Excel files store their names.
- `survey/` the survey flow and the assignment plan
- `prereg/` the pre-registration draft (not yet submitted)
- `report/` the project report as PDF

## Running the code

The scripts are written in R. Run them from the project folder (open `green-trust-ai.Rproj` in RStudio), in number order. The `00_` scripts install packages and test the API connections.

Scripts 03, 04 and 04b call paid APIs. They need two keys in a file called `.Renviron` in the project folder:

```
OPENAI_API_KEY=your-key-here
ANTHROPIC_API_KEY=your-key-here
```

`.Renviron` is listed in `.gitignore` and should never be committed. Model output changes from run to run, so a new run of 03 will give different wordings from the ones in `output/messages.csv`. Everything from step 05 on uses the saved files and needs no keys.

`R/07_power_simulation.R` takes a long time. Run it first with `quick_test <- TRUE` to see the time per fit, then set it to `FALSE` for the full run.

Main R packages: ellmer, tidyverse, lme4, openxlsx, readxl.
