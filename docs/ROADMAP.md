# Denti v0.2 Roadmap — Pressure + Build Depth

This roadmap captures the current player feedback and the intended next development loop for Denti: Divine Dentistry.

## Current progress

- Per-wave telemetry and completed-run JSON reports are available for balance review.
- Timed bursts, denser late waves and wider ranged volleys add pressure without universal health inflation.
- Bosses have damage pacing, telegraphed projectile phases and reinforcements. Playtesting reports that their mechanics are now more noticeable.
- Sugar enemies gain a telegraphed long charge with a marked landing area from wave 7, addressing their inability to reach a strong build.
- Post-wave rewards now queue all level-ups and rare chest choices after the loot sweep. Chest items are rolled when dropped, luck is bounded, and the queue survives save/resume.
- The item pool has grown from 18 to 22 with bleed spread, wet conductivity, movement-based sugar damage and chest scrap economy. The new effects and enemy status survive save/resume.
- Player feedback to revisit after the roadmap slice: by wave 12 a strong build can stand still without enemies reaching Denti. More mobile enemy roles and new attacks remain needed.
- Next: keep expanding the item pool toward 30-35 meaningful choices, then revisit late-wave pressure with the per-wave reports.

## Why v0.2 exists

The prototype loop works, but current playtesting shows a clear balance problem:

- Denti outpaces enemy scaling too easily.
- Late-run normal enemies frequently become universal one-shots.
- Bosses can die in roughly 2-5 seconds.
- Once the build comes online, movement and positioning become too unimportant.
- Waves need more bodies, more bursts/hordes and more projectile pressure.
- Mid-wave modal interruptions should be reduced: level-ups and chest choices belong in the intermission after combat.

The goal is not to make Denti feel weak. The goal is to let the player become absurdly powerful while the arena remains dangerous enough that they still have to move, read attacks and make build decisions.

Think: **power fantasy under pressure**, not HP-sponges.

A wave should feel like one uninterrupted combat segment. The reward-processing rhythm should happen afterwards:

```text
WAVE COMBAT
-> timer ends
-> collect all remaining XP / coins / chest drops
-> resolve earned level-ups
-> resolve chest loot (KEEP / SCRAP)
-> later: resolve boss relic / special reward if applicable
-> shop
-> next wave
```

This post-wave reward pipeline is a core design decision for v0.2.

---

## Phase 1 — Measure before balancing

Add a developer-only combat telemetry overlay / instrumentation.

Useful metrics:

- rolling DPS over the last 5-10 seconds
- peak DPS
- kills per second
- enemies currently alive
- enemies spawned per wave / per minute
- damage taken per minute
- coins and XP gained per wave
- boss time-to-kill
- optional: average hit damage / crit rate / active projectile count

Purpose:

- identify where scaling explodes
- compare builds objectively
- balance bosses against real player output
- catch performance problems when increasing enemy density

Do not expose all of this in normal gameplay.

### Telemetry must also power the end-of-run recap

Do not build combat telemetry as a disposable debug-only system. The same underlying run statistics should later feed a player-facing **"So war dein Run"** summary after victory or death.

Damage events should carry enough attribution to distinguish at least:

- direct weapon damage, identified by weapon type / stable weapon id
- item/proc damage, e.g. bleed, chain lightning, holy flash, retaliation
- other damage sources if they become relevant later

A water-flosser hit that triggers chain lightning should count the direct hit toward the weapon and the chained damage toward the proc. Avoid double-counting proc damage as weapon damage unless a design decision explicitly says otherwise.

Accumulate total damage per source over the full run. The first player-facing recap should be able to show something like:

- wave reached / run completed
- total play time
- final level
- enemies killed
- total damage dealt
- damage taken
- coins collected
- XP collected
- bosses defeated
- chests found
- chest items kept vs. scrapped
- accumulated damage per weapon
- percentage of total weapon damage per weapon
- optional separate synergy/proc damage section
- strongest weapon of the run

Example weapon breakdown:

```text
Zahnseidenpeitsche IV   162,884   38%
Wasserflosser III       101,337   24%
Turbo-Bohrer II          72,441   17%
```

Example proc breakdown:

```text
Blutung                  58,220
Kettenblitz              41,992
Zahnblitz                18,770
```

