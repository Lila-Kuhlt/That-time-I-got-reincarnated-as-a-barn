# Concept Design

The game is a tower defense game centered around harvesting plants.

## Entities

- player
- enemies
- projectiles

### Player

- can walk around on the map
- has scythe to harvest plants
- can walk through plants, but not through buildings/towers or blockers
- camera follows player

## UI

- Player Inventory / Hotbar?
- Farmhouse / Center Inventory
- Building inventory + stats/info

## Grid

- 2D rectangular grid
- top-down view

### Tiles

- Wasteland: Land where no plants can be placed
- Farmland: Land where plants can be placed
- Plants (Wheat, Tomatos, ...)
- Blocker (Rocks, Trees, River, ...)

## Buildings

- Center / Farmhouse: where seeds/harvested plants will be brought
  to fill up ammunition (and research)
- Towers: will be used to attack enemies using harvested plants / seeds

## Plants/Crops

- 4 base crops: corn, tomato, salad, ???
- growth stages
  - seeds (cannot be harvested)
  - growing (cannot be harvested)
  - ripe (can be harvested)
  - rotten (can be harvested, but gives nothing)
- different crops have different modifiers
  - as ammunition: area of effect, damage, fire rate, ... (stats)
  - while growing: damage, fire rate, ... (multipliers)
    - seeds: none
    - growing: slight buffs
    - ripe: full buffs
    - rotten: none
- plants can be crossed/mutated to combine effects ("research")
