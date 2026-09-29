# Brotato Balancing Research

Research notes for Denti's wave, enemy and economy balancing. The goal is **not** to clone Brotato numerically, but to understand why its difficulty curve keeps working while the player becomes much stronger.

Research checked against the Brotato Wiki on 2026-09-29.

## Executive summary

Brotato does not rely on one global exponential `enemy_hp *= X` curve. Its difficulty comes from several systems working together:

1. Individual enemies have their own linear health and damage growth per wave.
2. Enemy speed normally does not scale with the wave in the standard 20-wave run.
3. New enemy roles appear as the run progresses and on higher Danger levels.
4. Waves use authored enemy compositions rather than only multiplying the previous wave.
5. Horde and Elite waves create deliberate pressure spikes.
6. More enemies do not produce proportionally more economy because material drop chance decays over time and is reduced further during hordes.
7. Shop prices inflate with wave number.
8. XP requirements grow quadratically, so additional late-game XP has diminishing returns in terms of levels gained.
9. Elites and bosses use much steeper health scaling and mechanics/phases rather than behaving like ordinary enemies with a larger sprite.

This matches Denti's intended direction: **power fantasy under pressure, not HP sponges**.

---

## 1. Per-enemy linear stat scaling

Regular Brotato enemies define their own base stats and per-wave additions.

Conceptually:

```text
health(wave) = base_health + hp_per_wave * (wave - 1)
damage(wave) = base_damage + damage_per_wave * (wave - 1)
```

The important part is that `hp_per_wave` and `damage_per_wave` are properties of the enemy archetype, not a single universal growth factor.

Examples from the Crash Zone enemy table:

- weak enemies can have small health growth and remain disposable targets late in the run;
- tougher enemies can have much larger `hp_per_wave` values;
- Pursuer is given as an explicit example: `10 base HP + 24 HP/wave`, so on wave 11 it has `10 + 10 * 24 = 250 HP` before difficulty modifiers.

Normal enemy speed does **not** increase with wave or Danger level in the standard run. Endless mode adds separate speed scaling later.

### Denti implication

Avoid making every enemy use the same health multiplier.

Prefer data such as:

```text
Plaque
  low base HP
  low HP/wave
  remains fodder

Acid Spitter
  low/medium HP growth
  threat comes from projectiles and positioning

Tank / Tartar archetype
  high HP/wave
  survives long enough to disrupt movement

Elite
  own scaling curve
  mechanics matter more than raw HP
```

The player should still be able to erase basic enemies late in a run. Difficulty should come from the composition around them.

Source: https://brotato.wiki.spellsandguns.com/Enemies

---

## 2. Difficulty grows through enemy roles, not only stats

Brotato introduces different enemy types at different points in the run. Higher Danger levels also unlock additional enemies or cause dangerous enemies to appear earlier.

This means two waves with identical raw HP multipliers can still differ strongly in difficulty because their enemy roles differ:

- chasers create movement pressure;
- ranged enemies deny space;
- chargers punish predictable movement;
- buffers make other enemies more dangerous;
- tanks occupy space and absorb attention;
- elites introduce bespoke mechanics.

### Denti implication

Wave progression should be partly a **role progression**:

```text
Early
  mostly readable melee fodder

Mid
  fodder + ranged pressure + fast/charge enemies

Late
  dense fodder + ranged enemies + tanks + buffers/elites
```

Do not solve late-game difficulty by turning Plaque into a 500 HP blob.

Sources:

- https://brotato.wiki.spellsandguns.com/Enemies
- https://brotato.wiki.spellsandguns.com/Dangers

---

## 3. Standard wave duration ramps early, then stabilizes

Brotato's standard run contains 20 waves.

Wave duration progresses roughly as follows:

```text
Wave 1   20 s
Wave 2   25 s
Wave 3   30 s
Wave 4   35 s
Wave 5   40 s
Wave 6   45 s
Wave 7   50 s
Wave 8   55 s
Wave 9   60 s
Wave 10-19 60 s
Wave 20  90 s
```

This gives early builds frequent reward/shop cycles while later builds must survive longer periods of sustained pressure.

### Denti implication

Denti does not need to copy these times, but a similar structure may improve pacing. Example experiment:

```text
Waves 1-4    30-35 s
Waves 5-9    40 s
Waves 10-14  45 s
Waves 15-19  50 s
Wave 20      60-75 s boss encounter
```

This should be tested against post-wave reward frequency before adopting it.

Source: https://brotato.wiki.spellsandguns.com/Enemies

---

## 4. Pressure spikes: Horde and Elite waves

Brotato deliberately inserts exceptional waves rather than making every wave uniformly harder.

Danger levels add these systems progressively:

- Danger 2: Elite/Horde waves begin to appear.
- Danger 4/5: more Elite/Horde waves appear between waves 11 and 18.
- Danger 5: two bosses spawn on wave 20 instead of one; each boss receives a health reduction before the Danger modifier is applied.