The debug overlay and the run recap are different presentations of the same measurement layer:

- debug view = rolling/technical numbers for balancing
- run recap = accumulated, understandable numbers for the player

Run statistics should survive save/resume so quitting to the menu and continuing does not reset the eventual recap. Keep the measurement API centralized enough that future achievements can consume the same data without every weapon/item inventing its own counters.

Do not turn the recap into an unreadable spreadsheet. Prefer a concise summary plus the weapon damage breakdown, with deeper proc details only where they remain useful and fun to inspect.

---

## Phase 2 — Increase enemy pressure

### More enemies

Later waves should contain substantially more enemies. Trash mobs may still die instantly if the build is strong; the pressure should come from volume and mixed threats.

Avoid only increasing HP.

### More frequent hordes

Hordes should become a normal part of wave rhythm instead of a rare surprise.

Possible 45-second wave structure:

- 0s: baseline spawns
- 8s: small horde
- 17s: ranged pressure added
- 24s: large horde
- 32s: elite or heavy group
- 39s: final rush
- 45s: wave ends

This should not be identical every wave. Use randomized event slots / wave profiles.

### Wave profiles

Potential wave archetypes:

- Swarm: huge amount of weak enemies
- Fortress: fewer tanks + ranged support
- Crossfire: more projectile enemies
- Rush: fast enemies in bursts
- Elite hunt: fewer enemies but multiple elites
- Sugar flood: single-type thematic horde
- Mixed panic: everything in the final 10 seconds

---

## Phase 3 — Bullet-hell foundation

Build reusable projectile-pattern components so bosses and ranged enemies can share them.

Patterns worth supporting:

- aimed single shot
- aimed 3/5-shot volley
- fan/spread
- radial burst
- rotating radial / spiral
- slow large space-denial orb
- telegraphed line / lane shot
- delayed floor marker -> projectile / explosion
- ring with safe gaps

Design rules:

- hazards must be readable before they become dangerous
- enemy bullets must be visually distinct from Denti's bullets
- patterns should combine in interesting ways rather than becoming pure screen noise
- heavy VFX must not hide danger zones
- maintain performance under high density

---

## Phase 4 — Bosses that actually get to fight

Current boss time-to-kill can be only a few seconds. That prevents the mechanics from mattering.

Desired direction:

- minibosses should usually survive for a meaningful chunk of the wave, roughly tens of seconds
- final boss should sustain a real encounter, potentially 45-90+ seconds depending on build strength and tuning

These are tuning targets, not rigid guarantees.

Use more than HP:

- attack phases at health thresholds
- charge + telegraph
- radial projectile bursts
- aimed bullet patterns
- adds
- temporary armor / vulnerability windows
- movement changes
- arena hazards
- phase transitions

A strong build should kill bosses noticeably faster than a weak build, but not delete them before they can execute their kit.

---

## Phase 5 — Post-wave rewards and Zahnfee chests

The important design change: **do not interrupt active combat with level-up or chest-choice screens.**

The current wave should be allowed to build pressure continuously. Level-ups and chest rewards are earned during combat but resolved only after the wave ends.

### Post-wave reward pipeline

When the wave timer reaches zero:

1. stop spawning / finish the combat segment
2. run the existing loot-collection phase
3. pull all remaining XP, coins and chest drops to Denti
4. update XP and determine how many level-ups were earned
5. resolve all pending level-up choices
6. resolve all pending Zahnfee chest rewards
7. later, insert milestone rewards such as boss relics into this same intermission pipeline
8. open the shop
9. continue to the next wave

The flow should feel like a deliberate **"time to loot and level up"** break after the action, not a chain of interruptions during it.

### Deferred level-ups

Crossing an XP threshold during active combat must no longer pause the game.

Instead:

- XP keeps accumulating normally
- each crossed threshold increments a pending level-up count
- multiple levels may be earned in one wave
- after the end-of-wave loot sweep, present one three-choice level-up selection per pending level
- preserve overflow XP and threshold progression correctly

This is especially important once waves become denser and more bullet-hell-like. A modal popping up in the middle of a dodge sequence would destroy combat rhythm.

### Chest drops during combat

A Zahnfee chest may still physically drop during the wave. It can be exciting to see and collect, but **picking it up must not open a choice screen immediately**.

