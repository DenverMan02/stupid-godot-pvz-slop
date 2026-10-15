shader_type canvas_item;

// The concept renders are JPGs on white. Key near-white pixels so the renders
// sit naturally on the black town canvas instead of appearing as white cards.
uniform float white_threshold : hint_range(0.90, 1.0) = 0.985;
uniform float feather_width : hint_range(0.001, 0.08) = 0.015;
uniform float neutral_tolerance : hint_range(0.0, 0.25) = 0.08;

void fragment() {
    vec4 pixel = texture(TEXTURE, UV) * COLOR;
    float brightest = max(pixel.r, max(pixel.g, pixel.b));
    float darkest = min(pixel.r, min(pixel.g, pixel.b));
    float saturation = brightest - darkest;
    float luminance = dot(pixel.rgb, vec3(0.299, 0.587, 0.114));

    float white_background = smoothstep(
        white_threshold - feather_width,
        white_threshold + feather_width,
        luminance
    );
    float neutral_white = 1.0 - smoothstep(
        neutral_tolerance,
        neutral_tolerance + 0.08,
        saturation
    );

    pixel.a *= 1.0 - white_background * neutral_white;
    COLOR = pixel;
}
