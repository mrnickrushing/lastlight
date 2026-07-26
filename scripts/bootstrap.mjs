import { spawnSync } from "node:child_process";
import { platform } from "node:os";

const commands = [
  ["rokit", ["install"]],
  ["npm", ["test"]],
];

for (const [command, args] of commands) {
  const executable = platform() === "win32" && command === "npm" ? "npm.cmd" : command;
  const result = spawnSync(executable, args, {
    cwd: process.cwd(),
    stdio: "inherit",
  });

  if (result.error?.code === "ENOENT" && command === "rokit") {
    console.error("Rokit is required before bootstrap.");
    console.error("Linux/macOS: https://github.com/rojo-rbx/rokit#installation");
    console.error("Windows: download rokit.exe, run it, then reopen the terminal.");
    process.exit(1);
  }

  if (result.error) {
    console.error(`${command} failed to start: ${result.error.message}`);
    process.exit(1);
  }

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

console.log("Last Light bootstrap complete.");
