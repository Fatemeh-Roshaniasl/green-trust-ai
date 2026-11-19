# Pre-registration draft: trust cues, AI labels and reliance on carbon footprint advice

Fatemeh Roshaniasl, 19 November 2026

Status: draft, not submitted to a registry. Written in the AsPredicted format.
All materials and scripts are in this repository; the reasoning behind each
choice is recorded in the project's decisions table.

## 1. Have any data been collected for this study already?

No. The materials have been built and checked (216 advice messages, an AI
rater check and two human coders), but no participant data for the experiment
exist.

## 2. What's the main question being asked or hypothesis being tested?

When people cannot check whether advice about a product's carbon footprint is
correct, does the wording of the advice, or knowing that it comes from an AI,
change how much they follow it?

H1. Advice that signals competence or integrity is followed more than neutral
advice.

H2. The AI label changes how much advice is followed compared with the
"human expert" label. The direction is left open on purpose. Algorithm aversion
predicts that AI advice is followed less; algorithm appreciation predicts that
it is followed more, and appreciation is more likely for numerical estimates
like these. The test is two-sided.

H3. Competence and integrity cues increase reliance on wrong advice compared
with neutral advice. Participants in all groups are equally unable to check the
advice, because they are assigned at random, so reliance on wrong advice in the
neutral group is the baseline for what ignorance alone produces. Any extra
reliance in the cue groups is attributed to the wording.

The study asks about trust cues in general, not which cue works best. The
confirmatory test for H1 is therefore the two cue groups together (competence
and integrity) against neutral, and the confirmatory test for H3 is the same
comparison on wrong-advice trials. The sample size is based on the H3 test.
Each cue is also compared with neutral on its own, as a secondary test with a
Holm correction for the two comparisons.

## 3. Describe the key dependent variable(s) specifying how they will be measured.

On each trial a participant gives a first estimate (kg CO2e), sees the advice
and gives a final estimate.

Reliance (weight of advice) = (final - first) / (advice - first). It is 0 when
the advice is ignored and 1 when it is adopted fully. Values above 1 are set
to 1 and values below 0 are set to 0; the trial is kept and the number of
changed values is reported. Trials where the first estimate equals the advice
cannot be computed and are left out of this measure.

Decision improvement = first error - final error, where error is the absolute
log2 ratio of the estimate to the true value (the number of doublings between
estimate and truth). This puts all 12 products, from 0.04 to 172 kg CO2e, on
the same scale. A positive value means the final estimate moved closer to the
true value.

Confidence in the final estimate, rated after each trial from 1 (not at all
sure) to 7 (completely sure).

In this study weight of advice is called reliance. The word trust is used only
for the questionnaire answers described in section 8.

## 4. How many and which conditions will participants be assigned to?

