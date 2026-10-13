#!/usr/bin/env python3
"""
tools/level_analyzer.py
Deep analyzer for PvZ2 and PvZ2C levels to uncover:
- Wave Spending Point formulas and scaling
- Flag Wave multipliers
- Zombie Pool roles and cost structures
- Conveyor belt properties (queue capacity, card weights, drop conditions)
- Plant Food drop frequency and rules
- World-specific wave events (Sandstorms, Raiding Parties, Parachute Rains, Dino Events, Necromancy)
"""

import json
import glob
from collections import Counter, defaultdict

def deep_analyze():
    vanilla_files = glob.glob("Research Purposes/Official Levels/Vanilla/**/*.json", recursive=True)
    c2_files = glob.glob("Research Purposes/Official Levels/2c/**/*.json", recursive=True)
    all_files = vanilla_files + c2_files

    wave_spending_base = []
    wave_spending_inc = []
    flag_intervals = Counter()

    conveyor_queues = []
    conveyor_cards = defaultdict(list)

    plantfood_counts_per_level = []
    plantfood_waves = []

    world_zombie_pools = defaultdict(set)
    zombie_row_preferences = defaultdict(Counter)

    wave_actions = Counter()

    for path in all_files:
        try:
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                data = json.load(f)
        except Exception:
            continue

        objects = data.get("objects", [])

        stage = "Unknown"
        level_wave_count = 0
        level_plantfood_total = 0

        for obj in objects:
            objclass = obj.get("objclass", "")
            aliases = obj.get("aliases", [])
            objdata = obj.get("objdata", {})

            if objclass == "LevelDefinition":
                stage_ref = objdata.get("StageModule", "")
                if "@" in stage_ref:
                    stage = stage_ref.split("(")[-1].split("@")[0]

            elif objclass == "WaveManagerProperties":
                base_pts = objdata.get("WaveSpendingPoints")
                inc_pts = objdata.get("WaveSpendingPointIncrement")
                flag_int = objdata.get("FlagWaveInterval")
                if base_pts is not None: wave_spending_base.append(base_pts)
                if inc_pts is not None: wave_spending_inc.append(inc_pts)
                if flag_int: flag_intervals[flag_int] += 1
                level_wave_count = objdata.get("WaveCount", 0)

            elif objclass == "ConveyorSeedBankProperties" or "ConveyorBelt" in aliases:
                max_capacity = objdata.get("MaxActiveSeedPackets")
                if max_capacity: conveyor_queues.append(max_capacity)

                cards = objdata.get("InitialPlantList", []) or objdata.get("PacketList", [])
                for card in cards:
                    plant_type = card.get("PlantType", card.get("TypeName", "unknown"))
                    weight = card.get("Weight", card.get("InitialWeight", 100))
                    conveyor_cards[plant_type].append(weight)

            elif objclass == "SpawnZombiesJitteredWaveActionProps":
                action_name = aliases[0] if aliases else "WaveAction"
                wave_actions[objclass] += 1
                pf = objdata.get("AdditionalPlantfood", 0)
                level_plantfood_total += pf

                for z in objdata.get("Zombies", []):
                    z_type = z.get("Type", "")
                    row = z.get("Row")
                    if z_type:
                        z_short = z_type.split("(")[-1].split("@")[0] if "@" in z_type else z_type
                        world_zombie_pools[stage].add(z_short)
                        if row is not None:
                            zombie_row_preferences[z_short][str(row)] += 1

            elif "ZombieSpawnerProps" in objclass or "WaveActionProps" in objclass:
                wave_actions[objclass] += 1

        if level_wave_count > 0:
            plantfood_counts_per_level.append(level_plantfood_total)

    print("=== DEEP ANALYSIS RESULTS ===")
    if wave_spending_base:
        print(f"Wave Spending Base Points: Avg = {sum(wave_spending_base)/len(wave_spending_base):.1f}, Min = {min(wave_spending_base)}, Max = {max(wave_spending_base)}")
    if wave_spending_inc:
        print(f"Wave Spending Point Increment: Avg = {sum(wave_spending_inc)/len(wave_spending_inc):.1f}, Min = {min(wave_spending_inc)}, Max = {max(wave_spending_inc)}")
    print(f"Flag Wave Intervals Distribution: {flag_intervals.most_common()}")

    if conveyor_queues:
        print(f"Conveyor Max Cards Queue Capacity: Avg = {sum(conveyor_queues)/len(conveyor_queues):.1f}, Common = {Counter(conveyor_queues).most_common(5)}")

    if plantfood_counts_per_level:
        print(f"Plant Food drops per level: Avg = {sum(plantfood_counts_per_level)/len(plantfood_counts_per_level):.2f}, Max = {max(plantfood_counts_per_level)}")

    print("\nTop 15 Wave Action Props:")
    for wa, count in wave_actions.most_common(15):
        print(f"  {wa}: {count}")

    print("\nSample World Zombie Pools:")
    for st, pool in list(world_zombie_pools.items())[:5]:
        print(f"  {st}: {len(pool)} zombie types -> {list(pool)[:6]}...")

if __name__ == "__main__":
    deep_analyze()
