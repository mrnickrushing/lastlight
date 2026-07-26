import { mkdirSync } from "node:fs";
import { spawnSync } from "node:child_process";

mkdirSync("build", { recursive: true });

for (const [project, output] of [
  ["default.project.json", "build/LastLight.rbxlx"],
  ["test.project.json", "build/LastLightTest.rbxlx"],
]) {
  const result = spawnSync("rojo", ["build", project, "--output", output], {
    cwd: process.cwd(),
    stdio: "inherit",
  });

  if (result.error) {
    console.error(`Rojo failed to start: ${result.error.message}`);
    process.exit(1);
  }

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}
