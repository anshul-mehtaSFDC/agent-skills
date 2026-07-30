#!/usr/bin/env node
/**
 * agent-skills MCP server
 *
 * Exposes the repo's skills (skills/<category>/<name>/SKILL.md) over MCP as:
 *   - Tools:     list_skills, get_skill, search_skills
 *   - Prompts:   one prompt per skill (returns the SKILL.md body)
 *   - Resources: one resource per skill (skill://<name>)
 *
 * Skills are read from the local repo. Point at a different root with
 * AGENT_SKILLS_DIR, otherwise it defaults to ../skills relative to this file.
 */
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
  ListPromptsRequestSchema,
  GetPromptRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { readFileSync, readdirSync, statSync, existsSync } from "node:fs";
import { join, dirname, basename } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));

// ---- locate the skills directory ----
function resolveSkillsDir(): string {
  if (process.env.AGENT_SKILLS_DIR && existsSync(process.env.AGENT_SKILLS_DIR)) {
    return process.env.AGENT_SKILLS_DIR;
  }
  // dist/index.js -> ../../skills ; src/index.ts -> ../../skills
  const candidates = [
    join(__dirname, "..", "..", "skills"),
    join(__dirname, "..", "skills"),
    join(process.cwd(), "skills"),
  ];
  for (const c of candidates) if (existsSync(c)) return c;
  return candidates[0];
}
const SKILLS_DIR = resolveSkillsDir();

// ---- skill discovery + frontmatter parse ----
interface Skill {
  name: string;
  category: string;
  description: string;
  body: string; // markdown after frontmatter
  full: string; // entire SKILL.md
  path: string;
}

function parseFrontmatter(md: string): { fm: Record<string, string>; body: string } {
  const m = md.match(/^---\n([\s\S]*?)\n---\n?([\s\S]*)$/);
  if (!m) return { fm: {}, body: md };
  const fm: Record<string, string> = {};
  for (const line of m[1].split("\n")) {
    const kv = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
    if (kv) {
      let v = kv[2].trim();
      if ((v.startsWith('"') && v.endsWith('"')) || (v.startsWith("'") && v.endsWith("'"))) {
        v = v.slice(1, -1);
      }
      fm[kv[1]] = v;
    }
  }
  return { fm, body: m[2].trim() };
}

function findSkillFiles(root: string): string[] {
  const out: string[] = [];
  const walk = (dir: string) => {
    if (!existsSync(dir)) return;
    for (const entry of readdirSync(dir)) {
      const p = join(dir, entry);
      const st = statSync(p);
      if (st.isDirectory()) walk(p);
      else if (entry === "SKILL.md") out.push(p);
    }
  };
  walk(root);
  return out.sort();
}

function loadSkills(): Skill[] {
  return findSkillFiles(SKILLS_DIR).map((p) => {
    const full = readFileSync(p, "utf8");
    const { fm, body } = parseFrontmatter(full);
    const dir = dirname(p);
    const name = fm.name || basename(dir);
    const parent = basename(dirname(dir));
    const category = fm.category || (parent === "skills" ? "uncategorized" : parent);
    return {
      name,
      category,
      description: fm.description || "",
      body,
      full,
      path: p,
    };
  });
}

// re-read each request so edits to SKILL.md are picked up live
function getSkills(): Skill[] {
  return loadSkills();
}
function findSkill(name: string): Skill | undefined {
  return getSkills().find((s) => s.name === name);
}

// ---- server ----
const server = new Server(
  { name: "agent-skills", version: "1.0.0" },
  { capabilities: { tools: {}, prompts: {}, resources: {} } }
);

// ---------- TOOLS ----------
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    {
      name: "list_skills",
      description:
        "List all available agent-skills with their name, category, and description. Call this first to see what's available.",
      inputSchema: { type: "object", properties: {}, additionalProperties: false },
    },
    {
      name: "get_skill",
      description:
        "Get the full content (instructions) of one skill by name. Use the returned instructions to perform the task.",
      inputSchema: {
        type: "object",
        properties: { name: { type: "string", description: "Skill name, e.g. 'diagram-architect'" } },
        required: ["name"],
        additionalProperties: false,
      },
    },
    {
      name: "search_skills",
      description:
        "Search skills by keyword across name, category, and description. Returns matching skills.",
      inputSchema: {
        type: "object",
        properties: { query: { type: "string", description: "Keyword(s) to match" } },
        required: ["query"],
        additionalProperties: false,
      },
    },
  ],
}));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const { name, arguments: args } = req.params;
  const skills = getSkills();

  if (name === "list_skills") {
    const lines = skills.map((s) => `- ${s.name}  [${s.category}] — ${s.description}`);
    const text =
      skills.length === 0
        ? `No skills found in ${SKILLS_DIR}.`
        : `Available skills (${skills.length}):\n${lines.join("\n")}`;
    return { content: [{ type: "text", text }] };
  }

  if (name === "get_skill") {
    const s = findSkill(String(args?.name ?? ""));
    if (!s) {
      return {
        isError: true,
        content: [{ type: "text", text: `Skill '${args?.name}' not found. Call list_skills for names.` }],
      };
    }
    return { content: [{ type: "text", text: s.full }] };
  }

  if (name === "search_skills") {
    const q = String(args?.query ?? "").toLowerCase();
    const hits = skills.filter(
      (s) =>
        s.name.toLowerCase().includes(q) ||
        s.category.toLowerCase().includes(q) ||
        s.description.toLowerCase().includes(q)
    );
    const text =
      hits.length === 0
        ? `No skills match "${q}".`
        : `Matches for "${q}":\n` + hits.map((s) => `- ${s.name} [${s.category}] — ${s.description}`).join("\n");
    return { content: [{ type: "text", text }] };
  }

  return { isError: true, content: [{ type: "text", text: `Unknown tool: ${name}` }] };
});

// ---------- PROMPTS ----------
server.setRequestHandler(ListPromptsRequestSchema, async () => ({
  prompts: getSkills().map((s) => ({
    name: s.name,
    description: s.description,
  })),
}));

server.setRequestHandler(GetPromptRequestSchema, async (req) => {
  const s = findSkill(req.params.name);
  if (!s) throw new Error(`Prompt (skill) '${req.params.name}' not found`);
  return {
    description: s.description,
    messages: [
      {
        role: "user",
        content: {
          type: "text",
          text: `Follow this skill to help with the user's request:\n\n${s.full}`,
        },
      },
    ],
  };
});

// ---------- RESOURCES ----------
server.setRequestHandler(ListResourcesRequestSchema, async () => ({
  resources: getSkills().map((s) => ({
    uri: `skill://${s.name}`,
    name: s.name,
    description: s.description,
    mimeType: "text/markdown",
  })),
}));

server.setRequestHandler(ReadResourceRequestSchema, async (req) => {
  const uri = req.params.uri;
  const name = uri.replace(/^skill:\/\//, "");
  const s = findSkill(name);
  if (!s) throw new Error(`Resource '${uri}' not found`);
  return {
    contents: [{ uri, mimeType: "text/markdown", text: s.full }],
  };
});

// ---- start ----
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  // stderr only — stdout is the MCP channel
  console.error(`agent-skills MCP server running. Skills dir: ${SKILLS_DIR}`);
}
main().catch((err) => {
  console.error("Fatal:", err);
  process.exit(1);
});
