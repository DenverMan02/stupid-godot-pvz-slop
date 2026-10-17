shader_type canvas_item;

uniform float corner_radius : hint_range(0.0, 150.0) = 45.0;
uniform vec2 rect_size = vec2(1320.0, 920.0);

varying vec2 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	vec2 d = min(local_pos, rect_size - local_pos);
	if (d.x < corner_radius && d.y < corner_radius) {
		float dist = length(vec2(corner_radius) - d);
		if (dist > corner_radius) {
			discard;
		} else {
			COLOR.a *= clamp(corner_radius - dist, 0.0, 1.0);
		}
	}
}
