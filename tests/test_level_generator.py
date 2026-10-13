#!/usr/bin/env python3
"""
tests/test_level_generator.py
Automated test suite for tools/level_generator.py
Verifies generated levels across all archetypes, worlds, and difficulties.
"""

import unittest
import os
import shutil
import json
from tools.level_generator import generate_level, export_to_official_pvz2_json, WORLD_ZOMBIE_POOLS


class TestLevelGenerator(unittest.TestCase):

    def setUp(self):
        self.test_dir = "tests/test_output"
        os.makedirs(self.test_dir, exist_ok=True)

    def tearDown(self):
        if os.path.exists(self.test_dir):
            shutil.rmtree(self.test_dir)

    def test_standard_level_generation(self):
        level = generate_level(
            level_id="test_egypt_std",
            name="Test Egypt Standard",
            world="Egypt",
            archetype="Standard",
            difficulty=2,
            wave_count=10,
            seed=42
        )
        self.assertEqual(level["level_id"], "test_egypt_std")
        self.assertEqual(level["world"], "Egypt")
        self.assertEqual(level["archetype"], "Standard")
        self.assertEqual(len(level["waves"]), 10)
        self.assertTrue(level["natural_sun_drop"])

    def test_conveyor_belt_generation(self):
        level = generate_level(
            level_id="test_pirate_conv",
            name="Test Pirate Conveyor",
            world="Pirate",
            archetype="Conveyor Belt",
            difficulty=3,
            wave_count=12,
            seed=100
        )
        self.assertEqual(level["archetype"], "Conveyor Belt")
        self.assertEqual(level["plant_selection"]["mode"], "Conveyor")
        self.assertIn("conveyor_queue", level["plant_selection"])
        self.assertGreater(len(level["plant_selection"]["conveyor_queue"]["cards"]), 0)

    def test_last_stand_generation(self):
        level = generate_level(
            level_id="test_west_ls",
            name="Test West Last Stand",
            world="West",
            archetype="Last Stand",
            difficulty=4,
            wave_count=8,
            seed=200
        )
        self.assertEqual(level["archetype"], "Last Stand")
        self.assertGreaterEqual(level["starting_sun"], 1500)
        self.assertFalse(level["natural_sun_drop"])

    def test_preset_defense_generation(self):
        level = generate_level(
            level_id="test_dark_preset",
            name="Test Dark Preset",
            world="Dark",
            archetype="Preset Defense",
            difficulty=3,
            wave_count=10,
            seed=300
        )
        self.assertEqual(level["archetype"], "Preset Defense")
        self.assertGreater(len(level["lawn_layout"]["initial_plants"]), 0)

    def test_all_worlds_supported(self):
        for world in WORLD_ZOMBIE_POOLS.keys():
            level = generate_level(world=world, seed=123)
            self.assertEqual(level["world"], world)
            self.assertGreater(len(level["waves"]), 0)

    def test_official_conversion(self):
        godot_level = generate_level(level_id="test_conv_off", world="Future", archetype="Standard")
        official_json = export_to_official_pvz2_json(godot_level)
        self.assertIn("objects", official_json)
        self.assertGreater(len(official_json["objects"]), 3)


if __name__ == "__main__":
    unittest.main()
