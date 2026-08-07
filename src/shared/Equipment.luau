--!strict

local Equipment = {}

export type Equipped = { [string]: string? }

type Definition = {
    slot: string,
    displayName: string,
    description: string,
    damageReduction: number,
    staminaRegenMultiplier: number,
    --[[
        Weapon-slot statistics. The family (`kind`) decides the moveset the
        way the roadmap asks: a ranged family declares `strikeRange` (the
        strike resolves at distance and the client draws a shot), a reaching
        melee family declares `meleeReach` (extended arm, no projectile), and
        an on-hit family carries its rider (stamina refund to the striker, or
        a snare on the struck enemy). The server reads all of these -- a
        client never submits range, damage, or an effect.
    ]]
    kind: string?,
    strikeRange: number?,
    meleeReach: number?,
    strikeDamageMultiplier: number?,
    onHitStaminaRefund: number?,
    onHitSnareSeconds: number?,
}

local DEFINITIONS: { [string]: Definition } = {
    gear_ironroot_hood = table.freeze({
        slot = "head",
        displayName = "IRONROOT HOOD",
        description = "Softens incoming damage by 5%.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1,
    }),
    gear_bramble_boots = table.freeze({
        slot = "feet",
        displayName = "BRAMBLE BOOTS",
        description = "Recover stamina 10% faster.",
        damageReduction = 0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_thornwood_bow = table.freeze({
        slot = "weapon",
        displayName = "THORNWOOD BOW",
        description = "Strike from 30 studs. Arrows hit for 80% of a close blow.",
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "bow",
        strikeRange = 30,
        strikeDamageMultiplier = 0.8,
    }),
    --[[
        The other five weapon families. Every number stays inside the bounds
        combat already clamps (damage multiplier 0.5-1.5 at the strike,
        damage reduction capped at 0.25 in stats), so no family can silence
        an enemy's mechanics or stack into an economy problem. Identities
        trade against each other: the maul is the damage ceiling with no
        reach, the lance buys reach with no rider, the sling trades the
        bow's range and damage for a snare, the edge sustains its wielder,
        and the cudgel is the one weapon that also guards.
    ]]
    gear_heartwood_maul = table.freeze({
        slot = "weapon",
        displayName = "HEARTWOOD MAUL",
        description = "Slow heavy blows land 45% harder up close.",
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "maul",
        strikeDamageMultiplier = 1.45,
    }),
    gear_briar_lance = table.freeze({
        slot = "weapon",
        displayName = "BRIAR LANCE",
        description = "Full-strength strikes from 14 studs of reach.",
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "lance",
        meleeReach = 14,
        strikeDamageMultiplier = 1,
    }),
    gear_foxfire_sling = table.freeze({
        slot = "weapon",
        displayName = "FOXFIRE SLING",
        description = "Stones from 22 studs hit for 70% and briefly snare the threat.",
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "sling",
        strikeRange = 22,
        strikeDamageMultiplier = 0.7,
        onHitSnareSeconds = 2.5,
    }),
    gear_amber_edge = table.freeze({
        slot = "weapon",
        displayName = "AMBER EDGE",
        description = "Clean cuts hit 10% harder and return 6 stamina.",
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "edge",
        strikeDamageMultiplier = 1.1,
        onHitStaminaRefund = 6,
    }),
    gear_warden_cudgel = table.freeze({
        slot = "weapon",
        displayName = "WARDEN CUDGEL",
        description = "A guard's weapon: 5% harder blows, 4% softer hits taken.",
        damageReduction = 0.04,
        staminaRegenMultiplier = 1,
        kind = "cudgel",
        strikeDamageMultiplier = 1.05,
    }),

    --[[
        Bramblewake's other eight. The starting region shipped with a hood
        and boots and nothing else, because its kit predates the slot
        system -- the census recorded that gap, and this closes it. The
        numbers are the gentlest in the game on purpose: this is the gear
        a player crafts before they understand the light/heavy choice, so
        it introduces the two lines without punishing either.
    ]]
    gear_meadow_cowl = table.freeze({
        slot = "head",
        damageReduction = 0,
        description = "Recover stamina 4% faster. Cut light on purpose.",
        displayName = "MEADOW COWL",
        staminaRegenMultiplier = 1.04,
    }),
    gear_bramble_treads = table.freeze({
        slot = "feet",
        damageReduction = 0.03,
        description = "Softens incoming damage by 3%. Heavy, and worth it.",
        displayName = "BRAMBLE TREADS",
        staminaRegenMultiplier = 1,
    }),
    gear_meadow_coat = table.freeze({
        slot = "body",
        damageReduction = 0,
        description = "Recover stamina 5% faster. Cut light on purpose.",
        displayName = "MEADOW COAT",
        staminaRegenMultiplier = 1.05,
    }),
    gear_bark_plate = table.freeze({
        slot = "body",
        damageReduction = 0.04,
        description = "Softens incoming damage by 4%. Heavy, and worth it.",
        displayName = "BARK PLATE",
        staminaRegenMultiplier = 1,
    }),
    gear_meadow_wraps = table.freeze({
        slot = "hands",
        damageReduction = 0,
        description = "Recover stamina 4% faster. Cut light on purpose.",
        displayName = "MEADOW WRAPS",
        staminaRegenMultiplier = 1.04,
    }),
    gear_bramble_gauntlets = table.freeze({
        slot = "hands",
        damageReduction = 0.03,
        description = "Softens incoming damage by 3%. Heavy, and worth it.",
        displayName = "BRAMBLE GAUNTLETS",
        staminaRegenMultiplier = 1,
    }),
    gear_foxfire_token = table.freeze({
        slot = "charm",
        damageReduction = 0,
        description = "Recover stamina 5% faster. It hums faintly at dusk.",
        displayName = "FOXFIRE TOKEN",
        staminaRegenMultiplier = 1.05,
    }),
    gear_heartwood_seal = table.freeze({
        slot = "charm",
        damageReduction = 0.04,
        description = "Softens incoming damage by 4%. Heartwood remembers.",
        displayName = "HEARTWOOD SEAL",
        staminaRegenMultiplier = 1,
    }),

    --[[
        The other five regions' gear.

        Six weapon families and five armour slots across five regions is a
        lot of entries, and the honest question about a set that size is
        whether it is content or wallpaper. What keeps it from being
        wallpaper is that a region is not a tier here -- it is an axis.
        The Delve makes everything heavier and does not care what it hits;
        the Fen makes everything longer, because the Fen taught people to
        stay back; the Reach wants distance out of anything it is given;
        the Vale trades a little bite for something you get back; the
        Crown casts rather than forges, so its gear takes a blow better
        than it lands one.

        A Delve maul and a Vale maul are therefore not the same weapon in
        different colours -- one is the damage ceiling of the game and the
        other is the one you can still swing at the end of a long night.
        Every number stays inside the bounds combat already clamps, so no
        entry here can silence an enemy's mechanics or stack into an
        economy problem.

        Armour is two lines rather than a ladder: a light line that
        returns stamina and a heavy line that reduces damage, so a player
        picks a way to survive rather than a bigger number.
    ]]
    gear_stope_bow = table.freeze({
        slot = "weapon",
        displayName = "STOPE BOW",
        description = "Strikes from 30 studs, hits for 88%. Heavier and slower to swing, and it does not care what it hits.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "bow",
        strikeRange = 30,
        strikeDamageMultiplier = 0.88,
    }),
    gear_drift_maul = table.freeze({
        slot = "weapon",
        displayName = "DRIFT MAUL",
        description = "Hits for 150%. Heavier and slower to swing, and it does not care what it hits.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "maul",
        strikeDamageMultiplier = 1.5,
    }),
    gear_pit_lance = table.freeze({
        slot = "weapon",
        displayName = "PIT LANCE",
        description = "Reaches 14 studs, hits for 108%. Heavier and slower to swing, and it does not care what it hits.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "lance",
        meleeReach = 14,
        strikeDamageMultiplier = 1.08,
    }),
    gear_slag_sling = table.freeze({
        slot = "weapon",
        displayName = "SLAG SLING",
        description = "Strikes from 22 studs, hits for 78%, snares briefly. Heavier and slower to swing, and it does not care what it hits.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "sling",
        strikeRange = 22,
        strikeDamageMultiplier = 0.78,
        onHitSnareSeconds = 2.5,
    }),
    gear_coalglass_edge = table.freeze({
        slot = "weapon",
        displayName = "COALGLASS EDGE",
        description = "Hits for 118%, refunds 6 stamina. Heavier and slower to swing, and it does not care what it hits.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "edge",
        strikeDamageMultiplier = 1.18,
        onHitStaminaRefund = 6,
    }),
    gear_shift_cudgel = table.freeze({
        slot = "weapon",
        displayName = "SHIFT CUDGEL",
        description = "Hits for 113%, softens hits taken by 4%. Heavier and slower to swing, and it does not care what it hits.",
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
        kind = "cudgel",
        strikeDamageMultiplier = 1.13,
    }),
    gear_ironroot_cowl = table.freeze({
        slot = "head",
        displayName = "IRONROOT COWL",
        description = "Recover stamina 6% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
    }),
    gear_ironroot_helm = table.freeze({
        slot = "head",
        displayName = "IRONROOT HELM",
        description = "Softens incoming damage by 4%. Heavy, and worth it.",
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
    }),
    gear_ironroot_coat = table.freeze({
        slot = "body",
        displayName = "IRONROOT COAT",
        description = "Recover stamina 6% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
    }),
    gear_ironroot_plate = table.freeze({
        slot = "body",
        displayName = "IRONROOT PLATE",
        description = "Softens incoming damage by 4%. Heavy, and worth it.",
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
    }),
    gear_ironroot_wraps = table.freeze({
        slot = "hands",
        displayName = "IRONROOT WRAPS",
        description = "Recover stamina 6% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
    }),
    gear_ironroot_gauntlets = table.freeze({
        slot = "hands",
        displayName = "IRONROOT GAUNTLETS",
        description = "Softens incoming damage by 4%. Heavy, and worth it.",
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
    }),
    gear_ironroot_boots = table.freeze({
        slot = "feet",
        displayName = "IRONROOT BOOTS",
        description = "Recover stamina 6% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
    }),
    gear_ironroot_treads = table.freeze({
        slot = "feet",
        displayName = "IRONROOT TREADS",
        description = "Softens incoming damage by 4%. Heavy, and worth it.",
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
    }),
    gear_ironroot_token = table.freeze({
        slot = "charm",
        displayName = "IRONROOT TOKEN",
        description = "Recover stamina 6% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
    }),
    gear_ironroot_seal = table.freeze({
        slot = "charm",
        displayName = "IRONROOT SEAL",
        description = "Softens incoming damage by 4%. Heavy, and worth it.",
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
    }),
    gear_reed_bow = table.freeze({
        slot = "weapon",
        displayName = "REED BOW",
        description = "Strikes from 33 studs, hits for 80%. Longer in the hand than it looks, because the fen taught everyone to stay back.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "bow",
        strikeRange = 33,
        strikeDamageMultiplier = 0.8,
    }),
    gear_bog_maul = table.freeze({
        slot = "weapon",
        displayName = "BOG MAUL",
        description = "Reaches 11 studs, hits for 145%. Longer in the hand than it looks, because the fen taught everyone to stay back.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "maul",
        meleeReach = 11,
        strikeDamageMultiplier = 1.45,
    }),
    gear_punt_lance = table.freeze({
        slot = "weapon",
        displayName = "PUNT LANCE",
        description = "Reaches 17 studs, hits for 100%. Longer in the hand than it looks, because the fen taught everyone to stay back.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "lance",
        meleeReach = 17,
        strikeDamageMultiplier = 1.0,
    }),
    gear_mirror_sling = table.freeze({
        slot = "weapon",
        displayName = "MIRROR SLING",
        description = "Strikes from 25 studs, hits for 70%, snares briefly. Longer in the hand than it looks, because the fen taught everyone to stay back.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "sling",
        strikeRange = 25,
        strikeDamageMultiplier = 0.7,
        onHitSnareSeconds = 2.5,
    }),
    gear_witchlight_edge = table.freeze({
        slot = "weapon",
        displayName = "WITCHLIGHT EDGE",
        description = "Reaches 11 studs, hits for 110%, refunds 6 stamina. Longer in the hand than it looks, because the fen taught everyone to stay back.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "edge",
        meleeReach = 11,
        strikeDamageMultiplier = 1.1,
        onHitStaminaRefund = 6,
    }),
    gear_ferry_cudgel = table.freeze({
        slot = "weapon",
        displayName = "FERRY CUDGEL",
        description = "Reaches 11 studs, hits for 105%, softens hits taken by 4%. Longer in the hand than it looks, because the fen taught everyone to stay back.",
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
        kind = "cudgel",
        meleeReach = 11,
        strikeDamageMultiplier = 1.05,
    }),
    gear_mireglass_cowl = table.freeze({
        slot = "head",
        displayName = "MIREGLASS COWL",
        description = "Recover stamina 8% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.08,
    }),
    gear_mireglass_helm = table.freeze({
        slot = "head",
        displayName = "MIREGLASS HELM",
        description = "Softens incoming damage by 5%. Heavy, and worth it.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_mireglass_coat = table.freeze({
        slot = "body",
        displayName = "MIREGLASS COAT",
        description = "Recover stamina 8% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.08,
    }),
    gear_mireglass_plate = table.freeze({
        slot = "body",
        displayName = "MIREGLASS PLATE",
        description = "Softens incoming damage by 5%. Heavy, and worth it.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_mireglass_wraps = table.freeze({
        slot = "hands",
        displayName = "MIREGLASS WRAPS",
        description = "Recover stamina 8% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.08,
    }),
    gear_mireglass_gauntlets = table.freeze({
        slot = "hands",
        displayName = "MIREGLASS GAUNTLETS",
        description = "Softens incoming damage by 5%. Heavy, and worth it.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_mireglass_boots = table.freeze({
        slot = "feet",
        displayName = "MIREGLASS BOOTS",
        description = "Recover stamina 8% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.08,
    }),
    gear_mireglass_treads = table.freeze({
        slot = "feet",
        displayName = "MIREGLASS TREADS",
        description = "Softens incoming damage by 5%. Heavy, and worth it.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_mireglass_token = table.freeze({
        slot = "charm",
        displayName = "MIREGLASS TOKEN",
        description = "Recover stamina 8% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.08,
    }),
    gear_mireglass_seal = table.freeze({
        slot = "charm",
        displayName = "MIREGLASS SEAL",
        description = "Softens incoming damage by 5%. Heavy, and worth it.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_jetty_bow = table.freeze({
        slot = "weapon",
        displayName = "JETTY BOW",
        description = "Strikes from 36 studs, hits for 80%. Made to be used across water, so everything about it wants distance.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "bow",
        strikeRange = 36,
        strikeDamageMultiplier = 0.8,
    }),
    gear_ballast_maul = table.freeze({
        slot = "weapon",
        displayName = "BALLAST MAUL",
        description = "Reaches 12 studs, hits for 149%. Made to be used across water, so everything about it wants distance.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "maul",
        meleeReach = 12,
        strikeDamageMultiplier = 1.49,
    }),
    gear_gaff_lance = table.freeze({
        slot = "weapon",
        displayName = "GAFF LANCE",
        description = "Reaches 12 studs, hits for 104%. Made to be used across water, so everything about it wants distance.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "lance",
        meleeReach = 12,
        strikeDamageMultiplier = 1.04,
    }),
    gear_halyard_sling = table.freeze({
        slot = "weapon",
        displayName = "HALYARD SLING",
        description = "Strikes from 28 studs, hits for 70%, snares briefly. Made to be used across water, so everything about it wants distance.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "sling",
        strikeRange = 28,
        strikeDamageMultiplier = 0.7,
        onHitSnareSeconds = 2.5,
    }),
    gear_amberglass_edge = table.freeze({
        slot = "weapon",
        displayName = "AMBERGLASS EDGE",
        description = "Reaches 12 studs, hits for 114%, refunds 6 stamina. Made to be used across water, so everything about it wants distance.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "edge",
        meleeReach = 12,
        strikeDamageMultiplier = 1.14,
        onHitStaminaRefund = 6,
    }),
    gear_breakwater_cudgel = table.freeze({
        slot = "weapon",
        displayName = "BREAKWATER CUDGEL",
        description = "Reaches 12 studs, hits for 109%, softens hits taken by 4%. Made to be used across water, so everything about it wants distance.",
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
        kind = "cudgel",
        meleeReach = 12,
        strikeDamageMultiplier = 1.09,
    }),
    gear_tempest_cowl = table.freeze({
        slot = "head",
        displayName = "TEMPEST COWL",
        description = "Recover stamina 10% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_tempest_helm = table.freeze({
        slot = "head",
        displayName = "TEMPEST HELM",
        description = "Softens incoming damage by 5%. Heavy, and worth it.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_tempest_coat = table.freeze({
        slot = "body",
        displayName = "TEMPEST COAT",
        description = "Recover stamina 10% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_tempest_plate = table.freeze({
        slot = "body",
        displayName = "TEMPEST PLATE",
        description = "Softens incoming damage by 5%. Heavy, and worth it.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_tempest_wraps = table.freeze({
        slot = "hands",
        displayName = "TEMPEST WRAPS",
        description = "Recover stamina 10% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_tempest_gauntlets = table.freeze({
        slot = "hands",
        displayName = "TEMPEST GAUNTLETS",
        description = "Softens incoming damage by 5%. Heavy, and worth it.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_tempest_boots = table.freeze({
        slot = "feet",
        displayName = "TEMPEST BOOTS",
        description = "Recover stamina 10% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_tempest_treads = table.freeze({
        slot = "feet",
        displayName = "TEMPEST TREADS",
        description = "Softens incoming damage by 5%. Heavy, and worth it.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_tempest_token = table.freeze({
        slot = "charm",
        displayName = "TEMPEST TOKEN",
        description = "Recover stamina 10% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_tempest_seal = table.freeze({
        slot = "charm",
        displayName = "TEMPEST SEAL",
        description = "Softens incoming damage by 5%. Heavy, and worth it.",
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_vale_bow = table.freeze({
        slot = "weapon",
        displayName = "VALE BOW",
        description = "Strikes from 30 studs, hits for 75%, returns stamina 6% faster. Light enough to carry a long way cold, and it gives something back.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
        kind = "bow",
        strikeRange = 30,
        strikeDamageMultiplier = 0.75,
    }),
    gear_thaw_maul = table.freeze({
        slot = "weapon",
        displayName = "THAW MAUL",
        description = "Hits for 140%, returns stamina 6% faster. Light enough to carry a long way cold, and it gives something back.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
        kind = "maul",
        strikeDamageMultiplier = 1.4,
    }),
    gear_crevasse_lance = table.freeze({
        slot = "weapon",
        displayName = "CREVASSE LANCE",
        description = "Reaches 14 studs, hits for 95%, returns stamina 6% faster. Light enough to carry a long way cold, and it gives something back.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
        kind = "lance",
        meleeReach = 14,
        strikeDamageMultiplier = 0.95,
    }),
    gear_hush_sling = table.freeze({
        slot = "weapon",
        displayName = "HUSH SLING",
        description = "Strikes from 22 studs, hits for 65%, returns stamina 6% faster, snares briefly. Light enough to carry a long way cold, and it gives something back.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
        kind = "sling",
        strikeRange = 22,
        strikeDamageMultiplier = 0.65,
        onHitSnareSeconds = 2.5,
    }),
    gear_rime_edge = table.freeze({
        slot = "weapon",
        displayName = "RIME EDGE",
        description = "Hits for 105%, returns stamina 6% faster, refunds 6 stamina. Light enough to carry a long way cold, and it gives something back.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
        kind = "edge",
        strikeDamageMultiplier = 1.05,
        onHitStaminaRefund = 6,
    }),
    gear_cloister_cudgel = table.freeze({
        slot = "weapon",
        displayName = "CLOISTER CUDGEL",
        description = "Hits for 100%, softens hits taken by 4%, returns stamina 6% faster. Light enough to carry a long way cold, and it gives something back.",
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.06,
        kind = "cudgel",
        strikeDamageMultiplier = 1.0,
    }),
    gear_frostmere_cowl = table.freeze({
        slot = "head",
        displayName = "FROSTMERE COWL",
        description = "Recover stamina 12% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.12,
    }),
    gear_frostmere_helm = table.freeze({
        slot = "head",
        displayName = "FROSTMERE HELM",
        description = "Softens incoming damage by 6%. Heavy, and worth it.",
        damageReduction = 0.06,
        staminaRegenMultiplier = 1.0,
    }),
    gear_frostmere_coat = table.freeze({
        slot = "body",
        displayName = "FROSTMERE COAT",
        description = "Recover stamina 12% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.12,
    }),
    gear_frostmere_plate = table.freeze({
        slot = "body",
        displayName = "FROSTMERE PLATE",
        description = "Softens incoming damage by 6%. Heavy, and worth it.",
        damageReduction = 0.06,
        staminaRegenMultiplier = 1.0,
    }),
    gear_frostmere_wraps = table.freeze({
        slot = "hands",
        displayName = "FROSTMERE WRAPS",
        description = "Recover stamina 12% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.12,
    }),
    gear_frostmere_gauntlets = table.freeze({
        slot = "hands",
        displayName = "FROSTMERE GAUNTLETS",
        description = "Softens incoming damage by 6%. Heavy, and worth it.",
        damageReduction = 0.06,
        staminaRegenMultiplier = 1.0,
    }),
    gear_frostmere_boots = table.freeze({
        slot = "feet",
        displayName = "FROSTMERE BOOTS",
        description = "Recover stamina 12% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.12,
    }),
    gear_frostmere_treads = table.freeze({
        slot = "feet",
        displayName = "FROSTMERE TREADS",
        description = "Softens incoming damage by 6%. Heavy, and worth it.",
        damageReduction = 0.06,
        staminaRegenMultiplier = 1.0,
    }),
    gear_frostmere_token = table.freeze({
        slot = "charm",
        displayName = "FROSTMERE TOKEN",
        description = "Recover stamina 12% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.12,
    }),
    gear_frostmere_seal = table.freeze({
        slot = "charm",
        displayName = "FROSTMERE SEAL",
        description = "Softens incoming damage by 6%. Heavy, and worth it.",
        damageReduction = 0.06,
        staminaRegenMultiplier = 1.0,
    }),
    gear_tier_bow = table.freeze({
        slot = "weapon",
        displayName = "TIER BOW",
        description = "Strikes from 30 studs, hits for 75%, softens hits taken by 3%. Cast rather than forged, and it takes a blow better than it lands one.",
        damageReduction = 0.03,
        staminaRegenMultiplier = 1.0,
        kind = "bow",
        strikeRange = 30,
        strikeDamageMultiplier = 0.75,
    }),
    gear_kiln_maul = table.freeze({
        slot = "weapon",
        displayName = "KILN MAUL",
        description = "Hits for 140%, softens hits taken by 3%. Cast rather than forged, and it takes a blow better than it lands one.",
        damageReduction = 0.03,
        staminaRegenMultiplier = 1.0,
        kind = "maul",
        strikeDamageMultiplier = 1.4,
    }),
    gear_procession_lance = table.freeze({
        slot = "weapon",
        displayName = "PROCESSION LANCE",
        description = "Reaches 14 studs, hits for 95%, softens hits taken by 3%. Cast rather than forged, and it takes a blow better than it lands one.",
        damageReduction = 0.03,
        staminaRegenMultiplier = 1.0,
        kind = "lance",
        meleeReach = 14,
        strikeDamageMultiplier = 0.95,
    }),
    gear_cinder_sling = table.freeze({
        slot = "weapon",
        displayName = "CINDER SLING",
        description = "Strikes from 22 studs, hits for 65%, softens hits taken by 3%, snares briefly. Cast rather than forged, and it takes a blow better than it lands one.",
        damageReduction = 0.03,
        staminaRegenMultiplier = 1.0,
        kind = "sling",
        strikeRange = 22,
        strikeDamageMultiplier = 0.65,
        onHitSnareSeconds = 2.5,
    }),
    gear_memory_edge = table.freeze({
        slot = "weapon",
        displayName = "MEMORY EDGE",
        description = "Hits for 105%, softens hits taken by 3%, refunds 6 stamina. Cast rather than forged, and it takes a blow better than it lands one.",
        damageReduction = 0.03,
        staminaRegenMultiplier = 1.0,
        kind = "edge",
        strikeDamageMultiplier = 1.05,
        onHitStaminaRefund = 6,
    }),
    gear_bailiff_cudgel = table.freeze({
        slot = "weapon",
        displayName = "BAILIFF CUDGEL",
        description = "Hits for 100%, softens hits taken by 7%. Cast rather than forged, and it takes a blow better than it lands one.",
        damageReduction = 0.07,
        staminaRegenMultiplier = 1.0,
        kind = "cudgel",
        strikeDamageMultiplier = 1.0,
    }),
    gear_cinderfall_cowl = table.freeze({
        slot = "head",
        displayName = "CINDERFALL COWL",
        description = "Recover stamina 14% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.14,
    }),
    gear_cinderfall_helm = table.freeze({
        slot = "head",
        displayName = "CINDERFALL HELM",
        description = "Softens incoming damage by 7%. Heavy, and worth it.",
        damageReduction = 0.07,
        staminaRegenMultiplier = 1.0,
    }),
    gear_cinderfall_coat = table.freeze({
        slot = "body",
        displayName = "CINDERFALL COAT",
        description = "Recover stamina 14% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.14,
    }),
    gear_cinderfall_plate = table.freeze({
        slot = "body",
        displayName = "CINDERFALL PLATE",
        description = "Softens incoming damage by 7%. Heavy, and worth it.",
        damageReduction = 0.07,
        staminaRegenMultiplier = 1.0,
    }),
    gear_cinderfall_wraps = table.freeze({
        slot = "hands",
        displayName = "CINDERFALL WRAPS",
        description = "Recover stamina 14% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.14,
    }),
    gear_cinderfall_gauntlets = table.freeze({
        slot = "hands",
        displayName = "CINDERFALL GAUNTLETS",
        description = "Softens incoming damage by 7%. Heavy, and worth it.",
        damageReduction = 0.07,
        staminaRegenMultiplier = 1.0,
    }),
    gear_cinderfall_boots = table.freeze({
        slot = "feet",
        displayName = "CINDERFALL BOOTS",
        description = "Recover stamina 14% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.14,
    }),
    gear_cinderfall_treads = table.freeze({
        slot = "feet",
        displayName = "CINDERFALL TREADS",
        description = "Softens incoming damage by 7%. Heavy, and worth it.",
        damageReduction = 0.07,
        staminaRegenMultiplier = 1.0,
    }),
    gear_cinderfall_token = table.freeze({
        slot = "charm",
        displayName = "CINDERFALL TOKEN",
        description = "Recover stamina 14% faster. Cut light on purpose.",
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.14,
    }),
    gear_cinderfall_seal = table.freeze({
        slot = "charm",
        displayName = "CINDERFALL SEAL",
        description = "Softens incoming damage by 7%. Heavy, and worth it.",
        damageReduction = 0.07,
        staminaRegenMultiplier = 1.0,
    }),
}

function Equipment.default(): Equipped
    return {}
end

function Equipment.normalize(value: any): Equipped
    local result: Equipped = {}
    if type(value) ~= "table" then
        return result
    end
    for slot, itemId in value do
        if type(slot) == "string" and type(itemId) == "string" and DEFINITIONS[itemId] ~= nil then
            local definition = DEFINITIONS[itemId]
            if definition.slot == slot then
                result[slot] = itemId
            end
        end
    end
    return result
end

function Equipment.get(itemId: any): any
    return if type(itemId) == "string" then DEFINITIONS[itemId] else nil
end

function Equipment.isKnown(itemId: any): boolean
    return type(itemId) == "string" and DEFINITIONS[itemId] ~= nil
end

function Equipment.equip(
    gear: { [string]: number },
    equipped: Equipped,
    itemId: any
): (Equipped, any)
    local definition = Equipment.get(itemId)
    if definition == nil then
        return equipped, { applied = false, reason = "unknown_equipment" }
    end
    if (gear[itemId] or 0) < 1 then
        return equipped, { applied = false, reason = "not_owned" }
    end
    local nextEquipped = Equipment.normalize(equipped)
    nextEquipped[definition.slot] = itemId
    return nextEquipped,
        {
            applied = true,
            itemId = itemId,
            slot = definition.slot,
        }
end

function Equipment.unequip(equipped: Equipped, slot: any): (Equipped, any)
    if type(slot) ~= "string" then
        return equipped, { applied = false, reason = "invalid_slot" }
    end
    local nextEquipped = Equipment.normalize(equipped)
    if nextEquipped[slot] == nil then
        return equipped, { applied = false, reason = "empty_slot" }
    end
    nextEquipped[slot] = nil
    return nextEquipped, { applied = true, slot = slot }
end

--[[
    What the equipped weapon changes about a strike.

    Returns nil for bare hands: the caller keeps its own defaults, so nothing
    about existing combat moves unless a weapon is actually equipped. `ranged`
    is what the client's projectile visual keys off -- only the bow and sling
    families throw something; the lance's reach is an extended arm, not a shot.
]]
function Equipment.weaponStrikeProfile(equipped: Equipped): any
    local normalized = Equipment.normalize(equipped)
    local weaponId = normalized.weapon
    if type(weaponId) ~= "string" then
        return nil
    end
    local definition = DEFINITIONS[weaponId]
    if definition == nil or definition.kind == nil then
        return nil
    end
    return {
        itemId = weaponId,
        kind = definition.kind,
        ranged = definition.strikeRange ~= nil,
        strikeRange = definition.strikeRange,
        meleeReach = definition.meleeReach,
        strikeDamageMultiplier = definition.strikeDamageMultiplier or 1,
        onHitStaminaRefund = definition.onHitStaminaRefund,
        onHitSnareSeconds = definition.onHitSnareSeconds,
    }
end

--[[
    effectivenessByItem is the wear system's seam: 1 (or absent) leaves an
    item's contribution bit-identical to the pre-wear math, 0.5 halves the
    part of it that differs from "wearing nothing", and 0 contributes
    nothing at all -- failing gear hangs on the body but shields nobody.
]]
function Equipment.stats(equipped: Equipped, effectivenessByItem: { [string]: number }?): any
    local damageReduction = 0
    local staminaRegenMultiplier = 1
    for _, itemId in Equipment.normalize(equipped) do
        if type(itemId) == "string" then
            local definition = DEFINITIONS[itemId]
            if definition ~= nil then
                local effectiveness = if effectivenessByItem ~= nil
                    then effectivenessByItem[itemId] or 1
                    else 1
                damageReduction += definition.damageReduction * effectiveness
                staminaRegenMultiplier *= 1 + (definition.staminaRegenMultiplier - 1) * effectiveness
            end
        end
    end
    return {
        damageReduction = math.clamp(damageReduction, 0, 0.25),
        staminaRegenMultiplier = math.clamp(staminaRegenMultiplier, 0.75, 1.5),
    }
end

function Equipment.list(): { any }
    local result = {}
    for itemId, definition in DEFINITIONS do
        table.insert(result, {
            itemId = itemId,
            slot = definition.slot,
            displayName = definition.displayName,
            description = definition.description,
        })
    end
    table.sort(result, function(a, b)
        return a.itemId < b.itemId
    end)
    return result
end

return table.freeze(Equipment)