Six between-subjects groups: framing (neutral, competence, integrity) crossed
with source label ("Advice from the AI assistant" or "Advice from a human
expert"). Each participant is assigned once and keeps the same advisor for all
12 trials.

Advice quality varies within participants: for 6 products the advice is close
to the true value and for the other 6 it is about 40% too high or too low. Each
product appears once per participant, so the advisor never gives two different
numbers for the same product. Which products are wrong is counterbalanced with
two lists, participants are assigned in blocks of 12 that contain every group
and list once, the three wordings of each message rotate across blocks, and
trial order is shuffled for each person (survey/assignment_plan.csv, made by
R/06b_make_assignment.R with a fixed seed).

Participants get no feedback on the true values during the task, since
consumers cannot check carbon footprints in everyday life either. The true
values are shown in the debrief.

## 5. Specify exactly which analyses you will conduct to examine the main question/hypothesis.

One linear mixed-effects model per outcome, fitted with lme4 in R:

    outcome ~ framing * label * quality
              + (1 + quality | participant) + (1 | product) + (1 | message)

Neutral is the reference level for framing and wrong advice the reference
level for quality; label is sum-coded. Hypotheses are tested with planned
contrasts from emmeans, two-sided, alpha = .05.

- H1 (confirmatory): the mean of the competence and integrity groups vs
  neutral, averaged over label and quality, outcome reliance. Secondary:
  competence vs neutral and integrity vs neutral, Holm-corrected.
- H2: AI label vs human-expert label, averaged over framing and quality.
- H3 (confirmatory): the same cue-groups-vs-neutral contrast on wrong-advice
  trials only, averaged over label. Secondary: each cue vs neutral on
  wrong-advice trials, Holm-corrected.

The same model with decision improvement as the outcome shows whether the cues
helped or harmed the final estimates overall. If the full random-effects
structure does not converge, the random slope is removed first, then the
message intercept.

## 6. Describe exactly how outliers will be defined and handled, and your precise rule(s) for excluding observations.

Participants are excluded if they fail the attention check or finish in less
than a third of the median completion time. Participants who fail a
manipulation check are kept, because removing them would make the randomised
groups no longer comparable; pass rates are reported by group. At the trial
level, reliance is capped at 0 and 1 and undefined trials are left out (section
3). The survey accepts only positive numbers as estimates.

## 7. How many observations will be collected or what will determine sample size?

1,200 participants after exclusions (200 per group), from 1,332 recruited (111
blocks of 12), which allows for about 10% exclusions. If more than 132
participants are excluded, further complete blocks of 12 are recruited until
1,200 valid participants are reached.

The number comes from a simulation (R/07_power_simulation.R, 500 simulated
studies per sample size and effect). The smallest effect of interest is a 0.05
difference in reliance for the confirmatory H3 test (both cue groups together
against neutral, on wrong-advice trials). With 1,200 participants this test
detects that effect in 88% of simulations (35% at 300, 67% at 600, 79% at 900,
94% at 1,500), and an effect of 0.08 in all of them. The 80% target is reached
at about 900 participants; 1,200 is chosen to keep a margin in case real data
are noisier than assumed, and to allow the exploratory analyses in section 8.
The secondary tests of each cue alone (Holm, alpha .025) reach 71% for an
effect of 0.05 and 99% for 0.08, so a small difference between one cue and
neutral may be missed.

The assumptions were a baseline reliance of 0.35, which is close to the
averages reported in advice research (about 0.3 to 0.4), wrong advice followed
0.02 less than accurate advice, and standard deviations of 0.20 between people,
0.10 for each person's accurate-versus-wrong gap, 0.05 between products, 0.02
between message wordings and 0.25 between trials. If real data turn out to be
noisier, the study has less power than this, so a pilot of 30 to 60 people will
be run first to check these values. Pilot data are not part of the main sample.

## 8. Anything else you would like to pre-register?

Questionnaires. Some days before the main study, participants complete a short
separate survey with attitudes toward AI (ATAI, 5 items; Sindermann et al.,
2021) and green consumption values (GREEN scale, 6 items; Haws, Winterich &
Naylor, 2014). These are measured early because the AI label and a carbon
footprint task could change the answers. At the end of the main study
participants rate the advisor on competence, benevolence and integrity (two
items each), willingness to rely on it again, and whether it tried to push
their estimates in a particular direction. They then complete the manipulation
checks, propensity to trust (Frazier, Johnson & Fainshmidt, 2013), need for
cognition (NCS-6; Lins de Holanda Coelho, Hanel & Wolf, 2020), a self-rating
of knowledge about carbon footprints, and demographics.

Rule for measures taken at the end: if a trait differs between groups, it is
treated as an outcome of the manipulation and is not used as a moderator.

Exploratory analyses (no predictions, reported as exploratory):

- H3b: whether the cue effect on calibration (reliance on accurate minus wrong
  advice) depends on prior knowledge, measured by the self-rating and by the
  accuracy of first estimates.
- Whether cues raise confidence on wrong-advice trials.
- Whether perceived persuasive intent differs by framing.
- Whether green consumption values change reliance, separately for wrong advice
  that makes a product look greener (too low) and worse (too high).
- A causal forest (grf package) to estimate who responds differently to the
  cues and to the label, using the questionnaire measures, prior knowledge and
  demographics.
- A trust network of the advisor ratings, estimated separately for the AI and
  human-expert labels (600 participants each) and compared with a network
  comparison test.
