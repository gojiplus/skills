# skills

Agent Skills for empirical social-science work, software development, writing,
releases, and website performance.

Skills follow the [Agent Skills](https://agentskills.io) open format: a folder with
a `SKILL.md` carrying `name` and `description` in frontmatter, plus whatever
scripts, checks and references the skill needs. Agents load the description at
startup and the body only when a task matches.

Describe the task in ordinary language; the agent selects the relevant skill.
For example, ask to prepare a dataset, review a paper, release a package, or speed
up a website. Each entry below comes from its skill's own description.

<!-- skills:start -->

| Skill | When to use it |
|---|---|
| [audit-analysis](audit-analysis/) | Audit empirical social-science analyses for data integrity, identification, inference, robustness, and claim validity. Use for experiments, panels, causal designs, or replication packages. |
| [audit-package](audit-package/) | Audit a software package for correctness defects and prepare an upstream-quality fix. Use for maintained libraries, dependencies, regression tests, and reproducible bug reports. |
| [build-data](build-data/) | Prepare an analysis-ready dataset with documented columns, recodes, missing values, and verified joins. Use for unfamiliar data or unreliable data handoffs. |
| [design-analysis](design-analysis/) | Plan an empirical study before estimation, defining the question, identification assumptions, outcomes, inference, falsification checks, and pre-analysis plan. |
| [empirical-problem-solving](empirical-problem-solving/) | Diagnose a broken empirical metric, model, experiment, or pipeline. Use to reproduce and shrink failures, enumerate rival causes, order tests, and stop on evidence. |
| [metered-runs](metered-runs/) | Plan and run paid API batches with measured costs, small pilots, quality checks, and an authorized spending limit. Use for LLM inference, OCR, embeddings, or other metered jobs. |
| [ocr-error-triage](ocr-error-triage/) | Diagnose and improve OCR or document extraction. Use to measure error without full ground truth, localize failures, test repairs out of sample, and gate regressions and cost. |
| [on-writing](on-writing/) | Edit prose for organization, clarity, voice, and AI-writing tells. Use for papers, documentation, memos, emails, reports, reviews, humanization, or matching an author's voice. |
| [pruning-repo-history](pruning-repo-history/) | Collapse Git history to selected release commits or one commit, or recover release tags. Use only when the user requests history rewriting or tag reconstruction. |
| [release](release/) | Release a package after local checks, documentation review, independent model review, CI verification, and validation of the published artifact. |
| [review-article](review-article/) | Review empirical papers, reproduce central claims, assess causal and economic interpretations, and develop evidence-backed critiques or research opportunities. |
| [scrape-and-parse](scrape-and-parse/) | Build or fix a scraper and its parser. Use for government portals, ASP.NET postbacks, REST behind maps, PDF harvests, retries, checkpoints, resume, throughput diagnosis, and typed outputs. |
| [todo](todo/) | Read and write the user's Obsidian TaskNotes todo list. Use when asked to add, track, complete, or show tasks, preserving enough context for the task to be resumed later. |
| [visualize-evidence](visualize-evidence/) | Design or audit empirical figures, tables, and maps. Use for comparisons, uncertainty, units, captions, visual consistency, generated exhibits, or rendered-page quality assurance. |
| [web-perf](web-perf/) | Measure and improve website loading speed, rendering, layout stability, and resource use. Use for performance audits or slow pages on any hosting platform. |
| [write-empirical-paper](write-empirical-paper/) | Coordinate revision of a quantitative empirical paper and repository. Use for analysis audits, prose, figures, tables, citations, compilation, rendered-page checks, and claim validation. |

<!-- skills:end -->

`web-perf` measures and improves website performance on any host.

For research, `build-data` prepares the data, `design-analysis` plans the study,
`audit-analysis` checks an existing analysis, `review-article` evaluates a paper,
and `write-empirical-paper` coordinates manuscript production. Use the stage that
matches the request; a focused question does not require the whole sequence.

The generated [`index.json`](index.json) is the complete machine-readable catalog,
including supporting references and scripts.

## Installing

Skills are a filesystem format, and **custom skills do not sync across surfaces** —
claude.ai, the API, Claude Code and ChatGPT are separate installs. So there are two
mechanisms, and which you need depends on whether the surface can see a disk.

### Local agents — symlink, once

Claude Code, Codex, Cursor, Gemini CLI, VS Code and ~40 other clients read skills
from disk. Point the supported discovery paths at one clone to share a source:

```sh
git clone https://github.com/gojiplus/skills.git ~/Documents/GitHub/skills
ln -s ~/Documents/GitHub/skills ~/.agents/skills   # Codex, Cursor, Gemini CLI, …
ln -s ~/Documents/GitHub/skills ~/.claude/skills   # Claude Code
```

`~/.agents/skills` is the cross-tool standard path; `~/.claude/skills` is Claude
Code's. Restart the agent and it should list all skills. If one lists none, it does
not follow a symlinked directory — fall back to per-skill links for that one:

```sh
make link DEST=~/.claude/skills
```

Use one installation per agent. If this clone is already discovered through
`~/.agents/skills`, do not also keep copies of its skills under `~/.codex/skills`.
Reconcile unique edits before removing duplicate copies.

Local installation makes bundled scripts available and allows references to load
only when the task needs them.

### Claude web — upload a zip

In Claude, open **Customize → Skills → + → Create skill → Upload a skill** and
enable code execution. Grab the zips from the
[latest release](https://github.com/gojiplus/skills/releases/latest), or build them:

```sh
make dist        # -> dist/<skill>.zip, one per skill
```

Uploads are per-user. A changed skill means re-uploading that zip. These archives
are not ChatGPT plugin packages; current ChatGPT distribution uses plugins and
MCP connections instead.

### Web surfaces — connect the MCP endpoint

To avoid re-uploading, serve this repo over MCP. In Claude, open **Customize →
Connectors → + → Add custom connector**. In ChatGPT, enable Developer mode under
**Settings → Security and login**, then open **ChatGPT Plugins → +** and enter the
MCP URL, including `/mcp`.

The server reads content from GitHub at request time, so a push to `main` updates
skill bodies without a redeploy. Clients may cache the tool catalog; refresh or
reconnect after adding, renaming, or changing a skill description. The MCP shim
exposes skills as tools and resources, not as native installed skills.

[`server/`](server/) is a Cloudflare Worker: `npx wrangler login && npx wrangler
deploy`, once. It follows
[SEP-2640](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/2640),
the MCP Skills Extension — skills served as resources under `skill://` URIs, with
SHA-256 digests from `index.json` — plus a per-skill tool shim for the clients
that do not speak `skill://` yet, which today is all of them.

The tradeoff is real and worth stating: over MCP a skill is text. Bundled scripts
do not execute, and the body arrives through a tool call the model must choose to
make rather than sitting in the system prompt. Use the connector for reach and
live sync; use a zip when a skill needs its scripts.

## Developing

```sh
make check   # validate skills and both generated catalogs
make test    # run the repository unit tests
make index   # regenerate index.json and the README catalog
make dist    # build the upload zips
```

Run `make hooks` once after cloning to install the pre-commit hook. It regenerates
both catalogs and stops if they have unstaged changes, so you can review and stage
them with the skill edits. It does not stage unrelated README changes for you.
The README table and MCP descriptions share `SKILL.md` metadata; edit that source
and run `make index` rather than maintaining the table by hand.

Adding a skill is then just a directory with a `SKILL.md`. The symlinks mean
local agents pick it up with no further step. The MCP endpoint picks up content
on push; refresh connected clients when the catalog metadata changes.

`make check` enforces what claude.ai enforces on upload and Claude Code does not:
`name` at most 64 characters of lowercase letters, numbers and hyphens with no
reserved words, `description` non-empty and at most 200 characters, no XML tags
in either,
and `name` matching the directory. A skill can work locally for months and still
be rejected at upload; this is the gate that catches that.
