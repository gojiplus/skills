#!/usr/bin/env node
/**
 * End-to-end check against a running server.
 *
 *   node smoke.mjs http://localhost:8787
 *   node smoke.mjs https://gojiplus-skills.<subdomain>.workers.dev
 *
 * Exercises both audiences — the tool shim every client actually uses today,
 * and the SEP-2640 methods none of them do yet — plus the two things most
 * likely to be quietly wrong: that a skill's supporting files are reachable,
 * and that a file outside the index is not.
 */

import { createHash } from "node:crypto";

const endpoint = process.argv[2] ?? "http://localhost:8787";
let failures = 0;
let id = 0;

async function rpc(method, params) {
  const response = await fetch(endpoint, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ jsonrpc: "2.0", id: ++id, method, params }),
  });
  return response.json();
}

function check(label, condition, detail = "") {
  if (condition) {
    console.log(`ok   ${label}`);
  } else {
    failures += 1;
    console.log(`FAIL ${label}${detail ? ` — ${detail}` : ""}`);
  }
}

const init = await rpc("initialize", { protocolVersion: "2026-07-28", capabilities: {} });
check("initialize returns the negotiated version", init.result?.protocolVersion === "2026-07-28");
check("initialize declares the skills extension",
  "io.modelcontextprotocol/skills" in (init.result?.capabilities?.experimental ?? {}));

const older = await rpc("initialize", { protocolVersion: "2025-06-18", capabilities: {} });
check("initialize echoes an older supported version", older.result?.protocolVersion === "2025-06-18");

const tools = (await rpc("tools/list")).result?.tools ?? [];
check("one tool per skill, plus read_skill_file", tools.length === 10, `got ${tools.length}`);
check("tool names are legal", tools.every((t) => /^[a-zA-Z0-9_-]{1,64}$/.test(t.name)));
check("every skill tool carries its description",
  tools.filter((t) => t.name.startsWith("skill_")).every((t) => (t.description ?? "").length > 40));

const called = await rpc("tools/call", { name: "skill_on_writing", arguments: {} });
const body = called.result?.content?.[0]?.text ?? "";
check("calling a skill tool returns its SKILL.md", body.includes("name: on-writing"));
check("the response lists supporting files", body.includes("skill://on-writing/references/voice.md"));

const unknownTool = await rpc("tools/call", { name: "skill_nope", arguments: {} });
check("an unknown tool is a JSON-RPC error", unknownTool.error?.code === -32602);

const supporting = await rpc("tools/call", {
  name: "read_skill_file",
  arguments: { uri: "skill://on-writing/references/voice.md" },
});
check("read_skill_file returns a supporting file",
  (supporting.result?.content?.[0]?.text ?? "").length > 500);

const traversal = await rpc("tools/call", {
  name: "read_skill_file",
  arguments: { uri: "skill://../.github/workflows/release.yml" },
});
check("a path outside the index is refused", traversal.result?.isError === true);

const resources = (await rpc("resources/list")).result?.resources ?? [];
check("resources/list covers every indexed file", resources.length === 49, `got ${resources.length}`);
check("SKILL.md resources are text/markdown",
  resources.filter((r) => r.uri.endsWith("SKILL.md")).every((r) => r.mimeType === "text/markdown"));

const read = await rpc("resources/read", { uri: "skill://review-article/SKILL.md" });
check("resources/read returns content",
  (read.result?.contents?.[0]?.text ?? "").includes("name: review-article"));

const skills = (await rpc("skills/list")).result?.skills ?? [];
check("skills/list returns every skill", skills.length === 9, `got ${skills.length}`);
check("every entry carries frontmatter with name and description",
  skills.every((s) => s.frontmatter?.name && s.frontmatter?.description));
check("every entry's uri ends in the skill name",
  skills.every((s) => s.uri === `skill://${s.frontmatter.name}/SKILL.md`));
check("resources include the SKILL.md digest",
  skills.every((s) => s.resources.some((r) => r.uri === s.uri && /^sha256:[0-9a-f]{64}$/.test(r.digest))));

const got = await rpc("skills/get", { uri: "skill://audit-analysis/SKILL.md" });
check("skills/get returns one entry", got.result?.skill?.frontmatter?.name === "audit-analysis");

// The digest is the whole point of the listing — verify one for real.
const entry = skills.find((s) => s.frontmatter.name === "audit-analysis");
const content = await rpc("resources/read", { uri: entry.uri });
const actual = "sha256:" + createHash("sha256")
  .update(content.result.contents[0].text, "utf8")
  .digest("hex");
const promised = entry.resources.find((r) => r.uri === entry.uri).digest;
check("the served content matches its published digest", actual === promised,
  `${actual.slice(0, 20)} vs ${promised.slice(0, 20)}`);

const unknownMethod = await rpc("skills/nope");
check("an unknown method is -32601", unknownMethod.error?.code === -32601);

console.log(failures ? `\n${failures} failed` : "\nall passed");
process.exit(failures ? 1 : 0);
