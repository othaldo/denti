# AGENTS.md

# Denti: Divine Dentistry

Denti: Divine Dentistry is a small 2D arena-survivor / roguelite inspired by Brotato and Vampire Survivors.

The player directly controls Denti, a small divine tooth. Movement is manual; attacks are mostly automatic. The tone is humorous, charming, slightly absurd, and strongly dentistry-themed.

The game should remain easy to understand and quick to play, but build choices should become deep enough to support repeat runs.

## Read this first

The original prototype scope has already been exceeded. Do not treat this repository as a blank MVP anymore.

Current playable state includes roughly:

- 20 timed waves
- minibosses every 5 waves and a final boss on wave 20
- 4 normal enemy types, 2 elite variants and bosses
- 8 weapons with hand-slot costs and weapon fusion up to tier IV
- 30 shop items with stack limits and real synergies
- 8 level-up stats
- rarity and luck systems
- shop rerolls, weapon selling and build-aware item weighting
- save/resume during combat, level-up and shop states
- music, boss music, SFX, options and FPS display
- automated tests
- automatic Godot Web export and GitHub Pages deployment

See `README.md`, `docs/items.md`, `docs/waffen.md` and `docs/ROADMAP.md` for the current player-facing state and near-term plan.

## Current development goal: Pressure + Build Depth

The most important current player feedback is:

- Denti outscales enemies too easily in the middle/late run.
- Normal enemies eventually become universal one-shots.
- Bosses can die in roughly 2-5 seconds.
- The arena stops creating enough movement/positioning pressure.
- Waves need more enemies, more frequent hordes and more projectile pressure / bullet-hell patterns.
- Balance needs instrumentation instead of only tuning by feel.
- More items are wanted, but they should primarily deepen synergies instead of adding flat-stat filler.
- Rare random chests should drop items during runs; the player may keep the item or scrap it for coins. Luck should influence chest/rarity chances without allowing unlimited snowballing.
- Active combat should not be repeatedly interrupted by level-up or chest-choice modals. Rewards are resolved after the wave.

Do not solve the difficulty problem only by multiplying all enemy HP. Trash enemies may still die quickly. The desired late-run feeling is that Denti is extremely powerful while the arena remains dangerous because of density, elites, projectiles, telegraphed attacks and boss mechanics.

### Immediate implementation priority

Work in approximately this order unless a task explicitly says otherwise:

1. Combat telemetry and balance visibility
   - recent/rolling DPS
   - peak DPS where useful
   - kills per second
   - enemies alive / spawn density
   - damage taken
   - boss time-to-kill
   - useful run economy numbers
   - keep this as debug/developer UI; do not clutter normal play
2. Increase enemy pressure
   - more enemies in later waves
   - more frequent horde events
   - wave sub-events / bursts rather than only a flat continuous spawn stream
   - tune performance while increasing density
3. Reusable bullet-hell / projectile-pattern system
   - aimed volleys
   - spreads/fans
   - radial bursts
   - slow space-denial projectiles
   - lines / telegraphed lanes
   - boss patterns and combinations
4. Boss balance and phases
   - bosses must survive long enough for their mechanics to matter
   - prefer phases, damage reduction, attack patterns, adds and pressure over pure HP sponges
   - miniboss target encounter length is roughly tens of seconds, not 2-5 seconds
5. Post-wave reward flow + rare item chests
   - do not pause active combat when XP crosses a level threshold
   - accumulate pending level-ups during the wave
   - chest drops may appear/be collected during combat, but collecting a chest must not open a modal
   - when the timer ends, first run the existing loot-collection phase and collect all remaining XP, coins and chest drops
   - only after collection is complete, resolve pending level-up choices and chest KEEP / SCRAP choices
   - then open the shop / next intermission step
   - luck may raise chest chance and/or rarity within bounded limits
   - consider at most one ordinary random chest per wave to avoid runaway luck snowballing
   - elite/boss rewards may use stronger or guaranteed chest rules later
6. Expand item pool from 18 toward about 30-35 meaningful items
   - every new item should ideally connect to at least two weapons/items/stats
   - favor interaction, trade-offs and build identity over flat `+damage` filler
7. Elites / stronger enemy roles
8. Boss relics / divine blessings after milestone bosses
9. Weapon evolutions based on tier-IV weapon + compatible build pieces
10. Risk/reward wave choices
11. Meta unlocks, difficulty tiers and additional arenas