Horde waves add many additional enemies. Elite waves add an elite with its own attacks and movement pattern in addition to the normal wave.

This creates a difficulty curve with peaks and recovery periods rather than a perfectly smooth line.

### Denti implication

A possible authored structure:

```text
1-4    build-up
5      Karies-Graf
6-8    build-up with new role mix
9      Horde
10     Karies-Prinz
11-13  denser mixed waves
14     Elite/Horde pressure spike
15     Karies-König
16     high pressure
17     Horde
18     Elite
19     maximum pre-boss density
20     Karies-Imperator
```

Exact positions should be telemetry-driven rather than fixed purely because Brotato does it.

Sources:

- https://brotato.wiki.spellsandguns.com/Dangers
- https://brotato.wiki.spellsandguns.com/Horde_Wave

---

## 5. Danger multiplies HP and damage, but does not replace wave design

Current Brotato Danger modifiers include:

```text
Danger 0-2  no global HP/damage multiplier
Danger 3    +12% enemy HP and damage
Danger 4    +26% enemy HP and damage
Danger 5    +40% enemy HP and damage
```

These are total multipliers for the selected Danger level, not additive stacks of all earlier percentages.

The key lesson is that higher difficulty also changes enemy availability, Elite/Horde frequency, and the final boss setup. It is not simply `all stats * 1.4`.

Normal speed is unchanged by these Danger levels. The newer Nightmare difficulty is a separate case and includes a speed increase.

### Denti implication

Future Denti difficulty tiers should combine modest numerical modifiers with structural changes:

```text
Difficulty increase
= modest HP/damage modifier
+ earlier dangerous enemy roles
+ more pressure waves
+ additional projectiles/mechanics
+ altered boss patterns
```

Avoid multiplying HP, damage, speed and enemy count by the same large factor at once.

Source: https://brotato.wiki.spellsandguns.com/Dangers

---

## 6. More enemies are prevented from becoming runaway economy

This is one of the most useful systems for Denti.

Brotato's enemy material drop chance starts at 100%, then begins decaying from wave 5:

```text
Wave 1-4   100%
Wave 5      92.5%
Wave 10     85%
Wave 15     77.5%
Wave 20     70%
```

The rule is effectively a reduction of `1.5% * wave_number` starting at wave 5, with a lower cap later in Endless mode.

Horde waves multiply the resulting drop rate by `0.65`, i.e. enemies have 35% less material drop chance during hordes.

Therefore Brotato can put substantially more enemies on screen without making player income rise in direct proportion to spawn count.

There is also a maximum of 100 enemies on screen; when exceeded, a random non-Elite/non-Boss enemy is removed without loot.

### Why this matters

Without economy damping:

```text
more enemies
-> more coins / XP
-> stronger build
-> faster kills
-> still more income
-> runaway positive feedback
```

### Denti implication

If Denti increases enemy density substantially, coin/XP output must be reviewed at the same time.

A first test model could be:

```text
coin drop multiplier
waves 1-5    1.00
waves 6-10   0.90
waves 11-15  0.80
waves 16-20  0.70

Horde wave
  additional *0.70-ish economy factor
```

This is only a starting hypothesis. Denti separates XP and coins more clearly than Brotato, so they can use different curves. XP may need weaker damping so leveling remains satisfying.

Source: https://brotato.wiki.spellsandguns.com/Materials

---

## 7. Shop inflation counters growing income

Brotato applies wave-based inflation to shop prices.

The documented formula is:

```text
final_price =
    (base_price + wave + base_price * 0.1 * wave)
    * shop_price_modifier
```

For an item with base price 20 and no other modifier:

```text
Wave 1   23
Wave 5   35
Wave 10  50
Wave 20  80
```

This means late-run income has a natural counterweight: even if the player earns more materials, purchases become more expensive.

### Denti implication

Do not balance enemy coin output independently from shop prices.

When density rises, validate all of these together:

- coins earned per wave;
- reroll cost;
- average item price;
- number of purchases per shop;
- average weapon tier by wave;
- scrap/chest income.

Source: https://brotato.wiki.spellsandguns.com/Shop

---

## 8. XP progression has diminishing returns

Brotato's XP requirement for the next level is:

```text
XP required = (level + 3)^2
```

Examples:

```text
level 0 -> 1     16 XP
level 1 -> 2     25 XP
level 9 -> 10   169 XP
level 19 -> 20  529 XP
```

Because XP cost grows quadratically, a late increase in XP income does not translate into a proportional increase in levels.

### Denti implication

When enemy density rises, Denti should not necessarily reduce XP drops as aggressively as coins if its level curve already creates enough diminishing returns.

Telemetry should answer this rather than guessing:

```text
level reached per wave
XP earned per wave
unresolved level-ups after wave
average number of upgrades before each boss
```

Source: https://brotato.wiki.spellsandguns.com/Experience

---

