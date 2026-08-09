# MCP endpoint

A Cloudflare Worker that serves this repo's skills to claude.ai and ChatGPT,
which have no filesystem to read them from.

It reads `index.json` and the skill files from GitHub at request time, so **skill
edits go live on push with no redeploy**. You deploy this once; after that only a
change to the server itself needs `wrangler deploy`.

## What it speaks

| Method | For |
|---|---|
| `tools/list`, `tools/call` | One tool per skill, plus `read_skill_file`. The shim every client uses today. |
| `resources/list`, `resources/read` | Every skill file under its `skill://` URI. |
| `skills/list`, `skills/get` | [SEP-2640](https://github.com/modelcontextprotocol/modelcontextprotocol/pull/2640), with SHA-256 digests. No host ships this yet. |

The per-skill tool carries the skill's `description` as its own, which is what
the model matches against — the closest the tool surface gets to the frontmatter
a filesystem client would load at startup. Its result appends the skill's
supporting files as `skill://` URIs, because a body that says "see
`references/voice.md`" is useless if the model has no way to ask for that file.

Transport is Streamable HTTP with JSON responses. There is no SSE stream and no
session state — every response fits in one body, so there is nothing to stream
and nothing to keep.

## Deploying

```sh
cd server
npx wrangler login       # interactive, once
npx wrangler deploy
```

Then add the printed `https://gojiplus-skills.<subdomain>.workers.dev` URL as a
custom connector:

- **claude.ai** — Settings → Connectors → Add custom connector. No OAuth.
  Connectors are account-scoped, so this also reaches Claude on mobile.
- **ChatGPT** — Developer Mode → add an MCP server. Read-only is all this
  server does, which is all Plus and Pro accounts are permitted anyway.

To serve a different repo, change `GITHUB_REPO` and `GITHUB_REF` in
`wrangler.toml`. The repo must be public — there is no token handling here.

## Testing

```sh
npx wrangler dev --local        # one terminal
node smoke.mjs                  # another; defaults to localhost:8787
node smoke.mjs https://…        # or point it at the deployed Worker
```

`smoke.mjs` checks the protocol surface and the two things most likely to be
quietly wrong: that a skill's supporting files are reachable, and that a file
outside `index.json` is not. It also hashes a served file and compares it to the
digest the catalog published, since an unverified digest is decoration.

`GET /health` returns `{"ok":true,"skills":9}` — enough to tell a broken deploy
from a broken index.

## Security

`index.json` is the allowlist. A `skill://` URI that does not appear in it is
refused, which is what keeps a crafted request away from `.github/workflows` or
anything else in the repo.

The digests are unsigned and come from the same place as the content, so a match
proves the two are consistent, not that either is trustworthy. That is the
spec's position too, and it is worth repeating: this endpoint is public and
unauthenticated because the repo is public. Do not point it at anything private.
