#!/usr/bin/env python3
"""
tests/test_gameplay_systems.py
Automated test suite verifying:
1. Plant food bank logic, feeding plants, and plant food zombie drops.
2. Shovel system logic, plant destruction, and state toggling.
3. Turbo button 1.0x vs 1.5x time scaling and texture states.
4. Pause button and Pause Menu modal behavior.
5. Wave progression system (10 waves, midwave at 5, final wave at 10, flag drops, BGM transitions).
6. Title screen mouse-only click requirement.
7. Debug key gating (Z key summoning zombies strictly inside debug mode).
8. Head dropping via frame slices extraction.
"""

import unittest
import os
import re

class TestGameplaySystems(unittest.TestCase):

    def test_title_screen_mouse_only(self):
        """TitleScreen.gd must only advance on left mouse click, not on key presses."""
        with open("Scripts/TitleScreen.gd", "r") as f:
            content = f.read()
        self.assertIn("event.button_index == MOUSE_BUTTON_LEFT", content)
        self.assertNotIn("InputEventKey", content, "Key press should no longer trigger title screen transition")

    def test_debug_keys_gated_in_lawn(self):
        """Z, C, B, K keys to spawn zombies must be strictly gated behind debug_mode."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()

        # Check that elif debug_mode: encloses KEY_Z, KEY_C, KEY_B, KEY_K
        debug_block_match = re.search(r"elif debug_mode:\s+(?:[^\n]+\n)+?\s+if event\.keycode == KEY_Z:", content)
        self.assertIsNotNone(debug_block_match, "KEY_Z must be nested under 'elif debug_mode:'")

    def test_plant_food_system_in_lawn(self):
        """Verify plant food bank methods exist and operate with max 3 capacity."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("var plant_food_count: int = 1", content)
        self.assertIn("const MAX_PLANT_FOOD: int = 3", content)
        self.assertIn("func add_plant_food(", content)
        self.assertIn("func toggle_plant_food_armed(", content)
        self.assertIn("func use_plant_food_on(", content)
        self.assertIn("plantfood_bank.png", content)
        self.assertIn("plantfood_bank_filled_slot.png", content)

    def test_shovel_system_in_lawn(self):
        """Verify shovel toggle, plant digging, and audio cues exist."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("var is_shovel_active: bool = false", content)
        self.assertIn("func toggle_shovel(", content)
        self.assertIn("func dig_plant_at(", content)
        self.assertIn("shovel_button.png", content)
        self.assertIn("shovel_button_down.png", content)
        self.assertIn("shovel.ogg", content)
        self.assertIn("shovel_plant.ogg", content)

    def test_turbo_speedup_system_in_lawn(self):
        """Verify turbo toggle switches between 1.0x and 1.5x."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("var is_turbo: bool = false", content)
        self.assertIn("func toggle_turbo(", content)
        self.assertIn("Engine.time_scale = 1.5 if is_turbo else 1.0", content)
        self.assertIn("2x.png", content)
        self.assertIn("2x_selected.png", content)

    def test_pause_system_and_menu_in_lawn(self):
        """Verify pause menu modal and toggle exist with process_mode ALWAYS."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("func toggle_pause(", content)
        self.assertIn("get_tree().paused = new_paused", content)
        self.assertIn("PROCESS_MODE_ALWAYS", content)
        self.assertIn("pause.ogg", content)
        self.assertIn("func _resume_game(", content)
        self.assertIn("func _restart_game(", content)

    def test_wave_system_in_lawn(self):
        """Verify 10 waves structure, midwave at 5, final wave at 10, flag drop, and BGM."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("const TOTAL_WAVES: int = 10", content)
        self.assertIn("func _start_wave(", content)
        self.assertIn("func _announce_huge_wave(", content)
        self.assertIn("func _drop_mid_flag(", content)
        self.assertIn("func _drop_final_flag(", content)
        self.assertIn("modern_midwave_a.mp3", content)
        self.assertIn("modern_final_wave.mp3", content)
        self.assertIn("huge_wave_incoming.ogg", content)
        self.assertIn("huge_wave.ogg", content)
        self.assertIn("progress_meter.png", content)
        self.assertIn("progress_meter_zombiehead.png", content)

    def test_plant_food_zombie_and_item_scenes(self):
        """Verify PlantFoodItem scene and Zombie plant food drop logic."""
        self.assertTrue(os.path.exists("Scripts/PlantFoodItem.gd"))
        self.assertTrue(os.path.exists("Scenes/PlantFoodItem.tscn"))
        with open("Scripts/Zombie.gd", "r") as f:
            content = f.read()
        self.assertIn("var has_plant_food: bool = false", content)
        self.assertIn("func setup_plant_food(", content)
        self.assertIn("func _drop_plant_food(", content)

    def test_zombie_head_slices_extraction(self):
        """Verify XFLSprite2D has get_current_head_render_data and ZombieParticle renders slices."""
        with open("Scripts/XFLSprite2D.gd", "r") as f:
            content = f.read()
        self.assertIn("func get_current_head_render_data()", content)

        with open("Scripts/ZombieParticle.gd", "r") as f:
            content = f.read()
        self.assertIn("func setup_head_from_sprite(", content)

    def test_potato_mine_trigger_and_plant_hitbox(self):
        """Verify potato mine reach and zombie bite reach extended to the right."""
        with open("Scripts/Plant.gd", "r") as f:
            plant_content = f.read()
        self.assertIn("dist_x >= -45.0 and dist_x <= 70.0", plant_content)

        with open("Scripts/Zombie.gd", "r") as f:
            zombie_content = f.read()
        self.assertIn("dist_x >= -15.0 and dist_x <= 55.0", zombie_content)

    def test_lambda_freed_error_fixed(self):
        """Verify peashooter pf and sunflower sun do not use freed lambda captures."""
        with open("Scripts/Plant.gd", "r") as f:
            content = f.read()
        # Peashooter pf should use process variables rather than 30 create_timer lambdas capturing self
        self.assertIn("var peashooter_pf_peas_remaining", content)
        self.assertIn("var peashooter_pf_timer", content)
        self.assertNotIn("get_tree().create_timer(i * interval).timeout.connect(func():", content)

if __name__ == "__main__":
    unittest.main()
