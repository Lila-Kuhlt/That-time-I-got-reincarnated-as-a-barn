shader_type canvas_item;
render_mode unshaded;

uniform sampler2D frames: hint_albedo;
uniform float count;
uniform float duration;

void fragment() {
    float frame = floor(mod(TIME, count * duration) / duration);
    COLOR = texture(frames, UV + vec2(frame / count, 0));
}