## 9. Elites and bosses use separate scaling and mechanics

Brotato elites have extremely large per-wave health additions compared with ordinary fodder. Their threat also comes from mutations/phases and unique attack patterns.

The standard wave-20 bosses have around 29k base encounter health in the current data and multiple behavior phases. On Danger 5 two bosses appear; each receives a 25% health reduction, then the Danger 5 health modifier applies.

Historical Brotato balance patches also show that boss scaling was explicitly tuned separately from regular enemies (for example changing boss health from a low base/highly different per-wave formula to another dedicated boss formula).

### Denti implication

The four cavity bosses should be balanced as four encounters, not as one generic boss multiplied by wave number:

```text
Wave 5   Karies-Graf
  introductory boss
  readable charge / pulse / small fan

Wave 10  Karies-Prinz
  stronger area denial
  wider projectile patterns

Wave 15  Karies-König
  multi-directional pressure
  more distinct phase behavior

Wave 20  Karies-Imperator
  final encounter
  combines mechanics with safe gaps and phases
```

Boss TTK is a much better tuning target than raw HP alone.

Sources:

- https://brotato.wiki.spellsandguns.com/Enemies
- https://brotato.wiki.spellsandguns.com/Patch_1.0.0.3

---

## 10. Proposed Denti model

A Brotato-inspired Denti model should separate **stat scaling** from **pressure scaling**.

### A. Enemy data

Move toward per-archetype values such as:

```text
base_health
health_per_wave
base_damage
damage_per_wave
first_wave
role
```

Optional later fields:

```text
weight_by_wave
max_simultaneous
pressure_cost
```

Avoid one universal exponential health formula.

### B. Authored wave profiles

Each wave or wave band should define a composition budget rather than simply increasing every previous spawn by a percentage.

Possible conceptual model:

```text
WaveProfile
  duration
  spawn_budget
  burst_count
  allowed_enemy_roles
  role_weights
  horde / elite / boss flags
```

The same enemy data can then be reused in deliberately different compositions.

### C. Preserve fodder

Late-game Plaque should still die quickly.

The challenge should instead be that the player must process:

```text
many Plaque
+ Acid Spitter projectiles
+ a charging enemy
+ a durable blocker
+ occasional elite mechanics
```

A strong Denti build should feel spectacular because it destroys many enemies, not weak because every enemy takes ten hits.

### D. Scale density more aggressively than HP

Given current Denti playtests, the highest-value experiment is likely:

1. reduce universal HP inflation;
2. increase spawn density and burst frequency;
3. preserve dangerous ranged/projectile pressure;
4. add enemy-role combinations;
5. damp economy enough to avoid runaway growth.

### E. Use telemetry to tune

Use the existing run telemetry to track at least:

```text
rolling DPS
peak DPS
kills/sec
current and peak enemy count
enemies spawned
damage taken
boss TTK
coins earned/spent
XP earned
level by wave
damage per source
```

Useful balance questions:

- Are normal enemies alive long enough to create pressure?
- Are fodder enemies still satisfying to delete?
- Does enemy count rise without FPS or readability collapsing?
- Are ranged enemies forcing movement?
- Is coin income increasing faster than shop inflation?
- At which wave can a strong build stop moving entirely?
- How long does each boss survive against weak/median/strong runs?

---

## Recommended next implementation slice

The research suggests this order for Denti:

1. Add `health_per_wave` and `damage_per_wave` to enemy data (or an equivalent per-enemy curve).
2. Remove/reduce universal enemy HP scaling once the per-enemy curves exist.
3. Introduce explicit wave composition/profile data.
4. Increase late-wave density and authored bursts/hordes.
5. Tune coin and XP output alongside the spawn increase.
6. Give bosses explicit encounter-level tuning and TTK targets.
7. Add further enemy roles and projectile patterns after the foundation is measurable.

The intended end state remains:

> **Denti becomes absurdly powerful, while the arena remains dangerous.**

The screen should become harder because the player has more threats to read and more decisions to make — not because every Plaque suddenly becomes a damage sponge.

---

## Sources

Primary reference pages used for these notes:

- Brotato Wiki — Enemies: https://brotato.wiki.spellsandguns.com/Enemies
- Brotato Wiki — Danger Levels: https://brotato.wiki.spellsandguns.com/Dangers
- Brotato Wiki — Elite and Horde Waves: https://brotato.wiki.spellsandguns.com/Horde_Wave
- Brotato Wiki — Materials: https://brotato.wiki.spellsandguns.com/Materials
- Brotato Wiki — Shop: https://brotato.wiki.spellsandguns.com/Shop
- Brotato Wiki — Experience: https://brotato.wiki.spellsandguns.com/Experience
- Brotato Wiki — Patch 1.0.0.3: https://brotato.wiki.spellsandguns.com/Patch_1.0.0.3

These are design-research references, not dependencies. Numerical values may change in future Brotato patches and should not be treated as Denti requirements.