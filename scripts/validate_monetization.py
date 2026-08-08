#!/usr/bin/env python3
"""Keep functional progress free of monetization.

Milestone 4's exit gate asks that "no functional progress requires premium
cosmetics." It used to be true by absence -- the game contained no
MarketplaceService call, no game pass, no developer product and no premium
membership check anywhere. This script exists because that is the weakest way
for a gate to pass: an exit-gate item that passes because a thing is missing
goes on passing right up until someone adds the thing.

Milestone 11 added the thing. One module now touches a purchase API, it is on
the list below with the reason, and the property the gate asks about is held by
design rather than by absence: cosmetics are pure presentation, entitlements
resolve outside gameplay into plain profile data, and gameplay branches on what
is equipped rather than on what is owned. CosmeticNeutrality.spec is the half
of that this script cannot see -- it refuses any module outside the catalog to
so much as name a cosmetic id.

Two rules, and neither is a judgement about monetization itself:

  1. Gameplay code may not reference a purchase API at all.
  2. Nothing outside the allowlist may read a player's membership or
     ownership state, because a branch on "does this player own X" is how a
     cosmetic quietly becomes a requirement.

The allowlist holds exactly one module and is meant to stay that way. It is
short so that it is read.
"""

import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
ROOTS = ["src/server", "src/client", "src/shared", "src/first"]

# Modules permitted to touch a purchase or ownership API, each with the reason
# it is allowed. Adding an entry is a deliberate act and should be reviewed as
# one.
ALLOWED: dict[str, str] = {
    "src/server/Services/CommerceService.luau": (
        "The single grant authority. It resolves what a player owns once, at a "
        "receipt or at profile load, and writes the answer into "
        "profile.commerce as plain data; nothing downstream asks the platform "
        "anything. Every purchase is cosmetic and every cosmetic is "
        "presentation -- no cosmetic appears in a stat, a gate, a capacity, a "
        "recipe, a drop table, a spawn rule or a reward, which "
        "CosmeticNeutrality.spec asserts by walking the catalog and by "
        "refusing any module outside it to even name a cosmetic id. Gameplay "
        "branches on what is equipped, which is a profile field like every "
        "other. A second entry on this list would be the design failing, not "
        "the list being too short."
    ),
}

PURCHASE_APIS = [
    "MarketplaceService",
    "PromptPurchase",
    "PromptGamePassPurchase",
    "PromptProductPurchase",
    "PromptSubscriptionPurchase",
    "ProcessReceipt",
    "GetProductInfo",
]

OWNERSHIP_APIS = [
    "UserOwnsGamePassAsync",
    "PlayerOwnsAsset",
    "UserHasBadgeAsync",
    "IsPremium",
    "MembershipType",
    "HasPremium",
]

COMMENT = re.compile(r"--\[\[.*?\]\]|--[^\n]*", re.DOTALL)


def scan() -> int:
    failures: list[str] = []

    for root in ROOTS:
        base = ROOT / root
        if not base.exists():
            continue
        for path in sorted(base.rglob("*.luau")):
            relative = str(path.relative_to(ROOT))
            if relative in ALLOWED:
                continue

            # Comments discuss monetization in a few places without calling
            # anything, and a document about why something is free should not
            # fail the check that keeps it free.
            source = COMMENT.sub("", path.read_text())

            for api in PURCHASE_APIS:
                for match in re.finditer(rf"\b{re.escape(api)}\b", source):
                    line = source.count("\n", 0, match.start()) + 1
                    failures.append(
                        f"{relative}:{line}: gameplay code references the purchase API "
                        f"{api!r}. Functional progress may not depend on a purchase; if "
                        f"this is genuinely cosmetic, add the module to ALLOWED in "
                        f"scripts/validate_monetization.py with the reason."
                    )

            for api in OWNERSHIP_APIS:
                for match in re.finditer(rf"\b{re.escape(api)}\b", source):
                    line = source.count("\n", 0, match.start()) + 1
                    failures.append(
                        f"{relative}:{line}: gameplay code branches on ownership or "
                        f"membership via {api!r}. That is how a cosmetic becomes a "
                        f"requirement. Add the module to ALLOWED with the reason if the "
                        f"branch cannot change what a player can do."
                    )

    if failures:
        print("Monetization validation failed:\n", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        print(
            f"\n{len(failures)} finding(s). Milestone 4 exit gate: no functional "
            f"progress requires premium cosmetics.",
            file=sys.stderr,
        )
        return 1

    print(
        f"Monetization validation passed: no purchase or ownership branch in gameplay "
        f"code ({len(ALLOWED)} allowlisted module(s))."
    )
    return 0


if __name__ == "__main__":
    sys.exit(scan())
