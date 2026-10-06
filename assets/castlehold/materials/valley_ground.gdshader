shader_type spatial;
render_mode diffuse_burley;

// World-space color keeps the valley seamless while the road bends through it.
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float footprint = max(length(dFdx(world.xz)), length(dFdy(world.xz)));
	float fine_visibility = 1.0 - smoothstep(0.035, 0.12, footprint);
	float broad = noise(world.xz * 0.105);
	float meadow = noise(world.xz * 0.43);
	float detail = mix(0.5, noise(world.xz * 3.0), fine_visibility);
	float breakup = noise(world.xz * 0.74);

	vec3 grass = mix(vec3(0.115, 0.195, 0.095), vec3(0.27, 0.34, 0.145),
		clamp(broad * 0.51 + meadow * 0.36 + detail * 0.13, 0.0, 1.0));
	float brush = smoothstep(0.49, 0.76, meadow) * (0.28 + broad * 0.19);
	grass = mix(grass, vec3(0.24, 0.25, 0.11), brush);

	float bend = sin(world.x * 0.075) * 0.48 + sin(world.x * 0.18) * 0.14;
	float from_road = abs(world.z - bend);
	float ragged_edge = (breakup - 0.5) * 0.84 + (broad - 0.5) * 0.4;
	float road = 1.0 - smoothstep(2.23, 3.18, from_road + ragged_edge);
	float verge = 1.0 - smoothstep(3.1, 4.8, from_road + ragged_edge);
	vec3 soil = mix(vec3(0.29, 0.21, 0.13), vec3(0.47, 0.35, 0.22),
		broad * 0.52 + meadow * 0.48);
	grass = mix(grass, vec3(0.26, 0.265, 0.13), max(0.0, verge - road) * 0.42);

	// Broken, wandering wheel impressions replace long rectangular rut meshes.
	float rut_wear = 1.0 - smoothstep(0.11, 0.34,
		abs(from_road - 1.39 + 0.10 * sin(world.x * 0.31)));
	float interrupted = smoothstep(0.30, 0.63, noise(vec2(world.x * 0.34, world.z * 0.72)));
	soil *= 1.0 - rut_wear * interrupted * road * 0.20;
	float tracks = 1.0 - smoothstep(0.04, 0.16, abs(fract(world.x * 2.15) - 0.5));
	soil *= 1.0 - tracks * rut_wear * interrupted * road * 0.08 * fine_visibility;

	// Contact dirt follows BOTH fortresses, with a light trampled midfield.
	float fort_distance = min(abs(world.x + 54.0), abs(world.x - 54.0));
	float castle_foot = (1.0 - smoothstep(6.5, 13.5, fort_distance)) *
		(1.0 - smoothstep(5.0, 9.0, abs(world.z)));
	float battlefield = (1.0 - smoothstep(13.0, 24.0, abs(world.x))) *
		(1.0 - smoothstep(3.0, 7.0, abs(world.z))) * (0.3 + 0.4 * broad);
	vec3 color = mix(grass, soil, road);
	color = mix(color, vec3(0.19, 0.20, 0.12), castle_foot * 0.28 + battlefield * 0.10);
	color *= 0.96 + (detail - 0.5) * 0.12 * fine_visibility;
	ALBEDO = color;
	AO = 1.0 - castle_foot * 0.12;
	ROUGHNESS = 0.96;
}
