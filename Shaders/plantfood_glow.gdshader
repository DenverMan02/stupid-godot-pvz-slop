shader_type canvas_item;

// Decoded from Assets/Misc/RenderEffects/resource/effects/colorize_overlay.popfx
// PopFX colorize_overlay: mix(color.rgb, Params.rgb, Params.a)
uniform vec4 params : source_color = vec4(0.35, 1.0, 0.45, 0.6);
uniform float intensity : hint_range(0.0, 1.0) = 0.75;
uniform bool effect_enabled = false;

void fragment() {
    vec4 col = texture(TEXTURE, UV) * COLOR;
    if (effect_enabled) {
        float pulse = 0.5 + 0.5 * sin(TIME * 8.0);
        float effective_alpha = params.a * intensity * (0.6 + 0.4 * pulse);
        col.rgb = mix(col.rgb, params.rgb, effective_alpha);
    }
    COLOR = col;
}
