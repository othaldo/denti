# AGENTS.md

# Denti: Divine Dentistry

Denti: Divine Dentistry is a small 2D arena-survivor / roguelite inspired by games such as Brotato and Vampire Survivors.

The player directly controls Denti, a small divine tooth character.
Movement is manual, while attacks are mostly automatic.

The tone should be humorous, charming, slightly absurd, and strongly themed around dentistry.

Examples:
- metal crowns provide armor
- floss can become a weapon
- fluoride can improve regeneration or defense
- plaque, sugar and bacteria are enemies
- dental terminology can be used for stats, items, enemies and achievements

The game should remain easy to understand and quick to play.


## Technology

- Engine: Godot 4.x
- Language: GDScript
- Game type: 2D
- Target platform initially: Desktop Linux
- Keep the project portable to Windows where practical.

Prefer standard Godot functionality over unnecessary third-party dependencies.


## Core Gameplay

The intended gameplay loop is:

1. The player controls Denti inside an arena.
2. Enemies spawn continuously during a timed wave.
3. Enemies move toward Denti and try to damage him.
4. Denti's weapons attack automatically.
5. Defeated enemies can drop:
   - XP
   - coins
6. XP increases Denti's level.
7. On level-up:
   - pause gameplay
   - offer 3 random stat upgrades
   - player chooses exactly one
8. Coins are accumulated during the wave.
9. After the wave:
   - pause combat
   - open the shop
   - offer random items and weapons
   - allow rerolling shop contents
10. Start the next, harder wave.

The player should mainly make decisions through:
- movement and positioning
- level-up choices
- weapons
- shop purchases
- item synergies


## Progression Philosophy

XP and money serve different purposes.

### XP

XP grants level-ups.

Level-ups should primarily improve basic stats.

Examples:

- Bisskraft: damage
- Härte: armor / damage reduction
- Schmelz: maximum health
- Putzeifer: attack speed
- Glanz: critical chance / luck
- Speichel: regeneration
- Bewegung: movement speed

Names may evolve, but dental-themed stat names are preferred.

### Coins

Coins are used in the shop.

Shop purchases should define the player's build more strongly than level-ups.

Examples:

- Metallkrone
- Goldkrone
- Zahnseide
- Fluoridgel
- Implantat
- Zahnbürste
- Mundspülung
- Bohrer

Items should ideally create interesting trade-offs and synergies rather than only providing flat stat increases.


## Initial Prototype Scope

Do not overbuild the first version.

The first playable prototype should contain approximately:

- 1 playable character: Denti
- 1 arena
- 3 enemy types
- 3 weapons
- 10–20 items
- 6–8 player stats
- 10 waves
- 1 simple boss
- level-up selection
- shop between waves
- basic game-over and restart flow

Placeholder visuals are acceptable until proper assets exist.

Prioritize a fun, working gameplay loop over polish.


## Project Structure

Use the following structure where possible:

denti/
├── project.godot
├── AGENTS.md
├── scenes/
│   ├── game/
│   ├── player/
│   ├── enemies/
│   └── ui/
├── scripts/
│   ├── player/
│   ├── enemies/
│   ├── systems/
│   └── weapons/
├── data/
│   ├── items/
│   ├── enemies/
│   └── weapons/
├── assets/
│   ├── denti/
│   ├── enemies/
│   ├── items/
│   ├── ui/
│   └── environment/
└── tests/


## Architecture

Keep gameplay systems modular.

Prefer composition over deep inheritance hierarchies.

Avoid large all-purpose scripts.

Separate responsibilities such as:

- player movement
- health
- stats
- weapons
- damage
- enemy spawning
- wave progression
- XP
- leveling
- loot
- shop
- item effects
- UI

Systems should communicate using clear interfaces and Godot signals where appropriate.

Avoid tightly coupling UI code to gameplay logic.


## Data-Driven Design

Items, weapons and enemies should be data-driven wherever practical.

Prefer custom Godot `Resource` types for structured gameplay data.

Examples:

- ItemData
- WeaponData
- EnemyData
- UpgradeData

Gameplay values should generally not be scattered as magic numbers throughout scripts.

A weapon definition should be able to describe things such as:

- display name
- description
- icon
- damage
- attack speed
- range
- projectile speed
- number of projectiles
- rarity

An item definition should be able to describe things such as:

- display name
- description
- rarity
- price
- stat changes
- special effects
- icon


## Stats

Player stats should have one authoritative source.

Avoid duplicating stat values across multiple nodes.

Changes caused by:
- level-ups
- items
- buffs
- debuffs

should modify the same underlying stat system.

Derived stats should be recalculated consistently.


## Weapons

Weapons should normally attack automatically.

Possible targeting strategies include:

- nearest enemy
- random nearby enemy
- direction of movement
- radial attack
- orbiting weapon
- area-of-effect around Denti

Weapon implementations should share reusable components where reasonable.

Avoid implementing every weapon as a completely unrelated special case.


## Enemies

Enemies should initially remain simple.

Basic enemy behavior:

- spawn outside or near the visible arena bounds
- move toward Denti
- deal contact damage
- have health
- die when health reaches zero
- optionally drop XP and coins

Different enemies should vary through combinations of:

- movement speed
- health
- size
- damage
- spawn frequency
- special behavior

Avoid complex AI unless required by gameplay.


## Waves

Wave difficulty should scale predictably.

Possible scaling values include:

- enemy health
- enemy damage
- spawn rate
- enemy variety
- elite enemies

Wave progression should be controlled by a dedicated system rather than being embedded in enemy scripts.


## Shop

The shop appears between waves.

Initial shop functionality:

- display several random offers
- show price
- buy item or weapon
- reroll offers for coins
- continue to next wave

Future possibilities may include:

- locking an offer
- rarity progression
- discounts
- selling
- combining items

Do not implement these future systems until they are needed.


## UI

UI should be functional before it is beautiful.

Important HUD elements:

- health
- XP
- current level
- coins
- wave number
- wave timer

Level-up UI:

- pause gameplay
- show 3 upgrade cards
- clearly show what each upgrade changes

Shop UI:

- clearly show item name
- effect
- price
- rarity if relevant

Menus should work well with mouse input first.

Keyboard/controller support can be added later.


## Art Direction

The intended visual style is colorful, readable and playful.

The game may use:
- pixel art
- voxel-inspired pixel art
- stylized 2D sprites

Denti is a small divine tooth mascot.

The dental theme should remain obvious.

Do not generate temporary visual assets inside code if an existing placeholder asset can be reused.

Keep asset paths organized beneath `assets/`.


## Humor and Naming

Humor is an important part of the project.

Item names, descriptions and achievements may use dental jokes.

Examples:

Metallkrone

+3 Härte
-3% Bewegung

"Unzerstörbar. Außer bei Karamell."

Possible achievement:

"Alle huldigen dem Denti"

Humor should be short and readable rather than filling the UI with large amounts of text.


## GDScript Style

Use typed GDScript where practical.

Prefer:

```gdscript
var health: float = 100.0
var level: int = 1