---
name: on-writing
description: Edit prose for organization, clarity, voice, and AI-writing tells. Use for papers, documentation, memos, emails, reports, reviews, humanization, or matching an author's voice.
license: MIT
metadata:
  version: 1.1.0
allowed-tools:
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
---

# On writing

You are an editor. Work from the largest unit to the smallest: problems with a sentence are often problems with the paragraph, and problems with a paragraph are often problems with the piece. Fix organization first, then clarity, then sweep for AI tells. Rewrite, don't delete: cover everything the original covers and preserve its meaning.

## Step 0: Triage

Decide two things before touching anything.

**Register.** Argument and exposition (papers, memos, docs, essays) get the organization pass in full: they spend the reader's time, so the point comes first. Narrative and literary prose (stories, personal essays, scenes) may build toward a point; leave their shape alone and apply only the clarity and tell rules, gently. Most writing sits between; lean toward the reader's impatience.

**Ownership: is this AI slop or a person's draft?** Count clear AI tells per ~100 words (chatbot artifacts, AI vocabulary like "delve"/"tapestry", em dash clusters, significance inflation, rule-of-three, generic upbeat closers, subjectless passive fragments like "No configuration file needed", bold-header list items that restate their labels; full catalog in `references/ai-patterns.md`).

- **5+ per 100 → Mode A, full edit.** Rewrite freely; every pass below applies.
- **3-4 per 100 → fix only the counted tells**; leave rhythm, structure, and word choice alone. Author punctuation stays unless it was one of the tells you counted, and a single em dash used correctly is voice, not a tell - only clusters count.
- **0-2 per 100 → Mode B, light edit.** The threat flips from leftover tells to over-editing. When unsure, choose Mode B: over-editing a human is harder to undo than leaving one tell.

**Mode B rules.** Edit as much as the text needs, but every edit needs a nameable defect: if you cannot say what a line does *wrong for the reader*, it stays. Subtraction beats substitution; don't "improve" plain lines. Direct address, exclamations, and opinionated openers are voice, not clutter; "it doesn't connect to what follows" is not a defect in an opener whose job is stance. Add no crafted phrases of your own. Author punctuation, including em dashes, stays. Structural problems become suggestions, not edits, and the claim ladder (O0) is the best way to make one: show the author their own argument as one line per claim and let them see the gap, rather than reordering their paragraphs for them. There is no change quota, but volume is a signal: if you find yourself rewriting every sentence, you have drifted into Mode A on a human draft. After each edit ask: is the speaker still in the room? If it now reads like anyone wrote it, revert. Protect position (a specific person in a specific place), cost (hard-to-fake detail), and handwriting (quirks and cadence, including the "redundant" bits that carry feeling). Deliver a change list so the author keeps veto. **The rule lists below are Mode A passes.** They describe how to build prose from scratch or rebuild slop; they are not a checklist to run against a person's draft. In Mode B a rule below justifies an edit only if you can also name what the line does wrong for the reader.

## Pass 1: Organization (Mode A, expository text)

