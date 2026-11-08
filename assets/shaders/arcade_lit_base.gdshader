shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float surface_roughness : hint_range(0.0, 1.0) = 0.72;
uniform vec4 rim_color : source_color = vec4(0.32, 0.78, 1.0, 1.0);
uniform float rim_intensity : hint_range(0.0, 1.0) = 0.12;
uniform float rim_power : hint_range(0.5, 8.0) = 3.0;

void fragment() {
	ALBEDO = base_color.rgb * COLOR.rgb;
	ALPHA = base_color.a * COLOR.a;
	ROUGHNESS = surface_roughness;
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - facing, rim_power) * rim_intensity;
	EMISSION = rim_color.rgb * rim;
}
