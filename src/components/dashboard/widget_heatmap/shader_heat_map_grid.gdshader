shader_type canvas_item;
render_mode blend_add;

uniform vec2 grid_count = vec2(10.0);
uniform vec2 highlighted_cell = vec2(5.0);

void fragment(){
	float w = 1.0* SCREEN_PIXEL_SIZE.x;
	vec2 uv = fract(UV*grid_count);
	COLOR = vec4(uv.x*uv.y);
	vec2 hc = step(highlighted_cell, UV*grid_count ) - step(highlighted_cell + 1.0, UV*grid_count );
	COLOR += vec4(hc.x * hc.y);
	COLOR.a += (hc.x * hc.y);
	COLOR.a *= 0.05;
}