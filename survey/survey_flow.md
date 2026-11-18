# Survey flow (Step 6 mock-up)

Version: 15 Nov 2026. Decisions recorded in the plan doc's decisions table.
Assignment of groups, products, quality and variants: `survey/assignment_plan.csv`
(made by `R/06b_make_assignment.R`).

Design summary
- Between subjects (assigned once, same advisor for all trials): framing
  (neutral / competence / integrity) x source label (AI assistant / human expert).
- Within subjects: advice quality, 6 products accurate and 6 wrong (+/- 40%),
  each product shown once (no contradictions).
- No feedback during the task: carbon footprints are credence attributes that
  consumers cannot verify (Darby & Karni 1973). True values only in the debrief.
- Estimated time: about 15 minutes.

---

## Before the study: separate short session (some days earlier)

Attitudes toward AI are measured in a short, unrelated-looking survey some days
before the experiment, so that asking about AI neither primes the AI label nor
is changed by it: ATAI scale (Sindermann et al. 2021, KI - Kuenstliche
Intelligenz), 5 items, two scores (acceptance and fear of AI). The same people
are re-invited for the main study (e.g. on Prolific).
Green consumption values (optional measure, added 18 Nov) are measured in the
same earlier session, because a 15-minute carbon footprint task could shift
answers about the environment: GREEN scale (Haws, Winterich & Naylor 2014,
Journal of Consumer Psychology), 6 items. Exploratory use: whether green values
change reliance, especially on advice that makes a product look greener
(wrong advice that is too low) vs worse (too high).
Fallback rule (pre-registered): if a trait measured at the end differs between
groups, it is analysed as an outcome, not used as a moderator.

## Screen 1. Welcome and consent

> **Welcome.** In this study you will estimate the carbon footprint of 12
> everyday products and receive advice along the way. It takes about 15 minutes.
> Your answers are anonymous, and you can stop at any time. By clicking
> *Continue*, you agree to take part.

## Screen 2. Instructions (with reference products, decision D1)

> A product's **carbon footprint** is the amount of greenhouse gases released to
> make, transport and use it. It is measured in **kg CO2e**, which counts all
> greenhouse gases as the equivalent amount of carbon dioxide.
>
> To give you a sense of scale:
> - one banana: about **0.08 kg CO2e**
> - 1 litre of cow's milk: about **3 kg CO2e**
> - driving 100 km in an average car: about **18 kg CO2e**
>
> For each product, you will first give your own estimate. Then you will see
> advice, and you can keep or change your estimate. Nobody expects you to know the
> exact values; just give your best guess.

Reference sources: banana 80 g CO2e (Berners-Lee, *How Bad Are Bananas?*);
cow's milk 3.15 kg CO2e per litre (Poore & Nemecek 2018, via Our World in Data);
average UK car 0.1771 kg CO2e per km (UK Government GHG conversion factors 2025).
Note: the banana value is close to the accurate advice for bottled water (0.083);
reported as a limitation.

---

## Trials 1 to 12 (two screens each, order shuffled per participant)

### Screen A. First estimate

> **Product [k] of 12**
> What is the carbon footprint of **[functional unit] of [fictional name]**?
> Your estimate: [ ______ ] kg CO2e

Numeric input, decimals allowed, must be greater than 0.

### Screen B. Advice and final estimate

> **[heading: "Advice from the AI assistant" or "Advice from a human expert"]**
>
> *[message text from assignment_plan.csv]*
>
> Your first estimate was: **[their number]** kg CO2e
> Your final estimate: [ ______ ] kg CO2e
>
> How sure are you that your final estimate is close to the true value?
> 1 = not at all sure ... 7 = completely sure  *(decision D2: yes)*

Example (participant S0001, integrity x human expert, trial 1, wrong advice):

> **Advice from a human expert**
>
> *You asked about the carbon footprint of a pair of Duvra jeans. My estimate is
> about 47 kg CO2e. I have no ties to the company that makes them or to any
> retailer that sells them. CO2e means that all greenhouse gases are counted as
> the equivalent amount of carbon dioxide.*

(True value 33.4 kg CO2e, so this advice is 40% too high.)

---

## Screen C. About the advisor

> Think about the advisor who gave you advice in this study. How much do you
> agree? (1 = strongly disagree ... 7 = strongly agree)

| Construct | Item |
|---|---|
| Competence | The advisor was skilled at estimating carbon footprints. |
| Competence | The advisor knew a lot about these products. |
| Benevolence | The advisor cared about helping me make a good estimate. |
| Benevolence | The advisor had my interests in mind. |
| Integrity | The advisor was honest. |
| Integrity | The advisor would not try to mislead me. |
| Reliance | I would use this advisor's estimates again. |
| Persuasive intent (D3: yes) | The advisor was trying to push my estimates in a particular direction. |
| Attention check | For this statement, please select *Somewhat disagree*. |

Items adapted from the ability, benevolence and integrity model (Mayer, Davis &
Schoorman 1995). Item order randomised.

## Screen D. Manipulation checks

> Who gave you the advice in this study?
> An AI assistant / A human expert / I don't remember
>
> What did the advisor say about itself?
> Its skill or expertise / Its honesty or independence / Nothing about itself /
> I don't remember

## Screen E. About you

- Propensity to trust: short version of Frazier, Johnson & Fainshmidt (2013),
  Journal of Trust Research (exact items to be copied from the paper)
- Need for cognition: NCS-6 (Lins de Holanda Coelho, Hanel & Wolf 2020),
  6 items, one total score
- (Attitudes toward AI are measured in the earlier session, see "Before the study")
- Age, gender, highest education
- How much do you know about the carbon footprint of products?
  (1 = nothing ... 7 = a lot)

## Screen F. Debrief

> **Thank you.** Some information in this study was not what it seemed. The
> advisor label (AI assistant or human expert) was assigned at random, and all
> messages were written with an AI system. For half of the products, the advice
> was **deliberately wrong** by about 40%, to study how people respond to good
> and bad advice. Here are the best available estimates for all 12 products:
> [table of true values]. If you have questions, contact: [email].

---

## Measures computed per trial (for Step 7)

- Weight of advice: (final - initial) / (advice - initial)
- Decision improvement: initial error - final error, on a relative scale
  (error relative to the true value), because products range from 0.04 to 172 kg
- Confidence (1-7)