The detailed rationale and ideas live in `docs/ROADMAP.md`.

## Core gameplay loop

The intended flow should preserve uninterrupted combat during each wave:

1. Control Denti inside the arena.
2. Enemies spawn during a timed wave.
3. Enemies chase, shoot at or otherwise pressure Denti.
4. Weapons attack automatically.
5. Defeated enemies drop XP, coins and potentially rare chest drops.
6. XP can cross one or more level thresholds during combat, but this only increments a pending level-up count; combat continues.
7. When the wave timer ends, stop new combat and collect all remaining loot first.
8. After the loot sweep is complete, resolve the post-wave reward queue:
   - pending level-ups: choose one of three stat upgrades for each earned level
   - pending chests: reveal item and choose KEEP or SCRAP FOR COINS
   - later: boss relics / other milestone rewards can join the same queue
9. Open the shop. Coins fund weapon/item purchases and rerolls.
10. Weapons can fuse into higher tiers.
11. Start the next, harder wave.

The exact visual presentation of the post-wave queue may evolve, but the key rule is: **do not interrupt active combat with level-up or chest-choice screens**.

The player should make meaningful decisions through:

- movement and positioning during uninterrupted waves
- post-wave level-up choices
- weapon selection and fusion
- shop purchases and rerolls
- item synergies
- chest keep/scrap choices
- later: relics, evolutions and risk/reward wave decisions

## Progression philosophy

XP and money serve different purposes.

### XP

XP primarily improves basic stats:

- Bisskraft: damage
- Härte: armor / damage reduction
- Schmelz: maximum health
- Putzeifer: attack speed
- Glanz: critical chance
- Speichel: regeneration
- Bewegung: movement speed
- Zahnglück / Glück: luck

Crossing an XP threshold during a wave earns a pending level-up instead of pausing the wave. Multiple level-ups can queue and are resolved after the end-of-wave loot collection.

### Coins

Coins are used in the shop and should create stronger build identity than level-ups.

Items should create trade-offs and synergies rather than only flat increases.

### Future progression layers

Keep these conceptually distinct:

- stats = frequent incremental power, chosen in the post-wave reward phase
- shop items/weapons = build construction
- chests = opportunistic reward earned during combat but resolved after the wave via keep/scrap choice
- boss relics = rare rule-changing run modifiers, preferably resolved in the same post-wave reward pipeline
- weapon evolutions = explicit build goals / payoff
- meta progression = mostly unlocks and difficulty options, not mandatory permanent stat inflation

## Build families to deepen

Current and future items should reinforce recognizable families such as:

- Cut / bleed
- Water / electricity / chaining
- Crit / shine / holy effects
- Armor / shields / retaliation
- Economy / luck / loot
- Projectile / pierce / split
- AoE / explosions
- Healing / saliva / overheal
- High-risk sugar / caries items with strong upside and real downside

A funny "bad dental hygiene" build is desirable: forbidden candy, sugar rush, cola-like effects, etc. These should be legitimate risk/reward mechanics rather than joke-only dead items.

## Architecture

Keep gameplay systems modular. Prefer composition over deep inheritance. Avoid large all-purpose scripts.

Separate responsibilities such as:

- movement
- health/stats
- weapons and targeting
- damage
- enemy spawning and projectile patterns
- wave progression and wave events
- XP/loot
- post-wave reward queue / pending level-ups
- shop
- item effects
- chests/rewards
- UI
- telemetry/debug tools

Use signals and clear interfaces where practical. Avoid tightly coupling UI to gameplay logic.

The post-wave flow should have one authoritative state machine / coordinator rather than each reward system pausing the tree independently. Save/resume must preserve pending level-ups, pending chest rewards and the current intermission step.

## Data-driven design

Items, weapons, enemies and upgrades should remain data-driven using Godot Resources where practical, e.g. `ItemData`, `WeaponData`, `EnemyData`, `UpgradeData`.

Do not scatter gameplay values as magic numbers. New systems such as chest tables, projectile patterns, elite modifiers or relics should also be data-driven where doing so keeps iteration simple.

## Stats

Player stats should have one authoritative source. Level-ups, items, buffs and debuffs should modify the same underlying stat model. Recalculate derived stats consistently.

When balancing scaling, watch for accidental multiplicative explosions across weapon tier, crit, boss multipliers, item multipliers and armor-to-damage effects.

## Weapons

