shader_type spatial;
render_mode unshaded;

uniform vec4 albedo_sea : hint_color;
uniform vec4 albedo_land : hint_color;
uniform vec4 albedo_border : hint_color;

uniform float rim_power = 4.0;
uniform float rim_range = 3.0;

uniform float rim_power_land = 4.0;
uniform float rim_range_land = 3.0;

uniform vec3 rim_direction = vec3(1.,0.,0.);

uniform sampler2D tex_map;
uniform sampler2D poles_uv_map;
uniform sampler2D poles_map;
uniform sampler2D top_down_map;

void fragment() {
	float rim_f = clamp(pow( 1.0 - dot( NORMAL, rim_direction ), rim_range ) * pow( 1.0 - dot( NORMAL, VIEW ), rim_range ), 0.0, 1.0);
	float rim_f_land = clamp(pow( 1.0 - dot( NORMAL, rim_direction ), rim_range_land ) * pow( 1.0 - dot( NORMAL, VIEW ), rim_range_land ), 0.0, 1.0);
	vec3 tex = texture(tex_map, UV).rgb;
	tex = mix(tex, texture(poles_map, UV).rgb, texture(poles_uv_map, UV).r);
	vec3 albedo_final = mix(vec3(0.0), albedo_sea.rgb, tex.b);
	albedo_final = mix(albedo_final, albedo_land.rgb * ((rim_f_land * rim_power_land*0.5) + 1.0), tex.g);
	albedo_final = mix(albedo_final, albedo_border.rgb * ((rim_f_land * rim_power_land) + 1.0), tex.r);
	ALBEDO = albedo_final * ((rim_f * rim_power) + 1.0);
	ALBEDO *= texture(top_down_map, UV).r;
}