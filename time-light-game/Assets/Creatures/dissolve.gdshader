shader_type spatial;
//render_mode unshaded;

// dissolve stays off during normal play so the monster shows its real skin,
// the ai flips enabled on when it dies and tweens t from 0 to 1
uniform bool enabled = false;
uniform float t = 0.0;
uniform sampler2D albedo_tex : source_color;
uniform vec3 albedo_and_emissive_color : source_color = vec3(1.0);
uniform sampler2D noise_tex;
uniform float noise_scale = 1.0;

void fragment() {
	if (!enabled) {
		// off, just draw the normal monster texture and let it light normally
		ALBEDO = texture(albedo_tex, UV).rgb;
	} else {
		// on, eat away the pixels as t climbs and glow the edge color
		float noise = texture(noise_tex, UV * noise_scale).r;
		if (step(t, noise) < 1.0) { discard; }
		ALBEDO = albedo_and_emissive_color;
		EMISSION = albedo_and_emissive_color;
	}
}
