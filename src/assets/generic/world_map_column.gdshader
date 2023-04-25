shader_type spatial;
render_mode unshaded;

uniform vec4 albedo_color : hint_color;

uniform float rim_power = 4.0;
uniform float rim_range = 3.0;
uniform vec3 rim_direction = vec3(1.,0.,0.);


void fragment() {
	float rim_f = clamp(pow( 1.0 - dot( NORMAL, rim_direction ), rim_range ) * pow( 1.0 - dot( NORMAL, VIEW ), rim_range ), 0.0, 1.0);
	ALBEDO = albedo_color.rgb * (rim_f+0.3)*rim_power;
	}