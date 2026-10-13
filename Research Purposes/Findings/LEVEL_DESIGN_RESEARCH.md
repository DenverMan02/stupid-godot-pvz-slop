# Official Plants vs. Zombies 2 Level Design & Wave Mechanics Research

## Executive Summary

This research document synthesizes empirical design data analyzed from over 2,500 official level files across **PvZ2 Vanilla** and **PvZ2 Chinese (2C)** (`Research Purposes/Official Levels/`).

The objective is to establish the core mathematical principles, wave pacing structures, zombie composition formulas, and world gimmick mechanics that make official PvZ2 levels engaging, dynamic, and balanced.

---

## 1. Level Archetypes & Distribution

Analysis across official levels reveals four primary level archetypes:

1. **Standard Lawn Defense (Chooser / Pick-Your-Seeds)** (~40% of campaign levels)
   - Player picks 6–8 plant cards.
   - Initial sun starts at 50 (or 100).
   - Natural sun drop enabled (DefaultSunDropper).
   - Gradual difficulty ramp up with wave point budgets.

2. **Conveyor Belt Level** (~50% of levels in campaign / event rotation)
   - No seed picking; cards arrive on a moving conveyor.
   - Fixed queue limit (typically 4 to 6 active packets at once).
   - Card weights decay or boost based on current active count on lawn and conveyor queue size.
   - Wave actions (`ModifyConveyorWaveActionProps`) dynamically alter card streams during major flag waves.

3. **Preset Defense / Save Our Seeds / Mold Colony** (~8% of levels)
   - Pre-planted plants on specific grid coordinates (`InitialPlantProperties`).
   - Protected tiles or plants (`ProtectThePlantProperties` / `MoldColonyChallengeProps`).
   - Restricts player placement choices to create puzzle-like tactical constraints.

4. **Last Stand** (~2% of levels)
   - Player is given a fixed large sun pool (e.g. 1500–3000 Sun).
   - Sun production plants (Sun-flower, Twin Sunflower, etc.) are banned.
   - No natural sun drops during battle.
   - Tests static defensive setups against heavy zombie waves.

---

## 2. Wave Pacing & Mathematical Point Budget Formula

PvZ2 levels structure wave intensity using a **Point Budget System** (either explicit or through `WaveManagerProperties`):

### Point Budget Formula

$$\text{Wave Points}(w) = \text{Base Points} + (w - 1) \times \text{Point Increment}$$

- **Base Points (`WaveSpendingPoints`)**: Typically **100 to 200** points for Wave 1.
- **Point Increment (`WaveSpendingPointIncrement`)**: Typically **30 to 150** points per subsequent wave.
- **Flag Wave Multiplier**: Flag waves (every 3, 4, 5, or 10 waves) apply a **1.5× to 2.5× multiplier** to the wave's point budget, spawning large bursts of zombies simultaneously.

### Health-Based Wave Triggers
- **`MinNextWaveHealthPercentage`**: Default **0.55** (55% remaining health of current wave).
- **`MaxNextWaveHealthPercentage`**: Default **0.70** (70% remaining health of current wave).
- When total remaining zombie health drops below this threshold, the next wave triggers automatically, preventing dead downtime and keeping pressure on the player.

---

## 3. Zombie Threat Roles & Point Costs

To create well-balanced waves, zombies are assigned point costs based on their threat tier:

| Threat Tier | Role / Description | Approx Point Cost | Examples |
| :--- | :--- | :--- | :--- |
| **Tier 1: Basic** | Fodder / Meatshield | 10 – 20 pts | Mummy, Cowboy, Jetpack, Basic Zombie |
| **Tier 2: Armor 1** | Light Tank | 30 – 50 pts | Conehead Zombie, Armor1 variants |
| **Tier 3: Armor 2** | Heavy Tank | 90 – 120 pts | Buckethead Zombie, Armor2 variants, Knight |
| **Tier 4: Disruptor** | High Threat / Mechanic | 150 – 250 pts | Wizard, Newspaper, Jester, Octo, Tomb Raiser |
| **Tier 5: Ranged/Summoner** | Backline Pressure | 200 – 350 pts | Zombie Bull + Imp, Chicken Farmer, Zombie Cannon, Weasel Hoarder |
| **Tier 6: Boss/Gargantuar** | Win-Condition Pressure | 500 – 1000 pts | Gargantuar (all world variants) |

