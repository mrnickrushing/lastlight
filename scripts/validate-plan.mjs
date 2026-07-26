import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";

const root = resolve(import.meta.dirname, "..");
const requiredFiles = [
  "README.md",
  "AGENTS.md",
  "CONTRIBUTING.md",
  "default.project.json",
  "docs/GAME_DESIGN_DOCUMENT.md",
  "docs/WORLD_BIBLE.md",
  "docs/CONTENT_CATALOG.md",
  "docs/TECHNICAL_ARCHITECTURE.md",
  "docs/UX_MOBILE_ACCESSIBILITY.md",
  "docs/ART_AUDIO_DIRECTION.md",
  "docs/MONETIZATION_LIVEOPS_ANALYTICS.md",
  "docs/PRODUCTION_ROADMAP.md",
  "docs/QA_RELEASE_PLAN.md",
  "docs/DECISIONS.md",
  "src/shared/Config.luau",
  "src/server/init.server.luau",
  "src/client/init.client.luau",
  "src/first/init.client.luau"
];

const failures = [];

for (const file of requiredFiles) {
  if (!existsSync(join(root, file))) {
    failures.push(`missing required file: ${file}`);
  }
}

for (const jsonFile of ["package.json", "default.project.json"]) {
  try {
    JSON.parse(readFileSync(join(root, jsonFile), "utf8"));
  } catch (error) {
    failures.push(`invalid JSON in ${jsonFile}: ${error.message}`);
  }
}

function walk(directory) {
  const files = [];
  for (const entry of readdirSync(directory)) {
    if (entry === ".git" || entry === "node_modules" || entry === ".lazyweb") continue;
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) files.push(...walk(path));
    else files.push(path);
  }
  return files;
}

const markdownFiles = walk(root).filter((path) => path.endsWith(".md"));
const localLinkPattern = /\[[^\]]+\]\((?!https?:|mailto:|#)([^)#]+)(?:#[^)]+)?\)/g;

for (const markdownFile of markdownFiles) {
  const contents = readFileSync(markdownFile, "utf8");
  for (const match of contents.matchAll(localLinkPattern)) {
    const target = match[1].replaceAll("%20", " ");
    const resolved = resolve(dirname(markdownFile), target);
    if (!existsSync(resolved)) {
      failures.push(
        `broken local link in ${relative(root, markdownFile)}: ${match[1]}`
      );
    }
  }
}

const readme = existsSync(join(root, "README.md"))
  ? readFileSync(join(root, "README.md"), "utf8")
  : "";
for (const heading of [
  "## Game vision",
  "## Complete launch scope",
  "## Build order",
  "## Definition of done",
  "## Current status"
]) {
  if (!readme.includes(heading)) failures.push(`README is missing heading: ${heading}`);
}

function assertPatternCount(file, pattern, expected, label) {
  const contents = readFileSync(join(root, file), "utf8");
  const count = [...contents.matchAll(pattern)].length;
  if (count !== expected) {
    failures.push(`${label} count in ${file}: expected ${expected}, found ${count}`);
  }
}

assertPatternCount("docs/CONTENT_CATALOG.md", /^\| enemy_[a-z0-9_]+ \|/gm, 42, "standard enemy");
assertPatternCount("docs/CONTENT_CATALOG.md", /^\| elite_[a-z0-9_]+ \|/gm, 14, "elite enemy");
assertPatternCount("docs/CONTENT_CATALOG.md", /^\| boss_[a-z0-9_]+ \|/gm, 7, "chapter boss");
assertPatternCount("docs/CONTENT_CATALOG.md", /^\| companion_[a-z0-9_]+ \|/gm, 18, "companion");
assertPatternCount("docs/CONTENT_CATALOG.md", /^\| building_[a-z0-9_]+ \|/gm, 28, "building");
assertPatternCount("docs/CONTENT_CATALOG.md", /`event_[a-z0-9_]+`/g, 48, "dynamic event");
assertPatternCount("docs/WORLD_BIBLE.md", /^\| npc_[a-z0-9_]+ \|/gm, 24, "named resident");

if (failures.length > 0) {
  console.error("Blueprint validation failed:\n");
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(
  `Blueprint validation passed: ${requiredFiles.length} required files and ${markdownFiles.length} Markdown files checked.`
);
