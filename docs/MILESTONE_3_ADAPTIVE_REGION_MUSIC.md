# Milestone 3: Adaptive region music

## Outcome

Last Light now has a client-local adaptive music system with a distinct day, dusk, and night score for Emberhollow and every launch region. The playable Bramblewake expedition switches away from the town score immediately, night selects each world's most threatening track, and an active Blackout takes ownership with a separate pulse track.

## Music identities

| World | Day | Dusk | Night |
| --- | --- | --- | --- |
| Emberhollow | meadow warmth | glade preparation | nocturnal unease |
| Bramblewake | moss and discovery | forest whispers | dark forest threat |
| Ironroot | machine resonance | repeating tension | industrial venom |
| Mireglass | mystic wetland | nocturne | engulfing darkness |
| Tempest | lighthouse resolve | arcane storm | violent storm pulse |
| Frostmere | arctic negative space | ruined chapel strings | catacomb dread |
| Cinderfall | magmatic pressure | silent ruins | seance tension |
| Hollow Below | forbidden study | abyssal descent | inner sanctum ritual |

## Playback behavior

- Two non-spatial `Sound` slots in `SoundService` crossfade over 3.2 seconds.
- Only the incoming track is preloaded; startup never waits for the entire 25-track catalog.
- Music playback is local to each player and follows server-authored snapshot state.
- First input retries playback for mobile clients that defer autoplay.
- Per-track volume targets compensate for the measured source loudness range.
- Music communicates phase and tone, but all gameplay phases remain readable through the HUD, lighting, objectives, and world signals.

## Asset provenance

All 25 tracks came from Roblox Creator Store Audio and are free, public-domain/open-use assets from the verified `APMOfficial` or `DistrokidOfficial` providers. The actual cloud payload of every selection was downloaded and decoded with `ffprobe`; durations, codecs, names, artists, providers, and measured mean levels are recorded in `assets/audio/manifest.json`.

## Acceptance

1. Enter Play mode in `build/LastLightTest.rbxlx` and confirm Emberhollow day music begins after initial state arrives.
2. Advance to dusk and night; each transition must crossfade without overlapping at full volume.
3. Enter Bramblewake and confirm its music differs from Emberhollow.
4. During a Bramblewake Blackout, confirm the dedicated pulse replaces regional music.
5. Test once with audio muted and once on a phone; no objective may depend on music, and first touch must recover deferred playback.
