import os, sys, json, re, base64, urllib.request
import xml.etree.ElementTree as ET

def fetch_file(path):
    url = f'https://api.github.com/repos/DenverMan02/stupid-godot-pvz-slop/contents/{path}'
    req = urllib.request.Request(url, headers={'Accept': 'application/vnd.github+json'})
    with urllib.request.urlopen(req) as resp:
        return base64.b64decode(json.loads(resp.read().decode('utf-8'))['content']).decode('utf-8')

ns = {'xfl': 'http://ns.adobe.com/xfl/2008/'}
symbols_cache = {}

def get_symbol(name):
    if name in symbols_cache:
        return symbols_cache[name]
    content = fetch_file(f'Assets/Plants/peashooter.xfl/library/{name}.xml')
    dom = ET.fromstring(content)
    symbols_cache[name] = dom
    return dom

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

texture_map = {}
texture_list = []

def get_texture_id(name):
    path = name if name.endswith('.png') else f'{name}.png'
    if path not in texture_map:
        texture_map[path] = len(texture_list)
        texture_list.append(path)
    return texture_map[path]

def evaluate_symbol(symbol_name, frame_idx, parent_mat, draw_list):
    dom = get_symbol(symbol_name)
    tl = dom.find('.//xfl:DOMTimeline', ns)
    if tl is None:
        return
    layers = tl.findall('.//xfl:DOMLayer', ns)
    for layer in reversed(layers):
        frames = layer.findall('.//xfl:DOMFrame', ns)
        if not frames:
            continue
        max_f = max(int(f.attrib.get('index', 0)) + int(f.attrib.get('duration', 1)) for f in frames)
        if max_f == 0:
            continue
        curr_f = frame_idx % max_f
        
        active_frame = None
        for f in frames:
            idx = int(f.attrib.get('index', 0))
            dur = int(f.attrib.get('duration', 1))
            if idx <= curr_f < idx + dur:
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
                tex_id = get_texture_id(img_name)
                local_m = parse_matrix_elem(el)
                final_m = mult_matrix(parent_mat, local_m)
                draw_list.append([tex_id] + [round(v, 4) for v in final_m])
            elif tag == 'DOMSymbolInstance':
                sub_name = el.attrib.get('libraryItemName')
                sub_first = int(el.attrib.get('firstFrame', 0))
                loop_type = el.attrib.get('loop', 'loop')
                sub_f = sub_first if loop_type == 'single frame' else (sub_first + frame_idx)
                local_m = parse_matrix_elem(el)
                final_m = mult_matrix(parent_mat, local_m)
                evaluate_symbol(sub_name, sub_f, final_m, draw_list)

# Load DOMDocument
dom_xml = fetch_file('Assets/Plants/peashooter.xfl/DOMDocument.xml')
dom_root = ET.fromstring(dom_xml)

frame_rate = float(dom_root.attrib.get('frameRate', '30.0'))
stage_w = float(dom_root.attrib.get('width', '390.0'))
stage_h = float(dom_root.attrib.get('height', '390.0'))

# Plant ground anchor pivot: center X = 195.0, ground baseline Y = 230.0
pivot_x = 195.0
pivot_y = 230.0

# Extract animations and action events
anim_defs = {}
action_events = {} # frame_idx -> command

tl = dom_root.find('.//xfl:DOMTimeline', ns)
for layer in tl.findall('.//xfl:DOMLayer', ns):
    lname = layer.attrib.get('name')
    if lname == 'label':
        for f in layer.findall('.//xfl:DOMFrame', ns):
            lbl = f.attrib.get('name')
            idx = int(f.attrib.get('index', 0))
            dur = int(f.attrib.get('duration', 1))
            if lbl:
                anim_defs[lbl] = {'start': idx, 'duration': dur}
    elif lname == 'action':
        for f in layer.findall('.//xfl:DOMFrame', ns):
            idx = int(f.attrib.get('index', 0))
            for s in f.findall('.//xfl:script', ns):
                txt = s.text or ''
                # Look for fscommand("cmd", "arg")
                m = re.search(r'fscommand\s*\(\s*["\']([^"\']+)["\']', txt)
                if m:
                    action_events[idx] = m.group(1)

print('Discovered animations:', anim_defs)
print('Discovered action events:', action_events)

# Compile animations
compiled_anims = {}

for anim_name, info in anim_defs.items():
    start = info['start']
    dur = info['duration']
    symbol_name = f'label/{anim_name}'
    
    frames_data = []
    events_data = {}
    
    print(f'Compiling animation: {anim_name} ({dur} frames)...')
    for local_f in range(dur):
        abs_f = start + local_f
        if abs_f in action_events:
            events_data[str(local_f)] = action_events[abs_f]
            
        draw_list = []
        # Apply pivot offset matrix: [1, 0, 0, 1, -pivot_x, -pivot_y]
        base_mat = [1.0, 0.0, 0.0, 1.0, -pivot_x, -pivot_y]
        evaluate_symbol(symbol_name, local_f, base_mat, draw_list)
        frames_data.append(draw_list)
        
    compiled_anims[anim_name] = {
        'frame_count': dur,
        'events': events_data,
        'frames': frames_data
    }

final_output = {
    'name': 'peashooter',
    'frame_rate': frame_rate,
    'stage_size': [stage_w, stage_h],
    'pivot': [pivot_x, pivot_y],
    'textures': texture_list,
    'animations': compiled_anims
}

output_path = '/tmp/peashooter.anim.json'
with open(output_path, 'w') as out_f:
    json.dump(final_output, out_f)

print(f'Done! Successfully compiled {len(compiled_anims)} animations to {output_path}')
print(f'Total textures used: {len(texture_list)}')
print(f'Output JSON file size: {os.path.getsize(output_path) / 1024:.2f} KB')
