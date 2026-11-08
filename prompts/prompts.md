# Step 2: Message rules (version 1, agreed 8 Nov 2026)

These rules are given to the LLM that writes the advice messages (Step 3).
Everything in "Fixed content rules" is identical for every message. Only the
"Trust framing" block changes between conditions.

## Fixed content rules (all messages)

1. Plain text only: no markdown, bullet points, bold, emojis or headings.
2. One short paragraph of 40 to 60 words.
3. Name the product exactly as given (its fictional brand name and unit).
4. State the footprint estimate exactly as given, written as
   "about X kg CO2e", once, without changing the number.
5. No other facts: the estimate is the only product information. Do not
   explain where the emissions come from. Every message includes this
   shared sentence, word for word:
   "CO2e means that all greenhouse gases are counted as the equivalent
   amount of carbon dioxide."
   It explains the unit, is true for every product, and lets the neutral
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

## Trust framings (one per message)

Based on Mayer, Davis & Schoorman (1995): trust rests on perceived
ability, benevolence and integrity. The plan uses ability (here called
competence) and integrity, plus a neutral baseline.

**Neutral.** State the estimate plainly and factually. No statements about
how the estimate was made, about the advisor's skills or about the
advisor's honesty or motives.

**Competence (ability cue).** Signal expertise and a careful method: refer
to life-cycle assessment and published data, use precise and confident
wording. No statements about honesty or motives.

**Integrity (honesty cue).** Signal honesty and independence: say the
estimate is given straightforwardly, with no commercial interest in the
product and nothing held back. No statements about expertise or method,
and no hedging (rule 7): honesty is shown through openness about motives,
not through admitting uncertainty.

## Template given to the LLM for each message

    Write the advice message for this product.
    Product: {fictional_name} ({functional_unit})
    Footprint estimate to state: about {advice_value} kg CO2e
    Framing: {framing name and its description above}
    Follow every fixed content rule.
