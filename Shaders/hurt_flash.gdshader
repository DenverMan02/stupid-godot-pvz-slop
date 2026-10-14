shader_type canvas_item;

// Decoded PopFX Hurt Flash / Flashback effect
// Mixes texture color towards pure white on hit
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 col = texture(TEXTURE, UV) * COLOR;
    if (flash_intensity > 0.001 && col.a > 0.01) {
        col.rgb = mix(col.rgb, flash_color.rgb, flash_intensity * flash_color.a);
    }
    COLOR = col;
}
