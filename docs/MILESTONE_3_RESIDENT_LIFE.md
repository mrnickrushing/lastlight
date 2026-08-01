# Milestone 3 resident life

Build `0.20.0` brings the complete four-person Bramblewake town cast into the
physical world. Mara remains the prologue builder; resolving chapter one now
brings Tomas Reed, Pip Wren, and Ena Moss home.

## Resident readability

- **Tomas Reed, quartermaster:** apron, cookpot, and ladle; works from the
  Wayfarer Inn supply area.
- **Pip Wren, courier:** route map and field satchel; studies the Town Board and
  the safe roads.
- **Ena Moss, seedkeeper:** seed basket, visible bundles, and broad work hat;
  tends the changed Greenward landscape.
- All three use distinct colors, silhouettes, labels, and subtle shared
  resident motion at gameplay distance.

## Daily routine

The world service owns one phase schedule for each resident:

1. During the day they occupy their profession-specific workplace.
2. At dusk they leave work and muster along the Lantern Road.
3. At night they occupy separate watch positions and carry lit watch lanterns.
4. At dawn they return to work and stow the watch lanterns.

Routine state is written as model attributes for Studio inspection. It is
presentation-only in this increment: resident combat support, injury, bond,
housing preference, and quest arcs remain later systems.

## Validation

`TownProgression` tests cover locked and chapter-unlocked resident rosters.
`npm test` regenerates and verifies both place artifacts. Studio/device review
remains required for physical overlap, streaming, and night-watch sight lines.
