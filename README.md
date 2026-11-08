# green-trust-ai: trust in AI advice for sustainable choices

Independent project by Fatemeh Roshaniasl. It continues her MSc thesis,
"The Structure of Sustainability Cognition in Consumers: A Psychological
Network Analysis of Products and Companies" (Uppsala University, 2026).
The thesis found that, for companies, environmental value and green trust
(belief in the credibility of environmental claims) were tightly connected.
This project asks what happens to that credibility judgement when advice
about a sustainable choice comes from an AI.

**Question.** When an LLM gives advice about a sustainable product choice, do
trust cues in its wording and knowing the advice comes from AI change how much
people follow it, and does that trust help or hurt their decisions?

## Folders
- `R/` scripts, numbered in the order they are run
- `data/` input data (e.g. `products.csv`)
- `prompts/` the fixed content rules and trust framings (`prompts.md`)
- `output/` generated messages, check reports, figures

## Steps
0. Setup: packages, API key, test call
1. Scenario: 12 fictional products with CO2 footprints
2. Message rules
3. Generation with `ellmer`
4. Automatic checks (LLM rater)
5. Human coding (Cohen's kappa)
6. Final materials (survey flow)
7. Experiment plan and simulation-based power analysis
8. Report
