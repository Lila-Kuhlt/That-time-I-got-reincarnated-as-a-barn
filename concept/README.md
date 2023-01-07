# Concept Design

The game is a tower defense game centered around harvesting plants.

## Entities

- player
- enemies
- projectiles

### Player

- can walk around on the map
- can use items
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
- [Plants](#Plants)
- Blocker (Rocks, Trees, River, ...)

## Buildings

- have health
- Center / Farmhouse: where seeds/harvested plants will be brought to buy new buildings
  to fill up ammunition (and research)
- Towers: will be used to attack enemies using harvested plants / seeds

## Stats
- (AS)  Attack speed
- (DMG) Damage
- (AOE) Area of Effect
- (KB)  Knockback
- (PEN) Penetration
- (RG)  Range
- (PS)  Projectile Speed
- (HP)  Health

## Plants

- have health
- growth stages
  - seeds   (cannot be harvested)
  - growing (cannot be harvested)
  - ripe    (can be harvested, has a chance to drop seeds)
  - rotten  (can be harvested, removes the plant, drops nothing)

- different crops have different modifiers
    * seeds:    10%
    * growing:  50%
    * ripe:     100%
    * rotten:   0%

**Crops** \
!! *Stats are not final yet* !!

- Chilli    (AS + PS)
- Potato    (DMG + KB)
- Tomato    (AOE)
- Aubergine (PEN)

<!-- TODO : Maybe use fences instead?
**Special Plants**
- Hedge (Does not grow, or drop crops)
-->

## Enemies

- wild animals (bear, wolf, elk, boar, ...)
- damage crops (when walking over them) and attack buildings

## Items
- **Scythe/Sickle**: Used to harvest crops (and attack enemies)
- **Watering**: Used to heal plants

