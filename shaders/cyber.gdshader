shader_type canvas_item;

uniform vec4 color : source_color = vec4(.4, 1.0, .6, 1.0);
uniform float min_alpha = .5;
uniform float period = .2;
uniform float speed = .3;

float hash(vec2 st)
{
    return fract(sin(dot(st.xy,
                         vec2(12.9898,78.233)))*
        43758.5453123);
}

void fragment() {
	vec4 final_color = vec4(0.0);
	
	vec2 uv = UV;
	
	float stripe = mod(uv.y - TIME * speed, period) / period;
	
	vec4 sample = texture(TEXTURE, uv + vec2(sin(TIME * 20.0) * hash(vec2(TIME, 0)) * stripe * stripe * 2.0, 0.0) * SCREEN_PIXEL_SIZE);
	
	if (sample.a > 0.0) {
		final_color = color;
		final_color.a = min(sample.a, stripe + min_alpha);
	}
	
	COLOR = final_color;
}
