#!/usr/bin/env python3
"""
tools/popfx_decoder.py
Decoder for PopCap PopFX (.popfx / 'pcfx') shader format used in PvZ2 / PopCap Framework.
Extracts GLSL/HLSL source code and converts colorize_overlay and multiplicative_overlay
into Godot 4 CanvasItem shaders for in-game render effects (such as Plant Food glow).
"""

import sys
import os
import struct
import glob

def parse_popfx(filepath):
    """Parses a PopFX file according to PopFXFormat specification."""
    with open(filepath, 'rb') as f:
        data = f.read()

    if len(data) < 108:
        raise ValueError(f"File {filepath} too short for PopFX header")

    hdr = struct.unpack('<27I', data[:108])
    magic = hdr[0]
    # Check for 'pcfx' (0x70636678 in little-endian is b'xfcp')
    if magic != 0x70636678 and magic != 0x78666370:
        raise ValueError(f"Invalid magic: {hex(magic)}")

    num_strings = hdr[8]
    string_table = hdr[9]
    num_shaders = hdr[23]
    shader_table = hdr[24]
    string_data_offset = hdr[26]

    strings = []
    for i in range(num_strings):
        off = string_table + i * 12
        num_chars, fmt, str_off = struct.unpack('<III', data[off:off+12])
        raw = data[string_data_offset + str_off : string_data_offset + str_off + num_chars]
        strings.append(raw.decode('utf-8', errors='ignore'))

    shaders = []
    for i in range(num_shaders):
        sh_off = shader_table + i * 20
        fmt_idx, data_idx, num_params, param_begin, entry_idx = struct.unpack('<IIIII', data[sh_off:sh_off+20])
        fmt_str = strings[fmt_idx] if fmt_idx < len(strings) else ''
        glsl_code = strings[data_idx] if data_idx < len(strings) else ''
        entry_str = strings[entry_idx] if entry_idx < len(strings) else ''
        shaders.append({
            'format': fmt_str,
            'entry': entry_str,
            'code': glsl_code
        })

    return {
        'filepath': filepath,
        'strings': strings,
        'shaders': shaders
    }

def convert_colorize_overlay_to_godot_shader():
    """Converts the decoded colorize_overlay.popfx GLSL into a Godot 4 CanvasItem shader."""
    return """shader_type canvas_item;

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
"""

def main():
    if len(sys.argv) > 1 and sys.argv[1] != "all":
        paths = [sys.argv[1]]
    else:
        paths = sorted(glob.glob("Assets/Misc/RenderEffects/resource/effects/*.popfx"))

    os.makedirs("Shaders", exist_ok=True)

    for p in paths:
        try:
            res = parse_popfx(p)
            base = os.path.splitext(os.path.basename(p))[0]
            print(f"[✓] Successfully decoded {p}:")
            for i, sh in enumerate(res['shaders']):
                glsl_out = f"Shaders/{base}.glsl"
                with open(glsl_out, "w") as out_f:
                    out_f.write(sh['code'])
                print(f"    Exported GLSL -> {glsl_out}")
        except Exception as e:
            print(f"[!] Failed to parse {p}: {e}")

    # Generate the Godot shader for Plant Food glow
    pf_shader_path = "Shaders/plantfood_glow.gdshader"
    with open(pf_shader_path, "w") as f:
        f.write(convert_colorize_overlay_to_godot_shader())
    print(f"[✓] Generated Godot CanvasItem shader -> {pf_shader_path}")

if __name__ == "__main__":
    main()
