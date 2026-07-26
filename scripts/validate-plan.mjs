import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const requiredFiles = [
  "README.md",
  "AGENTS.md",
  "CONTRIBUTING.md",
  "default.project.json",
  "test.project.json",
  "rokit.toml",
  "docs/GAME_DESIGN_DOCUMENT.md",
  "docs/WORLD_BIBLE.md",
  "docs/CONTENT_CATALOG.md",
  "docs/TECHNICAL_ARCHITECTURE.md",
  "docs/UX_MOBILE_ACCESSIBILITY.md",
  "docs/UI_DESIGN_DIRECTION.md",
  "docs/ART_AUDIO_DIRECTION.md",
  "docs/MONETIZATION_LIVEOPS_ANALYTICS.md",
  "docs/PRODUCTION_ROADMAP.md",
  "docs/QA_RELEASE_PLAN.md",
  "docs/RELEASE_GATES.md",
  "docs/DEVELOPMENT.md",
  "docs/PUBLISHING_RUNBOOK.md",
  "docs/DECISIONS.md",
  "src/shared/Environment.luau",
  "src/shared/Content/ContentId.luau",
  "src/shared/Content/Registry.luau",
  "src/shared/Content/Definitions/Regions.luau",
  "src/server/ServiceRegistry.luau",
  "src/server/Services/FeatureFlagService.luau",
  "src/server/Services/Logger.luau",
  "src/shared/Config.luau",
  "src/server/init.server.luau",
  "src/client/init.client.luau",
  "src/first/init.client.luau",
  "tests/run.luau",
  "tests/studio/FoundationIntegration.server.luau",
  "scripts/verify-build.luau",
  "types/standard.d.luau"
];

const failures = [];

for (const file of requiredFiles) {
  if (!existsSync(join(root, file))) {
    failures.push(`missing required file: ${file}`);
  }
}

for (const jsonFile of ["package.json", "default.project.json", "test.project.json"]) {
  try {
    JSON.parse(readFileSync(join(root, jsonFile), "utf8"));
  } catch (error) {
    failures.push(`invalid JSON in ${jsonFile}: ${error.message}`);
  }
}

const rokitPath = join(root, "rokit.toml");
if (existsSync(rokitPath)) {
  const rokit = readFileSync(rokitPath, "utf8");
  for (const tool of ["rojo", "stylua", "selene", "lune", "luau-lsp"]) {
    const exactPin = new RegExp(`^${tool} = "[^"]+@\\d+\\.\\d+\\.\\d+"$`, "m");
    if (!exactPin.test(rokit)) {
      failures.push(`rokit.toml must exactly pin ${tool}`);
    }
  }
}

/**
 * Recursively returns repository files while excluding generated and dependency trees.
 */
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

/**
 * Checks both the number and uniqueness of catalog IDs captured by a regex.
 */
function assertPatternCount(file, pattern, expected, label) {
  const path = join(root, file);
  if (!existsSync(path)) return;
  const contents = readFileSync(path, "utf8");
  const matches = [...contents.matchAll(pattern)];
  const count = matches.length;
  if (count !== expected) {
    failures.push(`${label} count in ${file}: expected ${expected}, found ${count}`);
  }
  const ids = matches.map((match) => match[1] ?? match[0]);
  const uniqueCount = new Set(ids).size;
  if (uniqueCount !== count) {
    failures.push(`${label} IDs in ${file}: expected ${count} unique IDs, found ${uniqueCount}`);
  }
}

assertPatternCount("docs/CONTENT_CATALOG.md", /^\| (enemy_[a-z0-9_]+) \|/gm, 42, "standard enemy");
assertPatternCount("docs/CONTENT_CATALOG.md", /^\| (elite_[a-z0-9_]+) \|/gm, 14, "elite enemy");
assertPatternCount("docs/CONTENT_CATALOG.md", /^\| (boss_[a-z0-9_]+) \|/gm, 7, "chapter boss");
assertPatternCount("docs/CONTENT_CATALOG.md", /^\| (companion_[a-z0-9_]+) \|/gm, 18, "companion");
assertPatternCount("docs/CONTENT_CATALOG.md", /^\| (building_[a-z0-9_]+) \|/gm, 28, "building");
assertPatternCount("docs/CONTENT_CATALOG.md", /`(event_[a-z0-9_]+)`/g, 48, "dynamic event");
assertPatternCount("docs/WORLD_BIBLE.md", /^\| (npc_[a-z0-9_]+) \|/gm, 24, "named resident");

