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

- have health
- Center / Farmhouse: where seeds/harvested plants will be brought
  to fill up ammunition (and research)
- Towers: will be used to attack enemies using harvested plants / seeds

## Plants/Crops

- have health
- 3 base crops: corn, tomato, carrot
- growth stages
  - seeds (cannot be harvested)
  - growing (cannot be harvested)
  - ripe (can be harvested)
  - rotten (can be harvested, but gives nothing)
- different crops have different modifiers (area of effect, damage, fire rate, projectile speed, range, ...)
  - as ammunition: stats
  - while growing: multipliers
    - seeds: none
    - growing: slight buffs
    - ripe: full buffs
    - rotten: none
- plants can be crossed/mutated to combine effects ("research")
  - no duplicate base crops
  - 3 + 3 + 1 = 7 total crops

## Enemies

- wild animals (bear, wolf, elk, boar, ...)
- later mutants of the above animals
- damage crops (when walking over them) and attack buildings

## Lore

(background lore, doesn't have to be part of the game)

- while the player is experimenting with and mutating crops, aliens are experimenting with and mutating wild animals, which attack the player's base
