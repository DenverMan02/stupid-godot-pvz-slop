import os, sys, json, re, base64, urllib.request
import xml.etree.ElementTree as ET

ns = {'xfl': 'http://ns.adobe.com/xfl/2008/'}

def mult_matrix(m1, m2):
    a1, b1, c1, d1, tx1, ty1 = m1
    a2, b2, c2, d2, tx2, ty2 = m2
    return [
        a1 * a2 + c1 * b2,
        b1 * a2 + d1 * b2,
        a1 * c2 + c1 * d2,
        b1 * c2 + d1 * d2,
        a1 * tx2 + c1 * ty2 + tx1,
        b1 * tx2 + d1 * ty2 + ty1
    ]

def parse_matrix_elem(elem):
    if elem is None:
        return [1.0, 0.0, 0.0, 1.0, 0.0, 0.0]
    mat = elem.find('.//xfl:Matrix', ns)
    if mat is None:
        return [1.0, 0.0, 0.0, 1.0, 0.0, 0.0]
    return [
        float(mat.attrib.get('a', '1.0')),
        float(mat.attrib.get('b', '0.0')),
        float(mat.attrib.get('c', '0.0')),
        float(mat.attrib.get('d', '1.0')),
        float(mat.attrib.get('tx', '0.0')),
        float(mat.attrib.get('ty', '0.0'))
    ]

