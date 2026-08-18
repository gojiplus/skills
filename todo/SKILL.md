---
name: todo
description: Read and write the user's Obsidian TaskNotes todo list. Use when asked to add, track, complete, or show tasks, preserving enough context for the task to be resumed later.
---

# Todo

The user's todo list lives in Obsidian, managed by the **TaskNotes** plugin. Do not invent a
format and do not append to a flat markdown list — the plugin already defines the contract, and
its four views (tasks, kanban, agenda, calendar) only work if you follow it.

## Where things are

| what | path |
|---|---|
| vault | `~/Documents/Obsidian Vault` |
| tasks | `~/Documents/Obsidian Vault/TaskNotes/Tasks/` |
| archive | `~/Documents/Obsidian Vault/TaskNotes/Archive/` |
| the old flat list | `~/Documents/Obsidian Vault/_ to do.md` |

The flat list predates this and is not maintained by the skill. Leave it alone unless asked.

## The contract

A task is **any note carrying the tag `task`**. That is the whole identification rule —
`taskIdentificationMethod` is `tag`, so the filename is free and the folder is convention.

Valid values, from the plugin's own settings. Anything else renders as an unknown chip:

- `status`: `none` · `open` · `in-progress` · `done`  — default `open`, and `done` is the only one that counts as completed
- `priority`: `none` · `low` · `normal` · `high` — default `normal`

Dates are `YYYY-MM-DD`. `due` is a deadline that means something externally; `scheduled` is when
the user intends to look at it. **Leave both out unless there is a real date.** A fake deadline on
every task makes the agenda view useless, which is the fastest way to get the whole system
abandoned.

## Writing a task

Filename: a readable kebab-case slug of the title, `.md`. The plugin's own `zettel` format is for
notes it generates; a slug is better here because we create these from the terminal and will need
to find them again with `grep` and `ls`.

```markdown
---
title: Add a selection diagnostic to preclink
status: open
priority: high
tags:
  - task
projects:
  - preclink
contexts:
  - code
dateCreated: 2026-08-10
---

## What

One paragraph. The concrete change, in enough detail that it can be started without
reconstructing this conversation.

## Why

What makes it worth doing, and what is lost by not doing it. Include the evidence — the
measurement, the link, the thing that was verified. This is the section that decays fastest and
matters most.

## Where it lives

Repo, file paths, PR or issue numbers, branch names. Absolute paths.

## First step

The single next action. Not a plan — one thing, small enough to start in five minutes.

## Done when

A checkable condition. A number, a passing test, a merged PR. Not "when it feels complete".
```

The body sections are the point of the skill. A one-line todo is a note to someone who already
has the context; in three weeks that person does not exist. **Write for a cold reader.** If a
claim was verified — a search that found nothing, a number measured, a source read — record
*how*, so it does not have to be re-verified.

Keep it proportional: a two-line errand gets **What** and nothing else. A piece of engineering
gets all five sections. Never pad a small thing into a template.

## How to act

**Adding.** Write the file directly with the Write tool. Do not ask permission first, do not
propose a draft and wait. Fill the body from the conversation that produced the request — that
context is the whole value, and it is gone by the next session. Then tell the user in one or two
lines what was recorded and where, so they can correct it while it is cheap.

If the request is vague ("add that to the todo") and more than one thing could be meant, name
what you are about to record and record it. Guessing and stating the guess beats a question.

**Check for an existing task before writing a new one** — `grep -rl` the tasks folder for the
obvious keyword. If one exists, update it rather than creating a near-duplicate; a list with two
versions of the same task stops being trusted.

**Reading.** To show the list, read the frontmatter of every file in the tasks folder and group
by status, most recent first. Do not open the vault app or expect the user to.

**Completing.** Set `status: done` and add `completedDate: YYYY-MM-DD`. Do not delete the file
and do not move it — `moveArchivedTasks` is off, so archiving is the user's own gesture.

## Getting today's date

`new Date()` is not available and the session's date can be stale. Use `date +%F` in Bash.