const catalogPath = join(root, "docs/CONTENT_CATALOG.md");
if (existsSync(catalogPath)) {
  const catalog = readFileSync(catalogPath, "utf8");
  const regionRows = [...catalog.matchAll(
    /^\| (region_[a-z0-9_]+) \| [^|]+ \| [^|]+ \| ([^|]+) \| ([^|]+) \| ([^|]+) \|$/gm
  )];
  if (regionRows.length !== 7) {
    failures.push(`region count in docs/CONTENT_CATALOG.md: expected 7, found ${regionRows.length}`);
  }
  const regionIds = regionRows.map((row) => row[1]);
  if (new Set(regionIds).size !== regionIds.length) {
    failures.push("region IDs in docs/CONTENT_CATALOG.md are not unique");
  }
  const sumNumericColumn = (index) =>
    regionRows.reduce((sum, row) => {
      const value = Number.parseInt(row[index].trim(), 10);
      return sum + (Number.isNaN(value) ? 0 : value);
    }, 0);
  for (const [column, expected, label] of [
    [2, 180, "surface modules"],
    [3, 79, "points of interest"],
    [4, 48, "surface events"]
  ]) {
    const actual = sumNumericColumn(column);
    if (actual !== expected) failures.push(`${label}: expected ${expected}, found ${actual}`);
  }

  const recipeRows = [...catalog.matchAll(
    /^\| (recipe_group_[a-z0-9_]+) \| [^|]+ \| (\d+) \|$/gm
  )];
  const recipeTotal = recipeRows.reduce((sum, row) => sum + Number(row[2]), 0);
  const recipeIds = recipeRows.map((row) => row[1]);
  if (recipeRows.length !== 7 || recipeTotal !== 180) {
    failures.push(`recipe allocation: expected 7 groups totaling 180, found ${recipeRows.length} groups totaling ${recipeTotal}`);
  }
  if (new Set(recipeIds).size !== recipeIds.length) {
    failures.push("recipe group IDs in docs/CONTENT_CATALOG.md are not unique");
  }

  const expectedQuestCounts = new Map([
    ["quest_group_prologue", [1, 7]],
    ["quest_group_chapter", [7, 56]],
    ["quest_group_resident", [24, 72]],
    ["quest_group_mastery", [7, 21]],
    ["quest_group_mystery", [7, 42]],
    ["quest_group_contract", [36, 36]],
    ["quest_group_crisis", [18, 18]],
    ["quest_group_postgame", [3, 9]]
  ]);
  const questRows = [...catalog.matchAll(
    /^\| (quest_group_[a-z0-9_]+) \| [^|]+ \| (\d+) \| (\d+) \| [^|]+ \|$/gm
  )];
  for (const row of questRows) {
    const expected = expectedQuestCounts.get(row[1]);
    if (!expected || Number(row[2]) !== expected[0] || Number(row[3]) !== expected[1]) {
      failures.push(`unexpected quest inventory row: ${row[1]} ${row[2]}/${row[3]}`);
    }
    expectedQuestCounts.delete(row[1]);
  }
  for (const missing of expectedQuestCounts.keys()) {
    failures.push(`missing quest inventory row: ${missing}`);
  }
}

if (failures.length > 0) {
  console.error("Blueprint validation failed:\n");
  for (const failure of failures) console.error(`- ${failure}`);
  process.exit(1);
}

console.log(
  `Blueprint validation passed: ${requiredFiles.length} required files and ${markdownFiles.length} Markdown files checked.`
);