def compile_plant_from_dir(plant_dir, output_path=None):
    dom_path = os.path.join(plant_dir, 'DOMDocument.xml')
    if not os.path.exists(dom_path):
        for root, dirs, files in os.walk(plant_dir):
            if 'DOMDocument.xml' in files:
                dom_path = os.path.join(root, 'DOMDocument.xml')
                plant_dir = root
                break
    if not os.path.exists(dom_path):
        print(f"Error: DOMDocument.xml not found at {dom_path}")
        return None

    tree = ET.parse(dom_path)
    dom_root = tree.getroot()

    item_name = os.path.basename(os.path.normpath(plant_dir)).replace('.xfl', '').lower()
    is_zombie = 'zombie' in item_name
    is_sun = item_name == 'sun'

    frame_rate = float(dom_root.attrib.get('frameRate', '30.0'))
    stage_w = float(dom_root.attrib.get('width', '390.0'))
    stage_h = float(dom_root.attrib.get('height', '390.0'))

    if is_sun:
        pivot_x = 72.35
        pivot_y = 79.7
    else:
        pivot_x = stage_w / 2.0
        pivot_y = 230.0

    parsed_symbols = {}
    def get_sym(sym_name):
        if sym_name in parsed_symbols:
            return parsed_symbols[sym_name]
        for lib in ['library', 'LIBRARY']:
            for cand in [sym_name, sym_name.split('/')[-1] if '/' in sym_name else sym_name]:
                path = os.path.join(plant_dir, lib, f"{cand}.xml")
                if os.path.exists(path):
                    s_tree = ET.parse(path)
                    s_root = s_tree.getroot()
                    parsed_symbols[sym_name] = s_root
                    return s_root
        return None

    texture_map = {}
    texture_list = []
    def get_tex_id(name):
        path = name if name.endswith('.png') else f"{name}.png"
        if path not in texture_map:
            texture_map[path] = len(texture_list)
            texture_list.append(path)
        return texture_map[path]

    COSTUME_KEYWORDS = ['custom', 'costume', 'halloween', 'valenbrainz', 'feastivus', 'springening', 'summernights', 'birthdayz', 'shades', 'sunglasses', 'earmuff', 'monocle', 'tophat']
    ZOMBIE_HIDE_KEYWORDS = ['butter', 'ink', 'ground_swatch', 'brick', 'bucket', 'cone', 'zombie_arm_outer_upper_bone', '_particles']

    def eval_sym(sym_name, frame_idx, parent_mat, draw_list, anim_name, is_root=False):
        lower_name = sym_name.lower()
        if any(k in lower_name for k in COSTUME_KEYWORDS):
            return
        if is_zombie and any(k in lower_name for k in ZOMBIE_HIDE_KEYWORDS):
            return
        if 'gatlingpea_helmet_screw' in lower_name:
            return
        if anim_name != 'plantfood' and ('gatlingpea_' in lower_name or 'armor' in lower_name or 'helmet' in lower_name):
            return

        dom = get_sym(sym_name)
        if dom is None:
            return
        tl = dom.find('.//xfl:DOMTimeline', ns)
        if tl is None:
            return
        layers = tl.findall('.//xfl:DOMLayer', ns)

        tl_dur = 0
        for l in layers:
            for f in l.findall('.//xfl:DOMFrame', ns):
                idx = int(f.attrib.get('index', 0))
                dur = int(f.attrib.get('duration', 1))
                tl_dur = max(tl_dur, idx + dur)
        if tl_dur == 0:
            return

        eval_f = frame_idx if is_root else (frame_idx % tl_dur)

        for layer in reversed(layers):
            if layer.attrib.get('layerType') in ['guide', 'mask']:
                continue
            if layer.attrib.get('visible') == 'false':
                continue
            lname = layer.attrib.get('name', '').lower()
            if any(k in lname for k in ['custom', 'costume', 'guide']):
                continue
            if is_zombie and any(k in lname for k in ZOMBIE_HIDE_KEYWORDS):
                continue
            if anim_name != 'plantfood' and 'armor' in lname:
                continue

            active_frame = None
            for f in layer.findall('.//xfl:DOMFrame', ns):
                idx = int(f.attrib.get('index', 0))
                dur = int(f.attrib.get('duration', 1))
                if idx <= eval_f < idx + dur:
                    active_frame = f
                    break
            if active_frame is None:
                continue

            elements = active_frame.find('xfl:elements', ns)
            if elements is None:
                continue
            for el in elements:
                # Filter invisible elements with alphaMultiplier = 0
                col_el = el.find('.//xfl:Color', ns)
                if col_el is not None:
                    alpha = float(col_el.attrib.get('alphaMultiplier', '1.0'))
                    if alpha <= 0.05:
                        continue

                tag = el.tag.split('}')[-1]
                if tag == 'DOMBitmapInstance':
                    img_name = el.attrib.get('libraryItemName', '')
                    if '8x8' in img_name and 'peashooter' in img_name:
                        continue
                    if anim_name != 'plantfood' and any(arm in img_name for arm in ['120x139', '120x100', '110x51']):
                        continue
                    if any(c in img_name for c in ['107x107', '49x35', '85x36', '70x72']):
                        continue
                    t_id = get_tex_id(img_name)
                    local_m = parse_matrix_elem(el)
                    final_m = mult_matrix(parent_mat, local_m)
                    draw_list.append([t_id] + [round(v, 4) for v in final_m])
                elif tag == 'DOMSymbolInstance':
                    sub_name = el.attrib.get('libraryItemName')
                    sub_first = int(el.attrib.get('firstFrame', 0))
                    loop_type = el.attrib.get('loop', 'loop')
                    sub_f = sub_first if loop_type == 'single frame' else (sub_first + eval_f)
                    local_m = parse_matrix_elem(el)
                    final_m = mult_matrix(parent_mat, local_m)
                    eval_sym(sub_name, sub_f, final_m, draw_list, anim_name, is_root=False)

    anim_defs = {}
    action_events = {}

    tl = dom_root.find('.//xfl:DOMTimeline', ns)
    for layer in tl.findall('.//xfl:DOMLayer', ns):
        lname = layer.attrib.get('name')
        if lname in ['label', 'labels']:
            for f in layer.findall('.//xfl:DOMFrame', ns):
                lbl = f.attrib.get('name')
                idx = int(f.attrib.get('index', 0))
                dur = int(f.attrib.get('duration', 1))
                if lbl:
                    anim_defs[lbl] = {'start': idx, 'duration': dur}
        elif lname in ['action', 'actions']:
            for f in layer.findall('.//xfl:DOMFrame', ns):
                idx = int(f.attrib.get('index', 0))
                for s in f.findall('.//xfl:script', ns):
                    txt = s.text or ''
                    m = re.findall(r'fscommand\s*\(\s*["\']([^"\']+)["\']', txt)
                    if m:
                        action_events[idx] = m[0]

    instance_symbols = {}
    for layer in tl.findall('.//xfl:DOMLayer', ns):
        lname = (layer.attrib.get('name') or '').lower()
        if lname in ['label', 'labels', 'action', 'actions', 'guide']:
            continue
        for f in layer.findall('.//xfl:DOMFrame', ns):
            idx = int(f.attrib.get('index', 0))
            dur = int(f.attrib.get('duration', 1))
            for el in f.findall('.//xfl:DOMSymbolInstance', ns):
                sym = el.attrib.get('libraryItemName')
                if sym:
                    for f_i in range(idx, idx + dur):
                        if f_i not in instance_symbols:
                            instance_symbols[f_i] = sym

    compiled_anims = {}
    for anim_name, info in anim_defs.items():
        start = info['start']
        dur = info['duration']
        sym_name = instance_symbols.get(start)
        if not sym_name:
            for cand in [f'label/{anim_name}', anim_name, 'Symbol 1', 'Symbol1']:
                if get_sym(cand) is not None:
                    sym_name = cand
                    break
        if not sym_name:
            sym_name = f'label/{anim_name}'

        frames_data = []
        events_data = {}

        for local_f in range(dur):
            abs_f = start + local_f
            if abs_f in action_events:
                events_data[str(local_f)] = action_events[abs_f]

            draw_list = []
            base_mat = [1.0, 0.0, 0.0, 1.0, -pivot_x, -pivot_y]
            eval_sym(sym_name, local_f, base_mat, draw_list, anim_name, is_root=True)
            frames_data.append(draw_list)

        compiled_anims[anim_name] = {
            'frame_count': dur,
            'events': events_data,
            'frames': frames_data
        }

    out_data = {
        'name': item_name,
        'frame_rate': frame_rate,
        'stage_size': [stage_w, stage_h],
        'pivot': [pivot_x, pivot_y],
        'textures': texture_list,
        'animations': compiled_anims
    }

    if output_path is None:
        output_path = os.path.join(os.path.dirname(plant_dir), f"{item_name}.anim.json")

    with open(output_path, 'w') as out_f:
        json.dump(out_data, out_f)
    print(f"Compiled {item_name}: {len(compiled_anims)} animations, {len(texture_list)} textures -> {output_path}")
    return output_path

if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else 'all'
    if target.lower() in ['all', '--all', '-a']:
        # Walk all asset directories for .xfl folders
        for root_dir in ['Assets/Plants', 'Assets/Zombies', 'Assets/Misc', 'Assets/GridItems', 'Assets/UI']:
            if not os.path.exists(root_dir):
                continue
            for cur_root, dirs, files in os.walk(root_dir):
                dirs[:] = [d for d in dirs if 'research purposes' not in d.lower()]
                for d in dirs:
                    if d.endswith('.xfl'):
                        full = os.path.join(cur_root, d)
                        print(f"\n--- Compiling {full} ---")
                        try:
                            compile_plant_from_dir(full)
                        except Exception as e:
                            print(f"Error compiling {full}: {e}")
    else:
        p_dir = f"Assets/Plants/{target}.xfl" if not target.endswith('.xfl') else target
        compile_plant_from_dir(p_dir)