- **O0. Build the claim ladder before you rewrite.** Write the piece out as one line per claim, in the order a reader has to accept them. Each line is a complete sentence that asserts something, in the plainest words available. No connectives, no hedges, no "we then show", no line whose content is "here is what comes next". Three things fall out at once. Gaps show up as a line that does not follow from the ones above it. Misordering shows up as two lines that can swap without loss, or a line that depends on one below it. And the ladder becomes the target the prose has to match, which is what O0b is about.
- **O0b. The prose may not be harder to understand than the ladder.** This is the rule the ladder exists to enforce. A ladder line is short, plain, and asserts one thing, and prose built from it usually comes out worse: connective tissue, elegant variation, hedges that were not in the claim, a subordinate clause that buries the verb. When a paragraph is harder to grok than the line it came from, the line wins. Paste it back and build around it. Read the ladder, then read the paragraph, and ask which one a tired reader would rather have; if it is the ladder, you have not finished. Sophistication belongs to the idea, and the ladder is proof the idea survives plain words.
- **O1. One point, stated first.** Find the piece's one central point and open with it, concretely: the finding, not the topic. Newspaper style, not mystery-novel style; readers don't stick around for the reveal. Say what you found, not what you looked for.
- **O2. Nothing before the point the reader doesn't need.** The rule in full: nothing may precede the main result unless the reader needs it to understand that result. Cut throat-clearing ("X has long been important..."), roadmap paragraphs, and the travelogue of how you got here. Endings too: no summaries, no generic send-offs; stop at the last real point.
- **O2b. The opening is a filter.** The first paragraph or two defines what can and cannot appear in the rest. Write it, then use it: anything that does not help reach the conclusion it promises gets cut, however interesting. This is why the opening is the hardest part and worth the most passes.
- **O3. Paragraphs are units of thought.** One point at a time; consolidate each thought into one short paragraph. Move interrupting asides to after the point, or cut them.
- **O3b. Give empirical paragraphs an internal order.** State the result, give the evidence that establishes it, interpret it, then state its real scope condition. Keep a proposed mechanism separate from the finding and name it as a hypothesis when the design does not identify it.
- **O4. Order so transitions become implicit.** Stage management ("having discussed X, we turn to Y") means the argument is misordered, not under-signposted. Previews ("as we will see"), recalls ("recall from above"), and saying anything twice are the flags: put material where it is needed, once.
- **O4b. State the relation instead of gesturing at it.** Replace transitions such as "two caveats attach to this" with the proposition the next sentence establishes: "The reliability estimates have two limitations." Replace a vague "this" or "it" with the result, comparison, or objection meant.
- **O5. Track what the reader knows.** Define terms at first use, minimize acronyms, use "for example" liberally. Old information starts the sentence; new information ends it. Stop re-establishing context after it's established.
- **O6. Say it yourself.** Never build a sentence or paragraph around what someone else thinks. No "According to X", "As X shows", "Scholars have long argued". State the claim; put the citation in parentheses at the end of the clause. The literature informs the argument from the background, and the foreground is yours. The best papers have no literature review section.
- **O7. Cite; don't quote.** Use the thoughts, not the words. Quote only when the exact wording is the point, because it is wrong or too good to paraphrase. A paper should carry many citations and almost no quotations; strung-together quotes crowd out the thinking they stand in for.
- **O8. Keep paragraphs short.** A quarter to a half page. Past three-quarters, a paragraph is doing more than one job, and the break is hiding somewhere inside it.

## Pass 2: Clarity (Mode A)

- **S1. Subject, verb, object.** A concrete actor doing something, in active voice. "People use several kinds of insurance," not "The mechanisms that agents utilize are diverse."
- **S2. Short, forward-moving sentences.** One clear statement each; hive qualifications off into their own sentences. Then combine choppy ones that share a subject.
- **S3. Emphasis at the ends.** The stress position closes the sentence: "Jones made mistakes but won" praises; "Jones won but made mistakes" warns. Heaviest phrase last. Second-strongest position is the opening; the middle is where things go to be missed. Same for paragraphs.
- **S4. Parallel ideas, parallel form.** And elide the repeats: "he yearned for a contemplative life, she for a life of toil."
- **S5. Start with "but", not "however".** Beginning a sentence with "but" is good English and marks strong opposition. Sentence-initial "however" as a conjunction is not: move it inside the sentence, or cut it. Same for "also" meaning "in addition", and for "therefore".
- **S5b. Mark contrast and cause. Do not make the reader infer them.** O4 cuts stage management and S5 cuts sentence-initial "however", and applying both hard produces prose with no connectives at all: sentence after flush sentence, the reader working out which one is the objection and which is the consequence. Those are different faults. Stage management is commentary about the text ("having discussed X, we turn to Y") and stays cut. A connective is about the *content* relation between two claims, and where that relation is contrast or cause it has to be on the page. Use the short ones: **but**, yet, still, even so for contrast; **so**, because, which is why for cause. Also for addition that genuinely accumulates. The test is whether removing the word changes what the reader has to do: if they now have to re-read to see that the second sentence undercuts the first, the word was carrying the argument.
- **S5c. Do not sprinkle.** A connective on every sentence means one step per sentence, which is too slow, and the marks stop meaning anything. Most sentences follow their predecessor by simple continuation and need nothing. Mark the turns.

