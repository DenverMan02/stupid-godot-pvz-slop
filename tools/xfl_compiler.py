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
        print(f"Error: DOMDocument.xml not found at {dom_path}")
        return None

    tree = ET.parse(dom_path)
    dom_root = tree.getroot()

    frame_rate = float(dom_root.attrib.get('frameRate', '30.0'))
    stage_w = float(dom_root.attrib.get('width', '390.0'))
    stage_h = float(dom_root.attrib.get('height', '390.0'))
    pivot_x = stage_w / 2.0
    pivot_y = 230.0

    parsed_symbols = {}
    def get_sym(sym_name):
        if sym_name in parsed_symbols:
            return parsed_symbols[sym_name]
        for lib in ['library', 'LIBRARY']:
            path = os.path.join(plant_dir, lib, f"{sym_name}.xml")
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

    def eval_sym(sym_name, frame_idx, parent_mat, draw_list, anim_name, is_root=False):
        if sym_name == 'sprite/_custom':
            return
        if anim_name != 'plantfood' and 'gatlingpea_' in sym_name:
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
                tag = el.tag.split('}')[-1]
                if tag == 'DOMBitmapInstance':
                    img_name = el.attrib.get('libraryItemName')
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
        lname = layer.attrib.get('name')
        if lname in ['instance', 'instances']:
            for f in layer.findall('.//xfl:DOMFrame', ns):
                idx = int(f.attrib.get('index', 0))
                for el in f.findall('.//xfl:DOMSymbolInstance', ns):
                    sym = el.attrib.get('libraryItemName')
                    if sym:
                        instance_symbols[idx] = sym

    compiled_anims = {}
    for anim_name, info in anim_defs.items():
        start = info['start']
        dur = info['duration']
        sym_name = instance_symbols.get(start, f'label/{anim_name}')

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

    plant_name = os.path.basename(os.path.normpath(plant_dir)).replace('.xfl', '')
    out_data = {
        'name': plant_name,
        'frame_rate': frame_rate,
        'stage_size': [stage_w, stage_h],
        'pivot': [pivot_x, pivot_y],
        'textures': texture_list,
        'animations': compiled_anims
    }

    if output_path is None:
        output_path = os.path.join(os.path.dirname(plant_dir), f"{plant_name}.anim.json")

    with open(output_path, 'w') as out_f:
        json.dump(out_data, out_f)
    print(f"Compiled {plant_name}: {len(compiled_anims)} animations, {len(texture_list)} textures -> {output_path}")
    return output_path

if __name__ == '__main__':
    target = sys.argv[1] if len(sys.argv) > 1 else 'peashooter'
    p_dir = f"Assets/Plants/{target}.xfl" if not target.endswith('.xfl') else target
    compile_plant_from_dir(p_dir)