Preferred behavior:

- chest appears as a visible rare drop
- touching/collecting it queues a pending chest reward
- if it remains on the ground when the wave ends, the end-of-wave loot sweep collects it automatically like XP/coins
- the item reveal happens only in the post-wave reward phase

To avoid ordering exploits, the chest reward/rarity should preferably be rolled using the relevant luck state when the chest is generated/collected, or otherwise use a clearly defined luck snapshot. Do not let the player change luck during post-wave level-ups and thereby reroll already-earned chest quality accidentally.

### Core chest interaction

When a queued chest is resolved, reveal one item:

- **KEEP**: gain the item for free
- **SCRAP**: convert the item into coins

This ensures even a poor build-match is still useful.

If multiple chests are ever possible, resolve them sequentially or through one compact reward screen. Do not create a separate combat interruption per chest.

### Luck interaction

Luck may influence:

- chance for a random chest to drop during the wave
- item rarity inside the chest

Keep this bounded to avoid runaway snowballing. A good starting rule is at most one ordinary random chest per wave.

Possible later rules:

- elites have a meaningful chest chance
- milestone bosses guarantee a reward chest or stronger reward
- scrap value scales with rarity
- dedicated item can improve scrap value

### Architecture / save-state requirement

Treat this as a generic **post-wave reward queue**, not as several unrelated systems each calling `get_tree().paused`.

The game should know which intermission state it is in, for example conceptually:

```text
COLLECTING_LOOT
-> LEVEL_UP_REWARDS
-> CHEST_REWARDS
-> BOSS_REWARD (optional/later)
-> SHOP
```

Save/resume should preserve:

- pending level-up count / unresolved choices
- pending chest rewards
- which reward is currently being resolved
- completion state before the shop

This makes later boss relics and special rewards much easier to add without turning the game flow into nested pause logic.

### Why this helps

- combat remains uninterrupted and can become much denser
- the end of a wave gets a satisfying payoff rhythm
- all XP and coins are known before making post-wave decisions
- chest loot and level-ups feel like rewards for surviving the wave
- the shop stays the final build-planning step before the next fight

---

## Phase 6 — Expand from 18 to about 30-35 items

Do not add filler just to hit a number.

Each new item should preferably connect to at least two existing mechanics.

### Cut / Bleed

Ideas:

- extra bleed stack capacity
- bleed can crit
- killing a bleeding enemy spreads one bleed stack
- bonus movement/attack speed while near bleeding enemies
- stronger payoff after maintaining bleed for a duration

### Water / Electricity

Ideas:

- wet status increases chain range
- water impacts create temporary puddles
- electricity arcs through wet enemies / puddles
- chain damage grows with number of wet targets

### Crit / Shine / Holy

Ideas:

- crits emit a light beam
- holy damage temporarily raises crit chance
- excess crit chance above 100% converts into bonus crit damage or secondary proc chance
- consecutive crits build a short "glow" buff

### Armor / Shield / Retaliation

Ideas:

- shield break causes AoE
- taking damage fires enamel shards
- armor contributes to attack scaling with a cap
- gaining a shield temporarily raises damage

### Economy / Luck

Ideas:

- coins collected during a wave grant temporary power
- unspent coins earn a small end-wave bonus
- better scrap value
- chest rarity bias
- kill streaks have a low chance to mint extra coins

### Projectile

Ideas:

- more pierce
- split on kill
- larger/slower projectiles with more damage
- projectile return / boomerang-like secondary pass

### AoE / Explosions

Ideas:

- larger blast radius with reduced direct damage
- kills by AoE prime nearby enemies
- chained explosions with cooldown safeguards

### Healing / Saliva

Ideas:

- overheal becomes shield
- full HP grants damage
- regeneration accelerates after avoiding damage for several seconds
- healing events trigger a small holy pulse

### Sugar / Caries risk-reward build

A deliberately unhealthy build family is strongly desired.

Examples:

**Verbotener Lolli**
- large damage increase
- meaningful defensive drawback
- optionally accumulates "Karies" per wave

**Zuckerschock**
- large attack-speed boost
- later movement or defense crash

**Cola-Infusion**
- strong bonus at full health
- heavily reduced regeneration

These should be powerful enough to tempt the player, not joke-only traps.

---