Weapons normally attack automatically. Reuse targeting/attack components instead of making every weapon a completely unrelated special case.

Current weapon documentation is in `docs/waffen.md`.

Future weapon evolutions should require a meaningful combination, for example a tier-IV weapon plus one or more compatible items. Do not add evolutions until combat pressure and baseline balance are healthy.

## Enemies and waves

Trash enemies are allowed to die fast. Difficulty should come from a mixture of:

- density
- varied movement speed and durability
- ranged/projectile pressure
- horde bursts
- elites
- telegraphed hazards
- boss phases and adds

Prefer interesting pressure to universal HP inflation.

Waves may contain sub-events, e.g. normal spawn -> small horde -> ranged pressure -> large horde -> elite -> final rush. Keep enough randomness that runs do not feel scripted identically.

## Bosses

Bosses must live long enough for the player to interact with their mechanics. A 2-5 second boss kill is considered a balance failure for the current design direction.

Use telegraphs. Bullet-hell attacks should be readable and dodgeable, not arbitrary unavoidable damage.

Boss phases can add:

- radial projectile bursts
- aimed volleys
- arena lanes / floor warnings
- adds
- charge attacks
- temporary damage reduction or vulnerability windows
- faster/mixed patterns at health thresholds

## Shop and items

The shop already supports rarity progression, rerolls, item stacks, weapon purchases/fusion and selling.

New items should increase synergy density. Before adding a flat-stat item, ask whether it creates a new decision or connects existing mechanics.

The shop should open only after end-of-wave loot collection and all queued mandatory reward choices for that wave have been resolved.

See `docs/items.md` for current effects.

## UI

Keep HUD/cards/buttons coherent with the warm cartoon dental style. Combat readability is more important than decorative complexity, especially as enemy/projectile density rises.

For bullet hell:

- enemy projectiles must remain visually distinct from player projectiles
- telegraphs must be readable under heavy effects
- avoid VFX that obscure hazards
- preserve performance with large enemy counts

Post-wave reward screens should feel like one coherent intermission rather than a chain of unrelated interruptions. Keyboard/controller support can be added later unless a task specifically targets it.

## Denti - canonical character reference

Denti is the mascot: a cute small anthropomorphic white/ivory tooth with a divine/holy visual joke.

Important current design decision: base Denti begins visually unarmed / "naked". The base reference is `assets/denti/reference/denti-initial.png` / `assets/denti/denti_unarmed.png` where appropriate. The upgraded/crowned imagery is useful as upgraded, promotional or equipment-state art, but a golden crown is not required as permanent base equipment.

Preserve Dentis recognizable face, tooth silhouette, proportions and friendly tone. Equipment may be visually added for humor/readability, but gameplay equipment does not need literal representation if it hurts clarity.

Never overwrite original reference images.

## Art direction and humor

Colorful, readable, playful 2D art. Dental terminology and short jokes are encouraged.

Item icon workflow: `assets/items/item_icons_atlas.png`, `assets/items/item_icons_expansion.png` and `assets/items/item_icons_expansion_2.png` are the established painted icon atlases. `scripts/ui/denti_ui_icons.gd` selects their cells, and item resources use `icon_index` unless a dedicated `icon_texture` is set. For future batches of items, generate the new painted icons together as one transparent atlas using the existing atlases as visual references, then extend the atlas/index mapping. Check every cell at shop-card size and preserve the glossy cartoon dental style. The four v0.2 items added after the first 18 currently use individual generated PNGs; keep their approved artwork unless there is a reason to repack it. Do not substitute hand-drawn flat SVGs for this item art.

Humor should stay concise enough not to block gameplay. "Alle huldigen dem Denti" remains a valid achievement/joke direction.

## Testing and implementation style

Use typed GDScript where practical. Prefer small testable systems.

When changing combat scaling, waves, loot, shop, save state, post-wave rewards or item effects, update/add automated tests where reasonable.

Important flow tests should cover:

- XP threshold during active combat does not pause gameplay
- multiple pending level-ups resolve correctly after end-of-wave loot collection
- a chest pickup during combat does not open a modal
- remaining XP/coins/chests are collected before reward choices begin
- reward queue completes before shop opens
- save/resume preserves pending reward state

After the initial Godot import, the existing tests can be run with the command documented in `README.md`.

Do not blindly implement every roadmap idea at once. Preserve a playable build and iterate in small vertical slices: implement -> test -> play -> measure -> rebalance.
