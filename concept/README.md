# Design concept

The game is a tower defense game centered around harvesting plants.

## Entities

- [Player](/concept/entity.md#player)
- [Enemy](/concept/entity.md#enemy)

## [Buildings](/concept/building.md)

## [Plants](/concept/plant.md)

## Map

- map is automatically generated at the start of the game
- map is divided into plots, which can be purchased (using crops)
  - purchasing a plot enables the player to build in that plot
- each plot has enemy spawners, which disappear on purchase
  - only spawners in neighboring unpurchased plots are active

## UI

### Hotbar

The hotbar is used to select which crop to plant, what tool to use and as
storage for item in general.

### Store

The Store menu is used to sell crops for buildings and items.
<!-- or better crops -->

### Stats/Info Hover

When hovering over certain buildings the player should get information about
the building. Such as the stats of a Plant, or the current buffs of a Turret.



## Tiles

Tiles are the lowest layer of the game. Tiles are itself can not be destructed,
only replaced. There are 4 types of Tiles:

- **Wasteland** \
   On Wasteland no plants can be planted.

- **Farmland**: \
   Land where plants can be placed.

- **River**: \
   Water, in water no plants can be planted.

- **Blocker**: \
   Land where that cannot be made into farmland.



## Stats

- (AS) Attack speed
- (DMG) Damage
- (AOE) Area of Effect
- (KB) Knockback
- (PEN) Penetration
- (RG) Range
- (PS) Projectile Speed
- (HP) Health


## Items

- **Scythe/Sickle**: \
   Used to harvest crops (and attack enemies)

- **Watering can**: \
   Used to heal plants
