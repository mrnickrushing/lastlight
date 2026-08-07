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
  "docs/MILESTONE_3_ADAPTIVE_REGION_MUSIC.md",
  "docs/MONETIZATION_LIVEOPS_ANALYTICS.md",
  "docs/PRODUCTION_ROADMAP.md",
  "docs/QA_RELEASE_PLAN.md",
  "docs/RELEASE_GATES.md",
  "docs/DEVELOPMENT.md",
  "docs/PROJECT_STATUS.md",
  "docs/MILESTONE_4_PROFILE_BACKUPS.md",
  "docs/MILESTONE_4_PER_BUILDING_DAMAGE.md",
  "docs/STUDIO_MCP_SETUP.md",
  "scripts/studio-mcp-wrapper.sh",
  "docs/MILESTONE_2_PLAYTEST.md",
  "docs/MILESTONE_3_EXPEDITION_FOUNDATION.md",
  "docs/MILESTONE_3_BRAMBLEWAKE_EVENTS.md",
  "docs/MILESTONE_3_INVENTORY_EXTRACTION.md",
  "docs/MILESTONE_3_PLAYER_SURVIVAL.md",
  "docs/MILESTONE_3_PROFESSION_KITS.md",
  "docs/MILESTONE_3_WARDEN_STAG_BOSS.md",
  "docs/MILESTONE_3_BRAMBLEWAKE_BLACKOUT.md",
  "docs/MILESTONE_3_NORMAL_NIGHT.md",
  "docs/MILESTONE_3_CRAFTING.md",
  "docs/MILESTONE_3_GEAR_EFFECTS.md",
  "docs/PUBLISHING_RUNBOOK.md",
  "docs/DECISIONS.md",
  "src/shared/Environment.luau",
  "src/shared/AmbientMotion.luau",
  "src/shared/MusicCatalog.luau",
  "src/shared/EnemyMotion.luau",
  "src/shared/WeatherProfile.luau",
  "src/shared/Content/ContentId.luau",
  "src/shared/Content/Registry.luau",
  "src/shared/Content/Definitions/Regions.luau",
  "src/shared/Content/Definitions/BramblewakeExpedition.luau",
  "src/shared/ExpeditionEventFlow.luau",
  "src/shared/ExpeditionGenerator.luau",
  "src/shared/ExpeditionInventory.luau",
  "src/shared/ExpeditionRewardLedger.luau",
  "src/shared/ExtractionPayoff.luau",
  "src/server/ServiceRegistry.luau",
  "src/server/Services/FeatureFlagService.luau",
  "src/server/Services/Logger.luau",
  "src/shared/Config.luau",
  "src/shared/RuntimeIds.luau",
  "src/shared/ReviveFlow.luau",
  "src/shared/SurvivalState.luau",
  "src/shared/ProfessionCatalog.luau",
  "src/shared/ProfessionState.luau",
  "src/shared/TutorialFlow.luau",
  "src/shared/SaveSchema.luau",
  "src/shared/ProfileBackup.luau",
  "tests/specs/ProfileBackup.spec.luau",
  "src/shared/RateLimiter.luau",
  "src/shared/NightSchedule.luau",
  "src/shared/TownNightSchedule.luau",
  "src/shared/CraftingCatalog.luau",
  "src/shared/Crafting.luau",
  "src/shared/QuestCatalog.luau",
  "src/shared/Quests.luau",
  "src/server/init.server.luau",
  "src/server/Services/NetworkService.luau",
  "src/server/Services/ProfileService.luau",
  "src/server/Services/AnalyticsService.luau",
  "src/server/Services/WorldService.luau",
  "src/server/Services/EnemyService.luau",
  "src/server/Services/ExpeditionService.luau",
  "src/server/Services/PhaseService.luau",
  "src/server/Services/TownNightService.luau",
  "src/server/Services/PlayerSurvivalService.luau",
  "src/server/Services/ProfessionService.luau",
  "src/server/Services/TutorialService.luau",
  "src/server/World/BramblewakeBuilder.luau",
  "src/client/init.client.luau",
  "src/client/Controllers/HUDController.luau",
  "src/client/Controllers/WorldMotionController.luau",
  "src/client/Controllers/WeatherController.luau",
  "src/client/Controllers/InputController.luau",
  "src/client/Controllers/InteractionController.luau",
  "src/client/Controllers/MusicController.luau",
  "src/first/LoadingController.client.luau",
  "tests/run.luau",
  "tests/specs/ReviveFlow.spec.luau",
  "tests/specs/AmbientMotion.spec.luau",
  "tests/specs/MusicCatalog.spec.luau",
  "tests/specs/EnemyMotion.spec.luau",
  "tests/specs/ExtractionPayoff.spec.luau",
  "tests/specs/WeatherProfile.spec.luau",
  "tests/specs/SurvivalState.spec.luau",
  "tests/specs/ProfessionState.spec.luau",
  "tests/studio/FoundationIntegration.server.luau",
  "scripts/verify-build.luau",
  "scripts/validate_audio_assets.py",
  "assets/audio/manifest.json",
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

