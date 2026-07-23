shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float pixel_size : hint_range(0.0, 20.0, 1.0);
uniform float levels : hint_range(0.0, 100.0, 1.0);
uniform vec2 gamma;
// replaced this to respect alpha ontop of just tint
uniform vec4 tint : source_color = vec4(1.0, 1.0, 1.0, 0.0);

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 tex_size = vec2(textureSize(screen_texture, 0));
	
	float safe_pixel_size = max(pixel_size, 0.5); 
	vec2 pixel_count = tex_size / (safe_pixel_size * 2.0);
	
	vec2 pixelated_uv = floor(SCREEN_UV * pixel_count) / pixel_count;

	vec2 half_block = 0.5 / pixel_count;
	pixelated_uv = clamp(pixelated_uv, half_block, 1.0 - half_block);
	
	vec4 color = texture(screen_texture, pixelated_uv);
	
	color.rgb = pow(color.rgb, vec3(gamma.x));
	
	float grayscale = max(color.r, max(color.g, color.b));
	grayscale = max(grayscale, 0.0001); // Prevent division by zero later
	
	float lower = floor(grayscale * levels) / levels;
	float higher = ceil(grayscale * levels) / levels;
	
	float lower_diff = abs(lower - grayscale);
	float higher_diff = abs(higher - grayscale);
	
	float level = lower_diff < higher_diff ? lower : higher;
	float adjustment = level / grayscale;
	
	color.rgb *= adjustment;
	color.rgb = pow(color.rgb, vec3(gamma.y));
	
	ALBEDO = mix(color.rgb, color.rgb * tint.rgb, tint.a);
	ALPHA = color.a;
}