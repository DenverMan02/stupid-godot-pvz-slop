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
        debug_block_match = re.search(r"elif debug_mode:\s+(?:[^\n]+\n)+?\s+if event\.keycode == KEY_Z:", content)
        self.assertIsNotNone(debug_block_match, "KEY_Z must be nested under 'elif debug_mode:'")
    def test_audio_manager_autoload(self):
        """Verify AudioManager exists and is registered as an autoload in project.godot."""
        self.assertTrue(os.path.exists("audiomanager.gd"))
        with open("project.godot", "r") as f:
            content = f.read()
        self.assertIn('AudioManager="*res://audiomanager.gd"', content)

    def test_audio_manager_methods(self):
        """Verify AudioManager has play_sfx and play_music with pool handling."""
        with open("audiomanager.gd", "r") as f:
            content = f.read()
        self.assertIn("func play_sfx(", content)
        self.assertIn("func play_music(", content)
        self.assertIn("SFX_POOL_SIZE", content)

    def test_eating_sound_polyphony_limit(self):
        """Verify zombie eating uses cooldown/stagger to prevent ear-rape audio stacking."""
        with open("Scripts/Zombie.gd", "r") as f:
            content = f.read()
        self.assertIn("eat_sfx_timer", content)
        self.assertIn("res://Audio/SFX/eating.ogg", content)

    def test_sun_merging_system(self):
        """Verify sun merging logic: threshold 25, infinite scaling, and magnetic pull."""
        with open("Scripts/Sun.gd", "r") as f:
            content = f.read()
        self.assertIn("const MERGE_THRESHOLD: int = 25", content)
        self.assertIn("all_suns.size() >= MERGE_THRESHOLD", content)
        self.assertIn("get_target_scale()", content)
        self.assertIn("other.value", content)

    def test_ready_set_plant_banner_visuals(self):
        """Verify Ready Set Plant banner colors and outline matches PvZ1 style."""
        with open("Scenes/Lawn.tscn", "r") as f:
            content = f.read()
        self.assertIn("Ready...", content)
        self.assertIn("outline_size = 28", content)
        self.assertIn("font_size = 96", content)

        with open("Scripts/Lawn.gd", "r") as f:
            lawn_content = f.read()
        self.assertIn("Color(0.92, 0.05, 0.05", lawn_content)
        self.assertIn("Color(0.98, 0.78, 0.05", lawn_content)
        self.assertIn("Color(0.12, 0.72, 0.15", lawn_content)

    def test_plant_food_system_on_lawn(self):
        """Verify Lawn has plant food counter, maximum capacity of 3, and bank buttons."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("const MAX_PLANT_FOOD: int = 3", content)
        self.assertIn("var plant_food_count: int = 1", content)
        self.assertIn("func add_plant_food(", content)
        self.assertIn("func toggle_plant_food_armed()", content)
        self.assertIn("func use_plant_food_on(", content)
        self.assertIn("PlantFoodBank", content)
        self.assertIn("PlantFoodButton", content)

    def test_shovel_system(self):
        """Verify shovel button, toggle state, digging, and SFX."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("var is_shovel_active: bool = false", content)
        self.assertIn("func toggle_shovel()", content)
        self.assertIn("func dig_plant_at(", content)
        self.assertIn("shovel.ogg", content)
        self.assertIn("shovel_plant.ogg", content)

    def test_turbo_toggle_and_speed_scaling(self):
        """Verify turbo toggle sets Engine.time_scale to 1.5x / 1.0x."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("var is_turbo: bool = false", content)
        self.assertIn("func toggle_turbo()", content)
        self.assertIn("Engine.time_scale = 1.5 if is_turbo else 1.0", content)

    def test_pause_menu_system(self):
        """Verify pause menu with toggle, resume, and restart."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("func toggle_pause()", content)
        self.assertIn("func _resume_game()", content)
        self.assertIn("func _restart_game()", content)
        self.assertIn("get_tree().paused", content)

    def test_wave_progression_system(self):
        """Verify 10-wave progress meter, flags, zombie head progress, and music transitions."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("const TOTAL_WAVES: int = 10", content)
        self.assertIn("func _start_wave(", content)
        self.assertIn("func _update_wave_meter(", content)
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
        self.assertIn("var peashooter_pf_peas_remaining", content)
        self.assertIn("var peashooter_pf_timer", content)
        self.assertNotIn("get_tree().create_timer(i * interval).timeout.connect(func():", content)

    def test_peashooter_plantfood_duration_and_count(self):
        """Peashooter PF must fire strictly 60 peas in 2.0 seconds and return to normal."""
        with open("Scripts/Plant.gd", "r") as f:
            content = f.read()
        self.assertIn("peashooter_pf_peas_remaining = 60", content)
        self.assertIn("peashooter_pf_timer += 2.0 / 60.0", content)
        self.assertIn("_set_plantfood_glow(false)", content)

    def test_plantfood_bank_hud_layout(self):
        """Plantfood bank button uses plantfood_button.png, max of 3, and glowing dots."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("const MAX_PLANT_FOOD: int = 3", content)
        self.assertIn("plantfood_button.png", content)
        self.assertIn("plantfood_button_down.png", content)
        self.assertIn("plant_food_count >= (i + 2)", content)
        self.assertIn("plantfood_bank_filling_slot.png", content)
        self.assertIn("plant_food_glows", content)

    def test_shovel_and_progress_meter_positions(self):
        """Shovel must be at bottom-right and wave progress meter at top-center with level label."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        # Shovel at bottom-right
        self.assertTrue("Vector2(1780.0, 935.0)" in content or "Vector2(1790.0, 950.0)" in content)
        # Wave meter at top-center
        self.assertTrue("Vector2(750.0, 20.0)" in content or "Vector2(728.0, 16.0)" in content)
        self.assertIn("Modern Day - Day 1", content)
        self.assertIn("LevelNameLabel", content)

    def test_turbo_audio_effects(self):
        """Turbo toggle must play speed_up.ogg and speed_down.ogg."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("speed_up.ogg", content)
        self.assertIn("speed_down.ogg", content)

    def test_popfx_plantfood_glow_shader(self):
        """Decoded PopFX plant food glow shader exists and is applied to zombies with plant food."""
        self.assertTrue(os.path.exists("Shaders/plantfood_glow.gdshader"))
        with open("Shaders/plantfood_glow.gdshader", "r") as f:
            content = f.read()
        self.assertIn("colorize_overlay", content)
        self.assertIn("effect_enabled", content)
        self.assertIn("flash_intensity", content)

        # Plant food shader is strictly for zombies carrying plant food, NOT plants
        with open("Scripts/Zombie.gd", "r") as f:
            zombie_code = f.read()
        self.assertIn("res://Shaders/plantfood_glow.gdshader", zombie_code)
        self.assertIn("plantfood_glow_material", zombie_code)

        with open("Scripts/Plant.gd", "r") as f:
            plant_code = f.read()
        self.assertIn("func _set_plantfood_glow(", plant_code)

    def test_popfx_hurt_flash_shader(self):
        """PopFX hurt flash shader exists and is supported in shaders."""
        self.assertTrue(os.path.exists("Shaders/hurt_flash.gdshader"))
        with open("Shaders/hurt_flash.gdshader", "r") as f:
            content = f.read()
        self.assertIn("flash_intensity", content)
        self.assertIn("flash_color", content)

    def test_potato_mine_tile_placement_checks(self):
        """Verify potato mine checks cell occupation and incoming projectile reservations."""
        with open("Scripts/Lawn.gd", "r") as f:
            lawn_code = f.read()
        self.assertIn("func is_cell_occupied(", lawn_code)
        self.assertIn("pr.projectile_type == \"potato_pf\"", lawn_code)

    def test_cabbagepult_plantfood_volley(self):
        """Verify Cabbage-pult launches lobbed giant cabbages with damage 300."""
        with open("Scripts/Plant.gd", "r") as f:
            plant_code = f.read()
        self.assertIn("func _fire_cabbagepult_plantfood()", plant_code)
        self.assertIn("_spawn_cabbage_projectile_at(", plant_code)
        self.assertIn("p_is_giant", plant_code)

if __name__ == "__main__":
    unittest.main()
