# Parsing: separate from fetching, marker scans, and what to keep

## The parse reads `raw/` and nothing else

Fetching is expensive and cannot be repeated on demand; parsing is cheap and will be repeated
every time a shape you did not anticipate turns up. So the fetcher writes the portal's answer
**verbatim** (the JSON object, the HTML cell, the PDF bytes) and the parser is a separate
program that reads only those files and writes the typed table. A parser change never costs a
refetch, and the raw file is the audit trail when a parsed value looks wrong.

Both land-record repos are laid out this way: `fetch_*.py` → `raw/<unit>.jsonl.gz` →
`parse_*.py` → `raw/tenants.parquet` / `raw/owners.parquet`.

## Marker scan, not whole-cell regex

Government records put several fields in one free-text cell with inline markers:

```
ଅଇଁଠୁ ଦ୍ଵିବେଦୀ ପି: ବୈଦ୍ୟନାଥ ଦ୍ଵିବେଦୀ ଜା: ବ୍ରାହ୍ମଣ ବା: ନିଜଗାଁ        (Odisha: name, father, caste, residence)
गुलाब सिंह चीता पुत्र अमर सिंह  हिस्सा- 2/3 जाति- मेर(मेहरात, चीता) सा. अजयसर खातेदार   (Rajasthan)
```

A single regex has to describe every shape the cell can take, and it drops every row it does
not describe, silently and selectively. The Kerala roll parser lost 39% of its rows, a
Christian-heavy slice, to one rule about marks digits. Scan for markers instead: find each
marker's position, slice between them, and let a missing marker yield `None` for that field
while the others still parse. Shapes seen in the first week that a regex would have dropped: a
husband where the father belongs, a comma-separated list of co-tenants in the name slot, a
parenthesised gloss with commas inside the caste, an institutional owner with no relation and
no caste, an urban address block where the village belongs.

## Keep the raw cell on every row

Every parsed row carries the unparsed text it came from (`raw_cell`, `raw_line`). It is how a
reviewer audits a parse without the checkpoint files, and how the next shape is found: sort the
rows where a field is `None` by `raw_line` and read the top twenty.

## Normalise Unicode first, then key

Indic text arrives in mixed normalisation forms and with nukta variants (`ड़` as one code point
or as `ड` + `़`). `unicodedata.normalize("NFC", s)` before anything else, then a project-level
key function for matching (drop spaces and punctuation, fold known variants such as `ङ/ड़`).
Never strip a sex or honorific suffix in the key: dropping `देवी` matched a wife to a man with
her given name.

## Schedules, aliases, and the label the clerk wrote

A caste string is whatever the clerk wrote: `हरिजन`, `मेर(मेहरात काठात, चीता)`,
`लोहार मुसलमान`. Mapping it to an official category needs a synonym table (the state's SC/ST/OBC
schedules, exploded one synonym per row, schema-versioned JSON) and a phonetic key that keeps
non-inherent vowels, because dropping all vowels collides `Jat` with `Jatia` and `Bhil` with
`Balai`. Return `unlisted` for a string that hits nothing; it is not the same as `General`.

## Output: a typed table with a dictionary

The parser's output is Parquet with an explicit Arrow schema (never inferred from a CSV), and
a data dictionary beside it. The dictionary is the `build-data` skill's contract: one row per
column with type, meaning, unit, missing convention, and the raw field it came from. Place
columns dictionary-encoded; codes as strings (leading zeros); every `_code` next to its `_name`.

## What a parse must report

Not "parsed 2,285 rows". Fill rates per field, the distribution of the field you have opinions
about (the top 25 caste strings, the relation words, the tenure words), and the rows where a
field is missing. The numbers that would embarrass you if wrong, printed by the parser itself
at the end of every run.