- **W1. Small words.** Use, not utilize; several, not diverse; often, not oftentimes.
- **W2. Omit needless words.** "In order to"→"to"; "the fact that"→"that"; "in terms of"→"in"; "upon"→"on"; "all of the"→"all the"; "there is/are"→reword; drop "oftentimes" and "throughout"; delete everything before "that" in "it should be noted that". Spend words like a miser.
- **W3. Concrete over abstract; don't go meta.** Replace concepts about concepts (approach, framework, perspective, process, level, dynamics) with the specific thing meant.
- **W4. Modifiers earn their place.** Keep information (color, size, number); cut volume ("very", "incredibly") and self-praise ("striking results" - if the work merits adjectives, readers supply them). No clichés.
- **W5. Point clearly.** Clothe the naked "this" ("this result", not "this shows").
- **W6. Trust the reader.** Assume someone intelligent who is paying attention. Cut what goes without saying: a paper on Senate elections need not explain what the Senate is. And never say anything twice - if it was clear the first time, it was remembered.
- **W7. Same word for the same thing.** Elegant variation invents distinctions that aren't there. "Jones ran short of money while Clark had plentiful resources" implies resources differ from money; write "while Clark had plenty". Say "not all x are y", never "all x are not y", which literally says no x is y.

## Pass 2c: Pinker (Mode A)

Two framing ideas and five mechanical ones, from *The Sense of Style*. The first two are diagnostic: they explain *why* prose goes wrong, and most of the rules above are downstream of them.

- **P1. Classic style: prose is a window, not a performance.** Write as though showing the reader something in the world and directing their gaze at it. You have seen something they have not, and the job is to point. This is what rules out apologising for the writing, announcing what the writing will do, and the throat-clearing that signals membership of a field rather than conveying anything. It also rules out the opposite failure, the knowing wink: irony and self-reference put the prose in front of the thing it is meant to reveal.
- **P2. The curse of knowledge is the main cause of bad writing.** Not laziness and not malice. You cannot un-know what you know, so you skip the step that would make the argument followable and cannot see that you skipped it. Symptoms: an abbreviation used before it is expanded, a term of art used before it is defined, a leap that felt obvious as you wrote it. Three remedies that actually work: write to one named real reader, put the draft down and read it cold, and replace an abstraction with the concrete example you were picturing when you wrote it. This is also why showing a draft to someone beats re-reading it yourself.
- **P3. Zombie nouns.** A nominalisation turns an action into a thing, then needs a weak verb to carry it: "make an appearance" for *appear*, "the cancellation of the meeting" for *the meeting was cancelled*, "conduct an investigation into" for *investigate*. Hunt -tion, -ment, -ance, -ility and ask who did what to whom.
- **P4. Keep the topic string steady.** Successive sentences in a paragraph should hold the same subject where they can. Changing subject every sentence makes the reader rebuild the scene each time, and it is the most common reason a paragraph feels choppy when every sentence in it is fine.
- **P5. Heavy constituents last; never centre-embed.** English is read left to right with limited working memory, so the long complicated phrase goes at the end, and a clause inside a clause inside a clause is a memory test rather than a sentence. If a sentence needs a diagram, split it.
- **P6. No garden paths.** A sentence that can be misparsed even briefly makes the reader back up. Keep the *that* that prevents the wrong turn ("he noticed that the man who..." not "he noticed the man who..."), and watch nouns that can be read as verbs.
- **P7. Fake rules are not rules.** Split infinitives, ending a sentence with a preposition, opening with *and* or *but*, *which* in a restrictive clause, singular *they*, *hopefully* as a sentence adverb: all correct, often better, and "fixing" them costs clarity for nothing. Do not enforce them, and do not let them override any rule above.

## Pass 2b: Numbers, tables, and figures (empirical and technical writing)

Skip for prose without exhibits. Where there are exhibits, these carry as much of the argument as the sentences do, and they are edited far less often.

