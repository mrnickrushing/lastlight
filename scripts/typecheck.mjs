import { spawnSync } from "node:child_process";

function run(command, args) {
  const result = spawnSync(command, args, {
    cwd: process.cwd(),
    stdio: "inherit",
  });

  if (result.error) {
    console.error(`${command} failed to start: ${result.error.message}`);
    process.exit(1);
  }

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

run("luau-lsp", [
  "analyze",
  "--platform",
  "standard",
  "--definitions",
  "@lastlight=types/standard.d.luau",
  "src/shared",
  "src/server/ServiceRegistry.luau",
  "src/server/Services/FeatureFlagService.luau",
]);
