# Step 2: Message rules (version 6, agreed 9 Nov 2026)

These rules are given to the LLM that writes the advice messages (Step 3).
Everything in "Fixed content rules" is identical for every message. Only the
"Trust framing" changes between conditions.

Version history: version 1 (8 Nov) produced messages that copied the framing
descriptions word for word, padded the neutral version with comments about
the message itself, and sounded robotic. Version 2 added rules 10 to 13.
Version 2 (9 Nov) gave natural messages, but cue versions were about 12 words
longer than neutral ones and the framing descriptions still leaked stock
phrases. Version 3 adds a cue-free closing sentence to neutral messages,
narrows the length to 45 to 60 words, and rewrites the framing descriptions
as the impression the reader should form, without ready-made phrases.
Version 3 (9 Nov) worked for neutral and competence, but all integrity
variants reused one phrase and were too similar. Version 4 gives each of the
three variants of a cue its own angle, so variants differ by design.
Version 4 worked on gpt-5.5, but the generator was changed to gpt-6.1-terra
for cost, and Terra copied ready-made phrases from the descriptions
("proved accurate", "either direction"). Version 5 writes the framings and
angles as short abstract signals with no sentence to copy.
Version 5 stopped the copying, but reading showed meaning problems: "no
agenda" drifted to not steering the reader's decision, "openness" sounded
odd for a number-only message, and one message claimed "years" of work,
which fits only the human label. Version 6 clarifies no agenda, replaces
openness with truthfulness, and adds rule 14.

## Fixed content rules (all messages)

1. Plain text only: no markdown, bullet points, bold, emojis or headings.
2. One short paragraph of 45 to 60 words.
3. Name the product exactly as given (its fictional brand name and unit).
4. State the footprint estimate exactly as given, written as
   "about X kg CO2e", once, without changing the number.
5. No other facts: the estimate is the only product information. Do not
   explain where the emissions come from. Every message includes this
   shared sentence, word for word:
   "CO2e means that all greenhouse gases are counted as the equivalent
   amount of carbon dioxide."
   It explains the unit, is true for every product, and helps the neutral
   message reach the length range without padding.
6. Never mention who or what the advisor is (no "As an AI", no job title,
   no name): the same text is later shown with the label "AI assistant" or
   "human expert", so it must fit both.
7. No uncertainty or hedging words in any message ("may", "roughly",
   "uncertain", "estimates vary", ranges). The number is stated as given;
   the word "about" in rule 4 is the only approximation word, and it is the
   same in every message.
8. No advice about what to buy; the message only gives the estimate.
9. Do not mention other products, prices, brands or this study.
10. Voice: write as an advisor speaking directly to the reader, in natural,
    conversational English. Use the first person ("I", "my estimate") in
    every message, including the neutral one.
11. Opening: begin by referring, in your own words, to the reader's question
    about this product's carbon footprint (for example, that they asked
    about it).
12. Name the product naturally inside a sentence (for example "a pair of
    Duvra jeans", "a 500 g bag of Morrow coffee beans"), not with the unit
    in brackets.
13. Own words only: express the framing in your own words. Never reuse
    phrases from these rules, and never comment on the message itself or
    on how it is written (no "plain", "factual", "for your reference",
    "as requested", "in the specified unit").
14. No time spans, career or biography claims (no "years", "career",
    "trained", "my job"): such claims fit only one of the two labels.

## Trust framings (one per message)

Based on Mayer, Davis & Schoorman (1995): trust rests on perceived
ability, benevolence and integrity. The plan uses ability (here called
competence) and integrity, plus a neutral baseline. Each framing is
expressed in one or two sentences between the opening and the
CO2e sentence.

**Neutral.** Give the estimate and nothing that signals skill, method,
honesty or motives. The reader learns the number, not anything about the
advisor. Add one short closing sentence that simply restates the estimate
or the product in other words, so the message has a similar length to the
other framings; this sentence must not add any information or any cue.

**Competence (ability cue).** The reader should come away believing the
advisor is good at this task. Invent the wording yourself. Do not mention
honesty, motives or independence.
Angles (one per variant; the task says which to use):
- Angle 1, experience. Signal: extensive prior practice with this kind of
  task.
- Angle 2, method. Signal: use of the standard calculation procedure for
  product footprints.
- Angle 3, track record. Signal: past predictive success.

**Integrity (honesty cue).** The reader should come away believing the
advisor is truthful and independent. Invent the wording yourself. Do not
mention skill or method, and do not hedge (rule 7).
Angles (one per variant; the task says which to use):
- Angle 1, independence. Signal: absence of ties to the producer or
  retailer.
- Angle 2, no agenda. Signal: no preference for a higher or a lower
  figure.
- Angle 3, truthfulness. Signal: commitment to stating only what one
  believes is correct.

Neutral messages have no angle.

## Task given to the LLM for each message

    Write the advice message for this product.
    Product: {fictional_name} ({functional_unit})
    Footprint estimate to state: about {advice_value} kg CO2e
    Framing: {framing name}
    Angle: {angle number and name, or "none" for neutral}
    Follow every fixed content rule. Reply with the message only.