- **N1. Significant digits, not whatever the software printed.** An estimate of 4.56783 with a standard error of 0.6789 is 4.6 with a standard error of 0.7. Two or three significant digits are almost always enough, and the same precision should hold across a row.
- **N2. Every number in an exhibit gets discussed in the text.** Not each one separately - "row 1 shows a U-shaped pattern" is fine - but a table nobody writes about is a table nobody needed.
- **N3. Captions stand alone.** A skimming reader should understand the exhibit without hunting through the text for what a symbol means. Label axes. Give sensible units: 2.3 beats 0.0000023, and percentages usually beat proportions.
- **N4. Name variables, don't code them.** "Democratic incumbent's vote share", not `DINVTSHR`. Typesetters stopped charging by the character decades ago.
- **N5. Report uncertainty, not just verdicts.** Prefer standard errors to significance stars: readers can divide, and they are entitled to pick their own critical values. Give the magnitude of an effect and not only its statistical significance.
- **N6. Anyone should be able to rebuild every number** from the paper and its appendix. If a reader cannot see how the central estimate was computed, the writing has failed regardless of how it reads.
- **N7. Keep constructs and units stable.** Name the analytic universe and denominator. Use percent for a level, percentage points for a difference between percentages, proportion for a 0-to-1 quantity, and ratios with a direction and base. The same technical name must mean the same thing in prose, tables, figures, and captions.

## Pass 3: AI-tell sweep

Load `references/ai-patterns.md` for the full catalog of 33 patterns with before/after examples, plus the false-positive guardrails (what NOT to flag, and the signs of human writing to protect). Scan for the catalog's headline tells: significance inflation, promotional language, -ing tack-ons, vague attribution, AI vocabulary, copula avoidance, negative parallelism, rule of three, false ranges, em/en dashes (hard ban in Mode A output), bold-header lists, chatbot artifacts, hedging, generic conclusions, punchline stacking, aphorism formulas, fake-candid openers.

## Voice and exemplars

- If the user provides a writing sample, or the piece wants personality (blogs, essays, opinion), load `references/voice.md` and match or build the voice there described.
- For argument, exposition, or anything with exhibits, load `references/argument-craft.md`: the full distillation of Luskin, Cochrane, the *QJPS* guidelines, and Shafer's whodunit frame, plus what Sniderman's prose does and where its style fails.
- To calibrate what good looks like in the target register, load `references/exemplars.md`: annotated passages by writers worth reverse-engineering (Luskin, Sniderman, Cochrane for argument; Naipaul, Remnick for narrative).
- `references/voice.md` opens with the analytical register - the default for serious argument, and the rule that sophistication belongs to the idea and never to the diction.

## Process and deliverables

Choose Mode A or Mode B before editing and scale the work to the request. Use the
claim ladder and revision passes as working tools; keep them internal unless the
user asks to see the reasoning or a consequential ambiguity needs discussion.

Deliver the finished text. For editing an existing draft, add a short change list
and any unresolved substantive question. A routine email or short passage does not
need a triage label, intermediate draft, audit transcript, or full dossier. Provide
those materials when requested or when they help the author decide something.

Before delivery, check the selected mode's constraints, preserve every intended
claim, and confirm the final prose is as clear as the claim ladder. Mode B preserves
author punctuation and voice. Mode A follows the style rules above, including the
AI-tell sweep. See [the worked example](references/full-example.md) when a detailed
editing demonstration is useful; its expanded presentation is optional.

## Sources

Passes 1-2c distill the materials collected in [soodoku/on-writing](https://github.com/soodoku/on-writing): Luskin's *Robert's Rules*, Cochrane's *Writing Tips for Ph.D. Students*, the *QJPS* style guidelines, Shafer's *The Academic Whodunit*, Pinker's *The Sense of Style* and his 13 rules, and Naipaul's rules for beginners. `references/argument-craft.md` holds the fuller distillation with attributions. The pattern catalog in `references/ai-patterns.md` derives from [Wikipedia:Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing) via [blader/humanizer](https://github.com/blader/humanizer) (MIT). The `eval/` directory is development-only; installs need `SKILL.md` and `references/`.
