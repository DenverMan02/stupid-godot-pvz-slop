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
        """Verify Ready Set Plant banner colors and outline matches PvZ style (all same red color)."""
        with open("Scenes/Lawn.tscn", "r") as f:
            content = f.read()
        self.assertIn("Ready...", content)
        self.assertIn("outline_size = 28", content)
        self.assertIn("font_size = 96", content)

        with open("Scripts/Lawn.gd", "r") as f:
            lawn_content = f.read()
        self.assertIn("Color(0.92, 0.05, 0.05", lawn_content)
        self.assertIn('start_label.text = "Set..."', lawn_content)
        self.assertIn('start_label.text = "PLANT!"', lawn_content)

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
        """Verify PvZ2 pause menu matching official layout, toppers, sliders, and buttons."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("func toggle_pause()", content)
        self.assertIn("func _resume_game()", content)
        self.assertIn("func _restart_game()", content)
        self.assertIn("func _on_save_and_exit_pressed()", content)
        self.assertIn("windowtopper.png", content)
        self.assertIn("sunflower_topper.png", content)
        self.assertIn("dialogborder.png", content)
        self.assertIn("dialogtexture.png", content)
        self.assertIn("slider_bolt.png", content)
        self.assertIn("audio-bar.png", content)
        self.assertIn("audio-fill.png", content)
        self.assertIn("SAVE AND EXIT", content)
        self.assertIn("RESTART", content)
        self.assertIn("RESUME", content)

    def test_wave_progression_system(self):
        """Verify 10-wave progress meter, unraised flags popping up, and midwave randomization."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("const TOTAL_WAVES: int = 10", content)
        self.assertIn("func _start_wave(", content)
        self.assertIn("func _advance_wave_meter(", content)
        self.assertIn("func _update_wave_meter(", content)
        self.assertIn("func _announce_huge_wave(", content)
        self.assertIn("func _play_random_midwave()", content)
        self.assertIn("last_midwave_index", content)
        self.assertIn("modern_midwave_a.mp3", content)
        self.assertIn("modern_midwave_b.mp3", content)
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
        """Plantfood bank button uses plantfood_button.png, max of 3, and slot indexing without lag."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        self.assertIn("const MAX_PLANT_FOOD: int = 3", content)
        self.assertIn("plantfood_button.png", content)
        self.assertIn("plantfood_button_down.png", content)
        self.assertTrue("plant_food_count >= (i + 2)" in content or "plant_food_count >= (i + 1)" in content)
        self.assertIn("plantfood_bank_filling_slot.png", content)
        self.assertIn("plant_food_glows", content)
        self.assertTrue("Vector2(96.0, 41.0)" in content or "Vector2(94.0, 40.0)" in content)

    def test_shovel_and_progress_meter_positions(self):
        """Shovel must be at bottom-right and wave progress meter at top-center with level label swapped on top."""
        with open("Scripts/Lawn.gd", "r") as f:
            content = f.read()
        # Shovel at bottom-right
        self.assertTrue("Vector2(1780.0, 935.0)" in content or "Vector2(1790.0, 950.0)" in content)
        # Wave meter at top-center
        self.assertTrue("Vector2(750.0, 14.0)" in content or "Vector2(750.0, 20.0)" in content)
        self.assertIn("Modern Day - Day 1", content)
        self.assertIn("LevelNameLabel", content)
        self.assertIn("track_right - fill_w", content)

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


    def test_pause_menu_visual_alignments(self):
        with open("Scripts/Lawn.gd", "r") as f:
            lawn_code = f.read()
        self.assertIn("var diag_w = 920.0", lawn_code)
        self.assertIn("var w_front = 1040.0", lawn_code)
        self.assertIn("top_grass_y - 25.0", lawn_code)
        self.assertIn("var btn_size = Vector2(250.0, 90.0)", lawn_code)

    def test_plant_food_button_pixel_centering(self):
        with open("Scripts/Lawn.gd", "r") as f:
            lawn_code = f.read()
        self.assertIn("pf_main_btn.position = Vector2(22.0, 23.0)", lawn_code)

    def test_wave_bar_full_fill_and_no_gap(self):
        with open("Scripts/Lawn.gd", "r") as f:
            lawn_code = f.read()
        self.assertIn("var track_right = 405.0", lawn_code)
        self.assertIn("var max_fill_w = 390.0", lawn_code)
        self.assertIn("meter_fill.position = Vector2(405.0, 51.0)", lawn_code)
        self.assertIn("final_flag_icon.position = Vector2(14.0, 56.0)", lawn_code)

    def test_animation_viewer_auto_detection(self):
        with open("Scripts/AnimationViewer.gd", "r") as f:
            av_code = f.read()
        self.assertIn("func _scan_and_build_catalog()", av_code)
        self.assertIn("res://Assets/Plants", av_code)
        self.assertIn("res://Assets/Zombies", av_code)
        self.assertIn("res://Assets/Mowers", av_code)

    def test_new_plants_registered(self):
        with open("Scripts/Lawn.gd", "r") as f:
            lawn_code = f.read()
        for pid in ["repeater", "sunflower_twin", "peashooter_super", "threepeater", "three_head_sunflower"]:
            self.assertIn('"id": "%s"' % pid, lawn_code)

    def test_lawnmowers_system(self):
        self.assertTrue(os.path.exists("Scripts/LawnMower.gd"))
        self.assertTrue(os.path.exists("Scenes/LawnMower.tscn"))
        with open("Scripts/LawnMower.gd", "r") as f:
            mower_code = f.read()
        self.assertIn("class_name LawnMower", mower_code)
        self.assertIn("State.TRIGGERED", mower_code)
        self.assertIn("take_damage(99999.0)", mower_code)
        self.assertIn("res://Assets/Mowers/mower_modern.anim.json", mower_code)

        with open("Scripts/Lawn.gd", "r") as f:
            lawn_code = f.read()
        self.assertIn("func _setup_lawn_mowers()", lawn_code)
        self.assertIn("Vector2(705.0, row_y)", lawn_code)

    def test_plantfood_pickup_vfx_and_item(self):
        """Verify plantfood pickup animations: idle for dropped item, animation/animation2 for carrying zombies."""
        with open("Scripts/PlantFoodItem.gd", "r") as f:
            item_code = f.read()
        self.assertIn("plantfood_pickup.anim.json", item_code)
        self.assertIn('play("idle", true)', item_code)

        with open("Scripts/Zombie.gd", "r") as f:
            zombie_code = f.read()
        self.assertIn("plantfood_pickup.anim.json", zombie_code)
        self.assertIn('play("animation", true)', zombie_code)
        self.assertIn('play("animation2", true)', zombie_code)
        self.assertIn("pf_vfx_node1", zombie_code)
        self.assertIn("pf_vfx_node2", zombie_code)

    def test_yellow_twin_sunflower_assets(self):
        """Verify yellow Twin Sunflower assets are used in PLANT_REGISTRY."""
        with open("Scripts/Lawn.gd", "r") as f:
            lawn_code = f.read()
        self.assertIn('"anim_json": "res://Assets/Plants/sunflower_twin.anim.json"', lawn_code)
        self.assertIn('"tex_dir": "res://Assets/Plants/sunflower_twin.xfl/library/"', lawn_code)
        self.assertTrue(os.path.exists("Assets/Plants/sunflower_twin.anim.json"))
        self.assertTrue(os.path.exists("Assets/Plants/sunflower_twin.xfl"))

    def test_potato_mine_no_infinite_bounce(self):
        """Verify potato mine projectile passes self to is_cell_occupied so it does not bounce infinitely."""
        with open("Scripts/Lawn.gd", "r") as f:
            lawn_code = f.read()
        self.assertIn("func is_cell_occupied(col: int, row: int, ignore_projectile: Projectile = null)", lawn_code)
        self.assertIn("pr != ignore_projectile", lawn_code)

        with open("Scripts/Projectile.gd", "r") as f:
            proj_code = f.read()
        self.assertIn("lawn.is_cell_occupied(target_cell.x, target_cell.y, self)", proj_code)
        self.assertIn("not lawn.is_cell_occupied(c, r, self)", proj_code)

    def test_debug_mode_plantfoodcheat(self):
        """Verify middle-click plant food cheat only works when debug mode is enabled."""
        with open("Scripts/Plant.gd", "r") as f:
            plant_code = f.read()
        self.assertIn("MOUSE_BUTTON_MIDDLE and is_debug:", plant_code)

        with open("Scripts/Lawn.gd", "r") as f:
            lawn_code = f.read()
        self.assertIn("MOUSE_BUTTON_MIDDLE and debug_mode:", lawn_code)

    def test_town_rework_assets_and_ui(self):
        """Verify Town scene and script use authentic town.jpg background and UI elements."""
        self.assertTrue(os.path.exists("Assets/Town/town_background.png"))
        self.assertTrue(os.path.exists("Assets/Town/UI/energy_icon.png"))
        self.assertTrue(os.path.exists("Assets/Town/UI/ui_player_profile.png"))
        self.assertTrue(os.path.exists("Assets/Town/UI/ui_neighborville_sign.png"))
        self.assertTrue(os.path.exists("Assets/Town/UI/ui_chat_box.png"))
        self.assertTrue(os.path.exists("Assets/Town/UI/ui_bottom_shelf.png"))
        self.assertTrue(os.path.exists("Assets/Town/UI/ui_battle_button.png"))
        self.assertTrue(os.path.exists("Assets/Town/UI/coin_icon.png"))
        self.assertTrue(os.path.exists("Assets/Town/UI/gem_icon.png"))
        self.assertTrue(os.path.exists("Assets/Town/UI/settings_gear.png"))

        with open("Scenes/Town.tscn", "r") as f:
            tscn_code = f.read()
        self.assertIn("res://Assets/Town/town_background.png", tscn_code)
        self.assertIn("ui_player_profile.png", tscn_code)
        self.assertIn("ui_battle_button.png", tscn_code)
        self.assertIn("ChatBox", tscn_code)
        self.assertIn("BottomShelf", tscn_code)

        with open("Scripts/Town.gd", "r") as f:
            town_code = f.read()
        self.assertIn("BUILDING_METADATA", town_code)
        self.assertIn("Crazy Dave's Workshop", town_code)
        self.assertIn("Zen Garden", town_code)
        self.assertIn("Guildhall", town_code)
        self.assertIn("Devour Tower", town_code)
        self.assertIn("_on_battle_button_pressed", town_code)
        self.assertNotIn("theme_override_constants.", town_code)
        self.assertIn('add_theme_constant_override("separation"', town_code)

if __name__ == "__main__":
    unittest.main()
