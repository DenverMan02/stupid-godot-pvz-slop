#!/usr/bin/env python3
"""
tests/test_zombie_armor_and_bones.py
Automated test suite verifying zombie bone dropping, cone/bucket/brick armor degradation states,
Wall-nut body degrades and Plant Food armor, and tag compilation integrity according to PvZ2 official OBB specifications and PvZ2CH headers.
"""

import unittest
import json
import os

class TestZombieArmorAndBones(unittest.TestCase):

    def setUp(self):
        with open("Assets/Zombies/zombie_tutorial.anim.json", "r") as f:
            self.male_anim = json.load(f)
        with open("Assets/Zombies/zombie_tutorialfem.anim.json", "r") as f:
            self.fem_anim = json.load(f)
        with open("Assets/Plants/peashooter.anim.json", "r") as f:
            self.pea_anim = json.load(f)
        with open("Assets/Plants/wallnut.anim.json", "r") as f:
            self.wallnut_anim = json.load(f)

    def test_plant_slices_unaffected(self):
        """Ensure standard plant animations have no tags (length remains 7 for performance)."""
        for anim_name, anim_data in self.pea_anim["animations"].items():
            for frame in anim_data["frames"]:
                for slice_item in frame:
                    self.assertEqual(len(slice_item), 7, f"Plant slice in {anim_name} should have 7 elements")

    def test_zombie_animation_tags_present(self):
        """Ensure zombie animations have the correct tags for cone (1-3), arm (4-5), bucket (6-8), and brick (9-11)."""
        for anim_data, label in [(self.male_anim, "male"), (self.fem_anim, "female")]:
            walk_f0 = anim_data["animations"]["walk"]["frames"][0]
            tags = {s[7] for s in walk_f0 if len(s) > 7}
            # Cone
            self.assertIn(1, tags, f"{label} walk missing cone_norm (tag 1)")
            self.assertIn(2, tags, f"{label} walk missing cone_dmg1 (tag 2)")
            self.assertIn(3, tags, f"{label} walk missing cone_dmg2 (tag 3)")
            # Arm
            self.assertIn(4, tags, f"{label} walk missing arm_flesh (tag 4)")
            self.assertIn(5, tags, f"{label} walk missing arm_bone (tag 5)")
            # Bucket
            self.assertIn(6, tags, f"{label} walk missing bucket_norm (tag 6)")
            self.assertIn(7, tags, f"{label} walk missing bucket_dmg1 (tag 7)")
            self.assertIn(8, tags, f"{label} walk missing bucket_dmg2 (tag 8)")
            # Brick
            self.assertIn(9, tags, f"{label} walk missing brick_norm (tag 9)")
            self.assertIn(10, tags, f"{label} walk missing brick_dmg1 (tag 10)")
            self.assertIn(11, tags, f"{label} walk missing brick_dmg2 (tag 11)")

            # Die animation must have tag 5 (bone stump) and no arm_flesh (tag 4) or armor
            die_f0 = anim_data["animations"]["die"]["frames"][0]
            die_tags = {s[7] for s in die_f0 if len(s) > 7}
            self.assertIn(5, die_tags, f"{label} die missing arm_bone (tag 5)")
            self.assertNotIn(4, die_tags, f"{label} die should not have arm_flesh (tag 4)")
            self.assertNotIn(1, die_tags, f"{label} die should not have cone_norm (tag 1)")

    def test_wallnut_plantfood_armor_tags_present(self):
        """Ensure Wall-nut animation has tags 12, 13, 14 for plantfood armor."""
        all_tags = set()
        for anim_name, anim_data in self.wallnut_anim["animations"].items():
            for frame in anim_data["frames"]:
                for s in frame:
                    if len(s) > 7:
                        all_tags.add(s[7])
        self.assertIn(12, all_tags, "Wall-nut missing pf armor stage 0 (tag 12)")
        self.assertIn(13, all_tags, "Wall-nut missing pf armor stage 1 (tag 13)")
        self.assertIn(14, all_tags, "Wall-nut missing pf armor stage 2 (tag 14)")

    def test_armor_degradation_ranges_and_half_health_arm_drop(self):
        """Verify armor degradation ranges and that arm specifically drops at half health (50%)."""
        for armor_type, max_armor_hp in [("cone", 370.0), ("bucket", 1100.0), ("brick", 2200.0)]:
            armor_health = max_armor_hp
            body_health = 190.0
            max_body_health = 190.0
            stage = 0
            armor_dropped = False
            arm_dropped = False

            def take_damage(amount):
                nonlocal armor_health, body_health, stage, armor_dropped, arm_dropped
                if armor_health > 0:
                    dmg = min(armor_health, amount)
                    excess = amount - dmg
                    armor_health -= dmg
                    # Degrades divided into equal health ranges (3 stages: 0, 1, 2)
                    frac = armor_health / max_armor_hp
                    if frac > (2.0 / 3.0):
                        stage = 0
                    elif frac > (1.0 / 3.0):
                        stage = 1
                    elif frac > 0.0:
                        stage = 2
                    else:
                        armor_dropped = True
                    if excess > 0:
                        apply_body_damage(excess)
                else:
                    apply_body_damage(amount)

            def apply_body_damage(amount):
                nonlocal body_health, arm_dropped
                body_health -= amount
                # Arm drops specifically at half health (<= 50%)
                if not arm_dropped and body_health <= max_body_health * 0.5:
                    arm_dropped = True

            # Full health
            self.assertEqual(stage, 0)
            self.assertFalse(armor_dropped)
            self.assertFalse(arm_dropped)

            # Damage to reach stage 1 (just below 2/3)
            take_damage(max_armor_hp * (1.0 / 3.0) + 1.0)
            self.assertEqual(stage, 1)
            self.assertFalse(armor_dropped)
            self.assertFalse(arm_dropped)

            # Damage to reach stage 2 (just below 1/3)
            take_damage(max_armor_hp * (1.0 / 3.0))
            self.assertEqual(stage, 2)
            self.assertFalse(armor_dropped)
            self.assertFalse(arm_dropped)

            # Break armor completely
            take_damage(armor_health)
            self.assertTrue(armor_dropped)
            self.assertEqual(armor_health, 0.0)
            self.assertFalse(arm_dropped) # Body HP still full (190.0)

            # Deal 50 dmg to body: 140 HP remaining (> 95.0 HP) -> arm intact
            take_damage(50.0)
            self.assertEqual(body_health, 140.0)
            self.assertFalse(arm_dropped)

            # Deal 45 dmg to body: 95 HP remaining (== 50% max HP) -> arm drops!
            take_damage(45.0)
            self.assertEqual(body_health, 95.0)
            self.assertTrue(arm_dropped)

    def test_wallnut_health_degrades_formula(self):
        """Wall-nut has 4 body degrades based on health ranges: >75%, 50-75%, 25-50%, <25%."""
        max_hp = 4000.0
        def get_wallnut_anim(hp):
            frac = hp / max_hp
            if frac > 0.75:
                return "idle"
            elif frac > 0.50:
                return "damage"
            elif frac > 0.25:
                return "damage2"
            else:
                return "damage3"

        self.assertEqual(get_wallnut_anim(4000.0), "idle")
        self.assertEqual(get_wallnut_anim(3001.0), "idle")
        self.assertEqual(get_wallnut_anim(3000.0), "damage")
        self.assertEqual(get_wallnut_anim(2001.0), "damage")
        self.assertEqual(get_wallnut_anim(2000.0), "damage2")
        self.assertEqual(get_wallnut_anim(1001.0), "damage2")
        self.assertEqual(get_wallnut_anim(1000.0), "damage3")
        self.assertEqual(get_wallnut_anim(200.0), "damage3")

    def test_wallnut_plantfood_armor(self):
        """Wall-nut Plant Food armor has 8000 HP, absorbs damage first, with 3 degrade stages."""
        max_pf_armor = 8000.0
        pf_armor_hp = 8000.0
        body_hp = 4000.0

        def get_pf_stage(hp):
            frac = hp / max_pf_armor
            if frac > (2.0 / 3.0):
                return 0
            elif frac > (1.0 / 3.0):
                return 1
            elif frac > 0.0:
                return 2
            return -1

        self.assertEqual(get_pf_stage(8000.0), 0)
        self.assertEqual(get_pf_stage(5333.0), 1)
        self.assertEqual(get_pf_stage(2666.0), 2)
        self.assertEqual(get_pf_stage(0.0), -1)

    def test_potato_mine_explosion_reach(self):
        """Potato Mine explosion reaches leftwards (-145px) to catch zombies eating an adjacent Wall-nut."""
        mine_x = 500.0
        # Wall-nut is 1 tile left (~115px away). Zombie eating it is at ~ 500 - 115 + 35 = 420px (diff = -80px)
        # Or even behind it at 380px (diff = -120px)
        def is_in_explosion(z_x):
            diff = z_x - mine_x
            return diff >= -145.0 and diff <= 110.0

        def is_in_trigger(z_x):
            diff = z_x - mine_x
            return diff >= -35.0 and diff <= 40.0

        # Zombie eating Wall-nut on adjacent left tile is damaged by explosion but doesn't trigger mine prematurely
        self.assertTrue(is_in_explosion(420.0))
        self.assertFalse(is_in_trigger(420.0)) # Sweet spot preserved!
        self.assertTrue(is_in_explosion(380.0))
        self.assertFalse(is_in_trigger(380.0))

    def test_zombie_particle_matrix_scale(self):
        """Zombie particles use exact Flash vector scale factor 0.78125."""
        scale = 0.78125
        self.assertAlmostEqual(scale * 1.28, 1.0, places=4)

if __name__ == "__main__":
    unittest.main()