## Phase 7 — Elites

Introduce elite variants to create priority targets without needing many completely new enemy species.

Possible elite modifiers:

- larger + tougher
- aura that buffs nearby enemies
- periodic radial shots
- leaves acid trail
- splits on death
- shielded until nearby minions die
- enrages when low HP

Elites are good candidates for better chest-drop chances.

---

## Phase 8 — Boss relics / Divine Blessings

After milestone bosses (for example waves 5, 10 and 15), offer one of three rare rule-changing relics.

These are not normal shop items. Resolve them inside the post-wave reward pipeline, after loot collection and before the shop.

Examples:

- bleeding enemies explode on death and spread bleed
- every fifth water hit emits a circular wave
- shield break grants a temporary major damage buff
- crits leave holy marks that detonate after several hits

Purpose: create a third in-run progression layer:

- XP = stats
- coins = shop build
- boss relics = rule changes

Keep the relic pool small and distinctive before expanding it.

---

## Phase 9 — Weapon evolutions

Only after core balance and pressure are healthy.

Evolution concept:

Tier-IV weapon + compatible item(s) -> special evolved weapon.

Examples / placeholders:

- Zahnseidenpeitsche IV + Zahnseide-Spule + Skalpellwachs -> holy bleed evolution
- Wasserflosser IV + Funkensonde + Mundspülung -> electric water evolution
- Turbo-Bohrer IV + Implantat -> boss-killing drill evolution

The important part is not the exact names. Evolutions should give the player explicit mid-run goals and make shop rerolls emotionally meaningful.

---

## Phase 10 — Risk/reward waves

Before selected waves, present optional difficulty modifiers.

Example:

- Normal treatment
- Emergency treatment: +35% enemies, one elite, +50% coins

Possible modifiers:

- double horde
- extra projectile enemies
- no healing this wave
- stronger enemies for increased chest chance
- elite guaranteed

These choices let players voluntarily test whether their build is ahead of the curve.

---

## Phase 11 — Replayability / meta layer

After the in-run loop is strong:

### Unlock-focused meta progression

Prefer unlocking:

- new items
- new weapons
- relics
- challenge modifiers
- arenas
- alternate starting loadouts

Avoid relying primarily on permanent +damage/+HP upgrades, because they can undermine the balance work.

### Difficulty tiers / Kariesgrad

After the first victory, unlock escalating difficulty tiers.

Potential effects:

- denser waves
- additional elite modifiers
- harder boss patterns
- reduced healing
- new enemy combinations
- additional reward/unlock opportunities

### Arena chapters

The existing 5-wave boss cadence naturally supports four chapters:

- waves 1-5: Plaque
- 6-10: Sugar
- 11-15: Acid
- 16-20: Caries

Visual tint, spawn profile, hazards and music can change without requiring four entirely new maps.

---

## Balancing principles

1. Do not make every enemy a sponge.
2. Let trash mobs explode under a strong build.
3. Preserve danger through quantity, mixed roles, projectiles and elites.
4. Bosses must live long enough to show their mechanics.
5. Strong builds should feel visibly stronger than weak ones.
6. Avoid uncapped multiplicative scaling where possible.
7. Test interactions between weapon tiers, crit, boss multipliers, armor-to-damage and item procs.
8. Use cooldowns/limits to prevent proc chains from creating infinite or unreadable cascades.
9. Measure before and after tuning.
10. Keep the game readable at maximum intended enemy/projectile density.
11. Do not use modal reward screens to relieve combat pressure; let the wave breathe only after it actually ends.

## Definition of a healthier run

A successful v0.2 run should feel approximately like this:

- early: Denti is vulnerable and building identity
- mid: synergies begin to come online; hordes become satisfying but dangerous
- late: Denti destroys huge amounts of trash, but must still dodge patterns and respect elites
- each active wave: uninterrupted movement/combat with no level-up or chest modal stopping a dodge sequence
- wave end: everything flies in, then there is a satisfying loot/level-up/chest reward break
- bosses: strong builds shorten the fight, but do not erase the encounter in a few seconds
- shops/chests/relics create recognizable build goals and difficult decisions
- replaying immediately suggests another build to try

The desired fantasy is:

> Denti becomes outrageously powerful. The arena becomes outrageously hostile too.
