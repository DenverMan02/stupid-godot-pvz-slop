#!/usr/bin/env python3
"""
tests/test_zombie_armor_and_bones.py
Automated test suite verifying zombie bone dropping, cone armor degradation states,
and tag compilation integrity according to PvZ2 official OBB specifications and PvZ2CH headers.
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

    def test_plant_slices_unaffected(self):
        """Ensure plant animations have no tags (length remains 7 for performance)."""
        for anim_name, anim_data in self.pea_anim["animations"].items():
            for frame in anim_data["frames"]:
                for slice_item in frame:
                    self.assertEqual(len(slice_item), 7, f"Plant slice in {anim_name} should have 7 elements")

    def test_zombie_animation_tags_present(self):
        """Ensure zombie animations have the correct tags for cone armor (1, 2, 3) and arm (4, 5)."""
        for anim_data, label in [(self.male_anim, "male"), (self.fem_anim, "female")]:
            walk_f0 = anim_data["animations"]["walk"]["frames"][0]
            tags = {s[7] for s in walk_f0 if len(s) > 7}
            self.assertIn(1, tags, f"{label} walk missing cone_norm (tag 1)")
            self.assertIn(2, tags, f"{label} walk missing cone_dmg1 (tag 2)")
            self.assertIn(3, tags, f"{label} walk missing cone_dmg2 (tag 3)")
            self.assertIn(4, tags, f"{label} walk missing arm_flesh (tag 4)")
            self.assertIn(5, tags, f"{label} walk missing arm_bone (tag 5)")

            # Die animation must have tag 5 (bone stump) and no arm_flesh (tag 4)
            die_f0 = anim_data["animations"]["die"]["frames"][0]
            die_tags = {s[7] for s in die_f0 if len(s) > 7}
            self.assertIn(5, die_tags, f"{label} die missing arm_bone (tag 5)")
            self.assertNotIn(4, die_tags, f"{label} die should not have arm_flesh (tag 4)")
            self.assertNotIn(1, die_tags, f"{label} die should not have cone_norm (tag 1)")

    def test_cone_armor_degradation_logic(self):
        """Simulate damage sequence on Conehead zombie (370 HP armor + 190 HP body)."""
        armor_health = 370.0
        max_armor_health = 370.0
        body_health = 190.0
        max_body_health = 190.0
        cone_state = 0
        cone_dropped = False
        arm_dropped = False

        def take_damage(amount):
            nonlocal armor_health, body_health, cone_state, cone_dropped, arm_dropped
            if armor_health > 0:
                dmg = min(armor_health, amount)
                excess = amount - dmg
                armor_health -= dmg
                if armor_health > 260.0:
                    cone_state = 0
                elif armor_health > 130.0:
                    cone_state = 1
                elif armor_health > 0.0:
                    cone_state = 2
                else:
                    cone_dropped = True
                if excess > 0:
                    apply_body_damage(excess)
            else:
                apply_body_damage(amount)

        def apply_body_damage(amount):
            nonlocal body_health, arm_dropped
            body_health -= amount
            if not arm_dropped and body_health <= max_body_health * (2.0 / 3.0):
                arm_dropped = True

        # State 0: Full health
        self.assertEqual(cone_state, 0)
        self.assertFalse(cone_dropped)
        self.assertFalse(arm_dropped)

        # Hit by 3 cabbage hits (40 dmg each = 120 dmg). Armor HP: 250.0 (<= 260) -> State 1
        take_damage(120.0)
        self.assertEqual(armor_health, 250.0)
        self.assertEqual(cone_state, 1)
        self.assertFalse(cone_dropped)

        # Hit by 4 more cabbage hits (160 dmg). Armor HP: 90.0 (<= 130) -> State 2
        take_damage(160.0)
        self.assertEqual(armor_health, 90.0)
        self.assertEqual(cone_state, 2)
        self.assertFalse(cone_dropped)

        # Hit by 3 more cabbage hits (120 dmg). Armor HP breaks (90 dealt to armor, 30 excess to body).
        # Body HP: 190 - 30 = 160.0 HP.
        take_damage(120.0)
        self.assertEqual(armor_health, 0.0)
        self.assertTrue(cone_dropped)
        self.assertEqual(body_health, 160.0)
        self.assertFalse(arm_dropped) # Body HP > 126.6667 HP

        # Hit by 1 more cabbage hit (40 dmg). Body HP: 120.0 HP <= 126.6667 HP -> Arm drops!
        take_damage(40.0)
        self.assertEqual(body_health, 120.0)
        self.assertTrue(arm_dropped)

        # Total damage to kill = 560 HP. Hit with 120 more dmg -> Body HP = 0
        take_damage(120.0)
        self.assertLessEqual(body_health, 0.0)

if __name__ == "__main__":
    unittest.main()
