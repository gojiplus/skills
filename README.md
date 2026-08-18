# skills

Agent Skills for empirical social-science work, software and Cloudflare development,
writing, and releases.

Skills follow the [Agent Skills](https://agentskills.io) open format: a folder with
a `SKILL.md` carrying `name` and `description` in frontmatter, plus whatever
scripts, checks and references the skill needs. Agents load the description at
startup and the body only when a task matches.

| Skill | For |
|---|---|
| [audit-analysis](audit-analysis/) | Audit an empirical analysis from raw data through manuscript claims |
| [audit-package](audit-package/) | Audit a library for correctness defects and prepare an upstream fix |
| [build-data](build-data/) | Turn raw data into an analysis-ready file with a defensible dictionary, recode ledger and join contract |
| [design-analysis](design-analysis/) | State an estimand and freeze a plan before the headline number exists |
| [empirical-problem-solving](empirical-problem-solving/) | Diagnose a metric that moved or a pipeline that started lying |
| [ocr-error-triage](ocr-error-triage/) | Measure and fix document-extraction errors without ground truth |
| [on-writing](on-writing/) | Edit prose that buries its point, over-hedges, or reads as generated |
| [release](release/) | Cut a package release behind an independent review gate |
| [review-article](review-article/) | Referee a quantitative social-science paper |
| [todo](todo/) | Read and write durable tasks in the user's Obsidian TaskNotes vault |
| [visualize-evidence](visualize-evidence/) | Design empirical figures, tables, and maps around clear comparisons and uncertainty |
| [write-empirical-paper](write-empirical-paper/) | Coordinate analysis audits, prose, exhibits, compilation, and paper-level validation |

The repository also carries the Cloudflare skill bundle used by local agents, including
[cloudflare](cloudflare/), [Agents SDK](agents-sdk/), [Durable Objects](durable-objects/),
[Workers best practices](workers-best-practices/), [Wrangler](wrangler/), Sandbox,
Cloudflare One, email, Turnstile, and web-performance skills. The generated
[`index.json`](index.json) is the complete machine-readable catalog.

## Installing

Skills are a filesystem format, and **custom skills do not sync across surfaces** —
claude.ai, the API, Claude Code and ChatGPT are separate installs. So there are two
mechanisms, and which you need depends on whether the surface can see a disk.

### Local agents — symlink, once

Claude Code, Codex, Cursor, Gemini CLI, VS Code and ~40 other clients read skills
from disk. Point both standard paths at one clone and they can never drift:

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

This is the highest-fidelity install: bundled scripts execute, and progressive
disclosure works as designed.

### Claude web — upload a zip

In Claude, open **Customize → Skills → + → Create skill → Upload a skill** and
enable code execution. Grab the zips from the
[latest release](../../releases/latest), or build them:

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
make check   # validate every SKILL.md, and confirm index.json is current
make test    # run the repository unit tests
make index   # regenerate index.json after adding or editing a skill
make dist    # build the upload zips
```

Run `make hooks` once after cloning: it points `core.hooksPath` at `.githooks`,
whose pre-commit hook regenerates `index.json`. Otherwise every skill edit is two
steps and CI fails on the commits where you forget the second.

Adding a skill is then just a directory with a `SKILL.md`. The symlinks mean
local agents pick it up with no further step. The MCP endpoint picks up content
on push; refresh connected clients when the catalog metadata changes.

`make check` enforces what claude.ai enforces on upload and Claude Code does not:
`name` at most 64 characters of lowercase letters, numbers and hyphens with no
reserved words, `description` non-empty and at most 200 characters, no XML tags
in either,
and `name` matching the directory. A skill can work locally for months and still
be rejected at upload; this is the gate that catches that.
