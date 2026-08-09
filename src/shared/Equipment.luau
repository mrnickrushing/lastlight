--!strict

local Strings = require("./Strings")

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
        displayName = Strings.get("world.ironroot_hood"),
        description = Strings.get("item.softens_incoming_damage_by_5"),
        damageReduction = 0.05,
        staminaRegenMultiplier = 1,
    }),
    gear_bramble_boots = table.freeze({
        slot = "feet",
        displayName = Strings.get("world.bramble_boots"),
        description = Strings.get("item.recover_stamina_10naster"),
        damageReduction = 0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_thornwood_bow = table.freeze({
        slot = "weapon",
        displayName = Strings.get("world.thornwood_bow"),
        description = Strings.get("item.strike_from_30_studs_arrows_hit"),
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
        displayName = Strings.get("world.heartwood_maul"),
        description = Strings.get("item.slow_heavy_blows_land_45narder_up"),
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "maul",
        strikeDamageMultiplier = 1.45,
    }),
    gear_briar_lance = table.freeze({
        slot = "weapon",
        displayName = Strings.get("world.briar_lance"),
        description = Strings.get("item.full_strength_strikes_from_14_studs"),
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "lance",
        meleeReach = 14,
        strikeDamageMultiplier = 1,
    }),
    gear_foxfire_sling = table.freeze({
        slot = "weapon",
        displayName = Strings.get("world.foxfire_sling"),
        description = Strings.get("item.stones_from_22_studs_hit_for"),
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "sling",
        strikeRange = 22,
        strikeDamageMultiplier = 0.7,
        onHitSnareSeconds = 2.5,
    }),
    gear_amber_edge = table.freeze({
        slot = "weapon",
        displayName = Strings.get("world.amber_edge"),
        description = Strings.get("item.clean_cuts_hit_10narder_and_return"),
        damageReduction = 0,
        staminaRegenMultiplier = 1,
        kind = "edge",
        strikeDamageMultiplier = 1.1,
        onHitStaminaRefund = 6,
    }),
    gear_warden_cudgel = table.freeze({
        slot = "weapon",
        displayName = Strings.get("world.warden_cudgel"),
        description = Strings.get("item.a_guard_s_weapon_5narder_blows"),
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
        description = Strings.get("item.recover_stamina_4naster_cut_light_on"),
        displayName = Strings.get("item.meadow_cowl"),
        staminaRegenMultiplier = 1.04,
    }),
    gear_bramble_treads = table.freeze({
        slot = "feet",
        damageReduction = 0.03,
        description = Strings.get("item.softens_incoming_damage_by_3neavy_and"),
        displayName = Strings.get("item.bramble_treads"),
        staminaRegenMultiplier = 1,
    }),
    gear_meadow_coat = table.freeze({
        slot = "body",
        damageReduction = 0,
        description = Strings.get("item.recover_stamina_5naster_cut_light_on"),
        displayName = Strings.get("item.meadow_coat"),
        staminaRegenMultiplier = 1.05,
    }),
    gear_bark_plate = table.freeze({
        slot = "body",
        damageReduction = 0.04,
        description = Strings.get("item.softens_incoming_damage_by_4neavy_and"),
        displayName = Strings.get("item.bark_plate"),
        staminaRegenMultiplier = 1,
    }),
    gear_meadow_wraps = table.freeze({
        slot = "hands",
        damageReduction = 0,
        description = Strings.get("item.recover_stamina_4naster_cut_light_on"),
        displayName = Strings.get("item.meadow_wraps"),
        staminaRegenMultiplier = 1.04,
    }),
    gear_bramble_gauntlets = table.freeze({
        slot = "hands",
        damageReduction = 0.03,
        description = Strings.get("item.softens_incoming_damage_by_3neavy_and"),
        displayName = Strings.get("item.bramble_gauntlets"),
        staminaRegenMultiplier = 1,
    }),
    gear_foxfire_token = table.freeze({
        slot = "charm",
        damageReduction = 0,
        description = Strings.get("item.recover_stamina_5naster_it_hums_faintly"),
        displayName = Strings.get("item.foxfire_token"),
        staminaRegenMultiplier = 1.05,
    }),
    gear_heartwood_seal = table.freeze({
        slot = "charm",
        damageReduction = 0.04,
        description = Strings.get("item.softens_incoming_damage_by_4neartwood_rememb"),
        displayName = Strings.get("item.heartwood_seal"),
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
        displayName = Strings.get("item.stope_bow"),
        description = Strings.get("item.strikes_from_30_studs_hits_for"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "bow",
        strikeRange = 30,
        strikeDamageMultiplier = 0.88,
    }),
    gear_drift_maul = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.drift_maul"),
        description = Strings.get("item.hits_for_150neavier_and_slower_to"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "maul",
        strikeDamageMultiplier = 1.5,
    }),
    gear_pit_lance = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.pit_lance"),
        description = Strings.get("item.reaches_14_studs_hits_for_108neavier"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "lance",
        meleeReach = 14,
        strikeDamageMultiplier = 1.08,
    }),
    gear_slag_sling = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.slag_sling"),
        description = Strings.get("item.strikes_from_22_studs_hits_for"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "sling",
        strikeRange = 22,
        strikeDamageMultiplier = 0.78,
        onHitSnareSeconds = 2.5,
    }),
    gear_coalglass_edge = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.coalglass_edge"),
        description = Strings.get("item.hits_for_118_refunds_6_stamina"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "edge",
        strikeDamageMultiplier = 1.18,
        onHitStaminaRefund = 6,
    }),
    gear_shift_cudgel = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.shift_cudgel"),
        description = Strings.get("item.hits_for_113_softens_hits_taken"),
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
        kind = "cudgel",
        strikeDamageMultiplier = 1.13,
    }),
    gear_ironroot_cowl = table.freeze({
        slot = "head",
        displayName = Strings.get("item.ironroot_cowl"),
        description = Strings.get("item.recover_stamina_6naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
    }),
    gear_ironroot_helm = table.freeze({
        slot = "head",
        displayName = Strings.get("item.ironroot_helm"),
        description = Strings.get("item.softens_incoming_damage_by_4neavy_and"),
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
    }),
    gear_ironroot_coat = table.freeze({
        slot = "body",
        displayName = Strings.get("item.ironroot_coat"),
        description = Strings.get("item.recover_stamina_6naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
    }),
    gear_ironroot_plate = table.freeze({
        slot = "body",
        displayName = Strings.get("item.ironroot_plate"),
        description = Strings.get("item.softens_incoming_damage_by_4neavy_and"),
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
    }),
    gear_ironroot_wraps = table.freeze({
        slot = "hands",
        displayName = Strings.get("item.ironroot_wraps"),
        description = Strings.get("item.recover_stamina_6naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
    }),
    gear_ironroot_gauntlets = table.freeze({
        slot = "hands",
        displayName = Strings.get("item.ironroot_gauntlets"),
        description = Strings.get("item.softens_incoming_damage_by_4neavy_and"),
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
    }),
    gear_ironroot_boots = table.freeze({
        slot = "feet",
        displayName = Strings.get("item.ironroot_boots"),
        description = Strings.get("item.recover_stamina_6naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
    }),
    gear_ironroot_treads = table.freeze({
        slot = "feet",
        displayName = Strings.get("item.ironroot_treads"),
        description = Strings.get("item.softens_incoming_damage_by_4neavy_and"),
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
    }),
    gear_ironroot_token = table.freeze({
        slot = "charm",
        displayName = Strings.get("item.ironroot_token"),
        description = Strings.get("item.recover_stamina_6naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
    }),
    gear_ironroot_seal = table.freeze({
        slot = "charm",
        displayName = Strings.get("item.ironroot_seal"),
        description = Strings.get("item.softens_incoming_damage_by_4neavy_and"),
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
    }),
    gear_reed_bow = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.reed_bow"),
        description = Strings.get("item.strikes_from_33_studs_hits_for"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "bow",
        strikeRange = 33,
        strikeDamageMultiplier = 0.8,
    }),
    gear_bog_maul = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.bog_maul"),
        description = Strings.get("item.reaches_11_studs_hits_for_145nonger"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "maul",
        meleeReach = 11,
        strikeDamageMultiplier = 1.45,
    }),
    gear_punt_lance = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.punt_lance"),
        description = Strings.get("item.reaches_17_studs_hits_for_100nonger"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "lance",
        meleeReach = 17,
        strikeDamageMultiplier = 1.0,
    }),
    gear_mirror_sling = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.mirror_sling"),
        description = Strings.get("item.strikes_from_25_studs_hits_for"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "sling",
        strikeRange = 25,
        strikeDamageMultiplier = 0.7,
        onHitSnareSeconds = 2.5,
    }),
    gear_witchlight_edge = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.witchlight_edge"),
        description = Strings.get("item.reaches_11_studs_hits_for_110"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "edge",
        meleeReach = 11,
        strikeDamageMultiplier = 1.1,
        onHitStaminaRefund = 6,
    }),
    gear_ferry_cudgel = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.ferry_cudgel"),
        description = Strings.get("item.reaches_11_studs_hits_for_105"),
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
        kind = "cudgel",
        meleeReach = 11,
        strikeDamageMultiplier = 1.05,
    }),
    gear_mireglass_cowl = table.freeze({
        slot = "head",
        displayName = Strings.get("item.mireglass_cowl"),
        description = Strings.get("item.recover_stamina_8naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.08,
    }),
    gear_mireglass_helm = table.freeze({
        slot = "head",
        displayName = Strings.get("item.mireglass_helm"),
        description = Strings.get("item.softens_incoming_damage_by_5neavy_and"),
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_mireglass_coat = table.freeze({
        slot = "body",
        displayName = Strings.get("item.mireglass_coat"),
        description = Strings.get("item.recover_stamina_8naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.08,
    }),
    gear_mireglass_plate = table.freeze({
        slot = "body",
        displayName = Strings.get("item.mireglass_plate"),
        description = Strings.get("item.softens_incoming_damage_by_5neavy_and"),
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_mireglass_wraps = table.freeze({
        slot = "hands",
        displayName = Strings.get("item.mireglass_wraps"),
        description = Strings.get("item.recover_stamina_8naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.08,
    }),
    gear_mireglass_gauntlets = table.freeze({
        slot = "hands",
        displayName = Strings.get("item.mireglass_gauntlets"),
        description = Strings.get("item.softens_incoming_damage_by_5neavy_and"),
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_mireglass_boots = table.freeze({
        slot = "feet",
        displayName = Strings.get("item.mireglass_boots"),
        description = Strings.get("item.recover_stamina_8naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.08,
    }),
    gear_mireglass_treads = table.freeze({
        slot = "feet",
        displayName = Strings.get("item.mireglass_treads"),
        description = Strings.get("item.softens_incoming_damage_by_5neavy_and"),
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_mireglass_token = table.freeze({
        slot = "charm",
        displayName = Strings.get("item.mireglass_token"),
        description = Strings.get("item.recover_stamina_8naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.08,
    }),
    gear_mireglass_seal = table.freeze({
        slot = "charm",
        displayName = Strings.get("item.mireglass_seal"),
        description = Strings.get("item.softens_incoming_damage_by_5neavy_and"),
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_jetty_bow = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.jetty_bow"),
        description = Strings.get("item.strikes_from_36_studs_hits_for"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "bow",
        strikeRange = 36,
        strikeDamageMultiplier = 0.8,
    }),
    gear_ballast_maul = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.ballast_maul"),
        description = Strings.get("item.reaches_12_studs_hits_for_149nade"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "maul",
        meleeReach = 12,
        strikeDamageMultiplier = 1.49,
    }),
    gear_gaff_lance = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.gaff_lance"),
        description = Strings.get("item.reaches_12_studs_hits_for_104nade"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "lance",
        meleeReach = 12,
        strikeDamageMultiplier = 1.04,
    }),
    gear_halyard_sling = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.halyard_sling"),
        description = Strings.get("item.strikes_from_28_studs_hits_for"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "sling",
        strikeRange = 28,
        strikeDamageMultiplier = 0.7,
        onHitSnareSeconds = 2.5,
    }),
    gear_amberglass_edge = table.freeze({
        slot = "weapon",
        displayName = Strings.get("store.amberglass_edge"),
        description = Strings.get("item.reaches_12_studs_hits_for_114"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.0,
        kind = "edge",
        meleeReach = 12,
        strikeDamageMultiplier = 1.14,
        onHitStaminaRefund = 6,
    }),
    gear_breakwater_cudgel = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.breakwater_cudgel"),
        description = Strings.get("item.reaches_12_studs_hits_for_109"),
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.0,
        kind = "cudgel",
        meleeReach = 12,
        strikeDamageMultiplier = 1.09,
    }),
    gear_tempest_cowl = table.freeze({
        slot = "head",
        displayName = Strings.get("item.tempest_cowl"),
        description = Strings.get("item.recover_stamina_10naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_tempest_helm = table.freeze({
        slot = "head",
        displayName = Strings.get("item.tempest_helm"),
        description = Strings.get("item.softens_incoming_damage_by_5neavy_and"),
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_tempest_coat = table.freeze({
        slot = "body",
        displayName = Strings.get("item.tempest_coat"),
        description = Strings.get("item.recover_stamina_10naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_tempest_plate = table.freeze({
        slot = "body",
        displayName = Strings.get("item.tempest_plate"),
        description = Strings.get("item.softens_incoming_damage_by_5neavy_and"),
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_tempest_wraps = table.freeze({
        slot = "hands",
        displayName = Strings.get("item.tempest_wraps"),
        description = Strings.get("item.recover_stamina_10naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_tempest_gauntlets = table.freeze({
        slot = "hands",
        displayName = Strings.get("item.tempest_gauntlets"),
        description = Strings.get("item.softens_incoming_damage_by_5neavy_and"),
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_tempest_boots = table.freeze({
        slot = "feet",
        displayName = Strings.get("item.tempest_boots"),
        description = Strings.get("item.recover_stamina_10naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_tempest_treads = table.freeze({
        slot = "feet",
        displayName = Strings.get("item.tempest_treads"),
        description = Strings.get("item.softens_incoming_damage_by_5neavy_and"),
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_tempest_token = table.freeze({
        slot = "charm",
        displayName = Strings.get("item.tempest_token"),
        description = Strings.get("item.recover_stamina_10naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.1,
    }),
    gear_tempest_seal = table.freeze({
        slot = "charm",
        displayName = Strings.get("item.tempest_seal"),
        description = Strings.get("item.softens_incoming_damage_by_5neavy_and"),
        damageReduction = 0.05,
        staminaRegenMultiplier = 1.0,
    }),
    gear_vale_bow = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.vale_bow"),
        description = Strings.get("item.strikes_from_30_studs_hits_for_2"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
        kind = "bow",
        strikeRange = 30,
        strikeDamageMultiplier = 0.75,
    }),
    gear_thaw_maul = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.thaw_maul"),
        description = Strings.get("item.hits_for_140_returns_stamina_6naster"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
        kind = "maul",
        strikeDamageMultiplier = 1.4,
    }),
    gear_crevasse_lance = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.crevasse_lance"),
        description = Strings.get("item.reaches_14_studs_hits_for_95"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
        kind = "lance",
        meleeReach = 14,
        strikeDamageMultiplier = 0.95,
    }),
    gear_hush_sling = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.hush_sling"),
        description = Strings.get("item.strikes_from_22_studs_hits_for_2"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
        kind = "sling",
        strikeRange = 22,
        strikeDamageMultiplier = 0.65,
        onHitSnareSeconds = 2.5,
    }),
    gear_rime_edge = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.rime_edge"),
        description = Strings.get("item.hits_for_105_returns_stamina_6naster"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.06,
        kind = "edge",
        strikeDamageMultiplier = 1.05,
        onHitStaminaRefund = 6,
    }),
    gear_cloister_cudgel = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.cloister_cudgel"),
        description = Strings.get("item.hits_for_100_softens_hits_taken"),
        damageReduction = 0.04,
        staminaRegenMultiplier = 1.06,
        kind = "cudgel",
        strikeDamageMultiplier = 1.0,
    }),
    gear_frostmere_cowl = table.freeze({
        slot = "head",
        displayName = Strings.get("item.frostmere_cowl"),
        description = Strings.get("item.recover_stamina_12naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.12,
    }),
    gear_frostmere_helm = table.freeze({
        slot = "head",
        displayName = Strings.get("item.frostmere_helm"),
        description = Strings.get("item.softens_incoming_damage_by_6neavy_and"),
        damageReduction = 0.06,
        staminaRegenMultiplier = 1.0,
    }),
    gear_frostmere_coat = table.freeze({
        slot = "body",
        displayName = Strings.get("item.frostmere_coat"),
        description = Strings.get("item.recover_stamina_12naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.12,
    }),
    gear_frostmere_plate = table.freeze({
        slot = "body",
        displayName = Strings.get("item.frostmere_plate"),
        description = Strings.get("item.softens_incoming_damage_by_6neavy_and"),
        damageReduction = 0.06,
        staminaRegenMultiplier = 1.0,
    }),
    gear_frostmere_wraps = table.freeze({
        slot = "hands",
        displayName = Strings.get("item.frostmere_wraps"),
        description = Strings.get("item.recover_stamina_12naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.12,
    }),
    gear_frostmere_gauntlets = table.freeze({
        slot = "hands",
        displayName = Strings.get("item.frostmere_gauntlets"),
        description = Strings.get("item.softens_incoming_damage_by_6neavy_and"),
        damageReduction = 0.06,
        staminaRegenMultiplier = 1.0,
    }),
    gear_frostmere_boots = table.freeze({
        slot = "feet",
        displayName = Strings.get("item.frostmere_boots"),
        description = Strings.get("item.recover_stamina_12naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.12,
    }),
    gear_frostmere_treads = table.freeze({
        slot = "feet",
        displayName = Strings.get("item.frostmere_treads"),
        description = Strings.get("item.softens_incoming_damage_by_6neavy_and"),
        damageReduction = 0.06,
        staminaRegenMultiplier = 1.0,
    }),
    gear_frostmere_token = table.freeze({
        slot = "charm",
        displayName = Strings.get("item.frostmere_token"),
        description = Strings.get("item.recover_stamina_12naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.12,
    }),
    gear_frostmere_seal = table.freeze({
        slot = "charm",
        displayName = Strings.get("item.frostmere_seal"),
        description = Strings.get("item.softens_incoming_damage_by_6neavy_and"),
        damageReduction = 0.06,
        staminaRegenMultiplier = 1.0,
    }),
    gear_tier_bow = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.tier_bow"),
        description = Strings.get("item.strikes_from_30_studs_hits_for_3"),
        damageReduction = 0.03,
        staminaRegenMultiplier = 1.0,
        kind = "bow",
        strikeRange = 30,
        strikeDamageMultiplier = 0.75,
    }),
    gear_kiln_maul = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.kiln_maul"),
        description = Strings.get("item.hits_for_140_softens_hits_taken"),
        damageReduction = 0.03,
        staminaRegenMultiplier = 1.0,
        kind = "maul",
        strikeDamageMultiplier = 1.4,
    }),
    gear_procession_lance = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.procession_lance"),
        description = Strings.get("item.reaches_14_studs_hits_for_95_2"),
        damageReduction = 0.03,
        staminaRegenMultiplier = 1.0,
        kind = "lance",
        meleeReach = 14,
        strikeDamageMultiplier = 0.95,
    }),
    gear_cinder_sling = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.cinder_sling"),
        description = Strings.get("item.strikes_from_22_studs_hits_for_3"),
        damageReduction = 0.03,
        staminaRegenMultiplier = 1.0,
        kind = "sling",
        strikeRange = 22,
        strikeDamageMultiplier = 0.65,
        onHitSnareSeconds = 2.5,
    }),
    gear_memory_edge = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.memory_edge"),
        description = Strings.get("item.hits_for_105_softens_hits_taken"),
        damageReduction = 0.03,
        staminaRegenMultiplier = 1.0,
        kind = "edge",
        strikeDamageMultiplier = 1.05,
        onHitStaminaRefund = 6,
    }),
    gear_bailiff_cudgel = table.freeze({
        slot = "weapon",
        displayName = Strings.get("item.bailiff_cudgel"),
        description = Strings.get("item.hits_for_100_softens_hits_taken_2"),
        damageReduction = 0.07,
        staminaRegenMultiplier = 1.0,
        kind = "cudgel",
        strikeDamageMultiplier = 1.0,
    }),
    gear_cinderfall_cowl = table.freeze({
        slot = "head",
        displayName = Strings.get("item.cinderfall_cowl"),
        description = Strings.get("item.recover_stamina_14naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.14,
    }),
    gear_cinderfall_helm = table.freeze({
        slot = "head",
        displayName = Strings.get("item.cinderfall_helm"),
        description = Strings.get("item.softens_incoming_damage_by_7neavy_and"),
        damageReduction = 0.07,
        staminaRegenMultiplier = 1.0,
    }),
    gear_cinderfall_coat = table.freeze({
        slot = "body",
        displayName = Strings.get("item.cinderfall_coat"),
        description = Strings.get("item.recover_stamina_14naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.14,
    }),
    gear_cinderfall_plate = table.freeze({
        slot = "body",
        displayName = Strings.get("item.cinderfall_plate"),
        description = Strings.get("item.softens_incoming_damage_by_7neavy_and"),
        damageReduction = 0.07,
        staminaRegenMultiplier = 1.0,
    }),
    gear_cinderfall_wraps = table.freeze({
        slot = "hands",
        displayName = Strings.get("item.cinderfall_wraps"),
        description = Strings.get("item.recover_stamina_14naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.14,
    }),
    gear_cinderfall_gauntlets = table.freeze({
        slot = "hands",
        displayName = Strings.get("item.cinderfall_gauntlets"),
        description = Strings.get("item.softens_incoming_damage_by_7neavy_and"),
        damageReduction = 0.07,
        staminaRegenMultiplier = 1.0,
    }),
    gear_cinderfall_boots = table.freeze({
        slot = "feet",
        displayName = Strings.get("item.cinderfall_boots"),
        description = Strings.get("item.recover_stamina_14naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.14,
    }),
    gear_cinderfall_treads = table.freeze({
        slot = "feet",
        displayName = Strings.get("item.cinderfall_treads"),
        description = Strings.get("item.softens_incoming_damage_by_7neavy_and"),
        damageReduction = 0.07,
        staminaRegenMultiplier = 1.0,
    }),
    gear_cinderfall_token = table.freeze({
        slot = "charm",
        displayName = Strings.get("item.cinderfall_token"),
        description = Strings.get("item.recover_stamina_14naster_cut_light_on"),
        damageReduction = 0.0,
        staminaRegenMultiplier = 1.14,
    }),
    gear_cinderfall_seal = table.freeze({
        slot = "charm",
        displayName = Strings.get("item.cinderfall_seal"),
        description = Strings.get("item.softens_incoming_damage_by_7neavy_and"),
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
