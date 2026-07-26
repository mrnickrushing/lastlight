--!strict

-- This is intentionally a scaffold, not a claim that the game is implemented.
-- Runtime constants move here only after their milestone is approved and tested.
return table.freeze({
    GameName = "Last Light",
    MaxExpeditionPlayers = 8,
    NormalDaySeconds = 12 * 60,
    DuskSeconds = 2 * 60,
    NormalNightSeconds = 6 * 60,
    BlackoutNightSeconds = 9 * 60,
    BlackoutInterval = 7,
    SaveSchemaVersion = 1,
})

