#!/usr/bin/env node
// Build the recorded rollback target and check the place it produces.
//
// ROLLBACK.md names a revision to republish. A revision nobody has built since
// it was recorded is a plan rather than a rollback, and the moment you find out
// is the moment you are trying to use it. So this checks out the target into a
// throwaway worktree, builds it there, and runs the same DataModel verification
// the normal build runs.
//
// It also compares the bytes against the current build. That comparison is not
// a pass condition -- a rollback target is normally an older place than the one
// on the shelf, and a difference is the whole point of rolling back. It is
// reported because when they *are* identical it says something worth knowing:
// the place currently published is the rollback build, so a live pass on the
// running game is a live pass on the thing being restored.

import { createHash } from "node:crypto";
import { execFileSync } from "node:child_process";
import { mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const DOC = path.join(ROOT, "docs", "ROLLBACK.md");

const section = readFileSync(DOC, "utf8").split("## The rollback target")[1];
const revision = section?.match(/^\| \*\*Revision\*\* \| `([0-9a-f]{40})` \|$/m)?.[1];
if (!revision) {
	console.error(
		"Rollback build verification failed: ROLLBACK.md records no full revision.",
	);
	process.exit(1);
}

const worktree = mkdtempSync(path.join(tmpdir(), "lastlight-rollback-"));
const run = (command, args, cwd) =>
	execFileSync(command, args, { cwd, stdio: "inherit" });
const sha = (file) => createHash("sha256").update(readFileSync(file)).digest("hex");

try {
	run("git", ["worktree", "add", "--quiet", "--detach", worktree, revision], ROOT);
	run("node", [path.join(worktree, "scripts", "build.mjs")], worktree);
	run("lune", ["run", path.join(worktree, "scripts", "verify-build")], worktree);

	const built = sha(path.join(worktree, "build", "LastLight.rbxlx"));
	let current = null;
	try {
		current = sha(path.join(ROOT, "build", "LastLight.rbxlx"));
	} catch {
		// Nothing built here yet, which is fine: the comparison is a note.
	}
	console.log(
		`Rollback build verified: ${revision.slice(0, 12)} builds and its DataModel passes.`,
	);
	if (current !== null) {
		console.log(
			built === current
				? "  The published place is byte-identical to this build, so a live pass on the running game is a live pass on the rollback build."
				: "  It differs from the current build, which is what rolling back is for.",
		);
	}
} finally {
	rmSync(worktree, { recursive: true, force: true });
	execFileSync("git", ["worktree", "prune"], { cwd: ROOT });
}