// The living handoff states the build, schema, and service count a session
// should expect. A version bump that leaves those stale sends the next session
// -- and any tester following a runbook back to it -- looking for a build that
// no longer exists. Runbooks now defer to Config.luau rather than repeating the
// numbers, so this is the one document that has to be checked.
const statusPath = join(root, "docs/PROJECT_STATUS.md");
const configPath = join(root, "src/shared/Config.luau");
const bootstrapPath = join(root, "src/server/init.server.luau");
if (existsSync(statusPath) && existsSync(configPath) && existsSync(bootstrapPath)) {
  const config = readFileSync(configPath, "utf8");
  const status = readFileSync(statusPath, "utf8");
  const statusHeader = status.match(/^Last updated:[\s\S]*?(?=\n\n)/m)?.[0];

  if (!statusHeader) {
    failures.push(
      "docs/PROJECT_STATUS.md must open with a `Last updated:` paragraph naming the build, save schema, and service count"
    );
  } else {
    const declared = [
      [
        "build version",
        config.match(/BuildVersion\s*=\s*"([^"]+)"/)?.[1],
        statusHeader.match(/build `([^`]+)`/)?.[1]
      ],
      [
        "save schema",
        config.match(/SaveSchemaVersion\s*=\s*(\d+)/)?.[1],
        statusHeader.match(/save schema (\d+)/)?.[1]
      ],
      [
        "service count",
        String([...readFileSync(bootstrapPath, "utf8").matchAll(/services:register\(/g)].length),
        statusHeader.match(/(\d+) services/)?.[1]
      ]
    ];
    for (const [label, actual, stated] of declared) {
      if (actual === undefined) {
        failures.push(`could not read the ${label} from source to check docs/PROJECT_STATUS.md`);
      } else if (stated === undefined) {
        failures.push(`docs/PROJECT_STATUS.md no longer states the ${label}`);
      } else if (stated !== actual) {
        failures.push(
          `docs/PROJECT_STATUS.md states ${label} ${stated} but source declares ${actual} -- update the handoff`
        );
      }
    }
  }
}

const terrainBuilderPath = join(root, "src/server/World/TerrainBuilder.luau");
if (existsSync(terrainBuilderPath)) {
  const terrainBuilder = readFileSync(terrainBuilderPath, "utf8");
  if (terrainBuilder.includes(".Decoration")) {
    failures.push("TerrainBuilder must not access the runtime-incompatible Terrain.Decoration property");
  }
  const streamStart = terrainBuilder.indexOf("local function fillStream");
  const streamEnd = terrainBuilder.indexOf("local SURFACE_PATCH_DEPTH");
  const streamSource = terrainBuilder.slice(streamStart, streamEnd);
  if (streamStart < 0 || streamEnd < 0 || streamSource.includes("terrain:FillBall(")) {
    failures.push("stream and pond water must use flat fills, never spherical fills");
  }
  if (!streamSource.includes("Enum.Material.Water") || !streamSource.includes("FillBlock")) {
    failures.push("stream and pond must retain explicit flat water fills");
  }
}

const meshLoaderPath = join(root, "src/server/World/MeshTemplateLoader.luau");
if (existsSync(meshLoaderPath)) {
  const meshLoader = readFileSync(meshLoaderPath, "utf8");
  for (const restrictedProperty of ["CollisionFidelity", "RenderFidelity"]) {
    if (meshLoader.includes(`.${restrictedProperty} =`)) {
      failures.push(
        `MeshTemplateLoader must not write capability-restricted MeshPart.${restrictedProperty}`
      );
    }
  }
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

  /*
    The recipe target moved from 180 to 122 on purpose: the original
    allocation assumed categories that turned out not to exist (craftable
    tools, town project components, trap devices, companion utilities),
    and reaching 180 inside the categories that do exist would have meant
    a second copy of every item with different numbers. The count is
    still validated -- against the new number, and against the catalogs
    themselves in ContentCensus.spec, which is the check that matters.
  */
  const recipeRows = [...catalog.matchAll(
    /^\| (recipe_group_[a-z0-9_]+) \| [^|]+ \| (\d+) \|[^|]*\|?$/gm
  )];
  const recipeTotal = recipeRows.reduce((sum, row) => sum + Number(row[2]), 0);
  const recipeIds = recipeRows.map((row) => row[1]);
  if (recipeRows.length !== 3 || recipeTotal !== 130) {
    failures.push(`recipe allocation: expected 3 groups totaling 130, found ${recipeRows.length} groups totaling ${recipeTotal}`);
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