### Wave Composition Synergy Rules (What makes a level "GOOD")
1. **The 3-Role Synergy Rule**: Never spawn only tanks or only basics. A standard wave should combine:
   - **Frontline Meatshields** (Tier 1/2) to absorb initial plant shots.
   - **Tanks or Disruptors** (Tier 3/4) in 1 or 2 lanes.
   - **Backline or Ranged Support** (Tier 5) to force player reaction across multiple rows.
2. **Lane Balance**: Avoid stacking 3 high-threat zombies in a single lane unless it is a deliberate "lane rush" event (like a Sandstorm). Distribute threat across all 5 lanes evenly during flag waves.
3. **Escalation Pattern**:
   - **Waves 1–2**: 1–2 Basic Zombies (gives player time to plant sun producers).
   - **Waves 3–4**: First Conehead/Armor1 introduced; introduces 2 active lanes.
   - **Wave 5 (First Flag)**: First wave burst; Buckethead / Armor2 introduced across 3 lanes.
   - **Mid-Game Waves**: Introduces world-specific disruptor (e.g. Swashbuckler, Tomb Raiser, Jetpack).
   - **Final Flag Wave**: Full multi-lane assault with Gargantuans / Special Ambush events.

---

## 4. World Gimmicks & Ambush Events

Official PvZ2 levels rely heavily on world-specific dynamic events that interrupt standard lane behavior:

1. **Sandstorm / Snowstorm / Duststorm (`StormZombieSpawnerProps`)**:
   - Spawns zombies directly into grid columns 3 to 7, bypassing front defenses.
   - Used in Ancient Egypt, Wild West, Lost City.

2. **Raiding Party / Swashbucklers (`RaidingPartyZombieSpawnerProps`)**:
   - Swashbucklers swing on ropes landing in columns 4 to 6.
   - Used in Pirate Seas.

3. **Parachute Rain / Bug Drops (`ParachuteRainZombieSpawnerProps`)**:
   - Drop zombies from above directly onto random tiles.
   - Used in Lost City, Far Future, Modern Day.

4. **Dino Hazards (`DinoWaveActionProps`)**:
   - Dinosaurs appear on specific rows and kick/push zombies forward towards column 1.
   - Used in Jurassic Marsh.

5. **Gravestones / Necromancy (`SpawnGravestonesWaveActionProps` / Necromancy)**:
   - Rises gravestones onto empty grid tiles, blocking straight-shooting projectiles and spawning zombies upon flag waves.

6. **Tide / Water Mechanics (`TideProperties`)**:
   - Rises/lowers water level, forcing low-tide / high-tide plant and zombie mechanics.
   - Used in Big Wave Beach.

---

## 5. Plant Food Distribution Rules

- **Average per level**: 3 to 4 Plant Food drops total.
- **First Plant Food**: Awarded between Wave 1 and Wave 3 (usually on the first Buckethead or high-health zombie) to give players an early panic button.
- **Mid-Level Plant Food**: Awarded right before or during the first Flag Wave.
- **Pre-Final Flag Plant Food**: Awarded 1–2 waves before the final flag assault to prepare player defenses.

---

## 6. Conveyor Queue & Card Pacing Rules

- **Queue Capacity**: Fixed at 4–6 active packets.
- **Card Weights**:
  - Main Offense (Peashooter, Cabbage-pult, Repeater): Weight 100–150.
  - Defense (Wall-nut, Tall-nut): Weight 50–80.
  - Instants/Crowd Control (Cherry Bomb, Potato Mine, Iceberg Lettuce): Weight 20–40.
- **Queue Suppression**: When player holds 4+ cards on conveyor, card drop speed slows down significantly, preventing packet overflow.
