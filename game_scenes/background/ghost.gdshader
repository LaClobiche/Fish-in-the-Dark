shader_type canvas_item;

render_mode blend_mix;          // (la valeur par défaut mélange déjà l’alpha)

uniform bool  shaking      = false;
uniform float amplitude     = 1.0;
uniform float noise_scale   = 20.0;
uniform float noise_speed   = 20.0;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float saturation = 1.0;

float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453123);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  float a = hash(i + vec2(0.0,0.0));
  float b = hash(i + vec2(1.0,0.0));
  float c = hash(i + vec2(0.0,1.0));
  float d = hash(i + vec2(1.0,1.0));
  vec2 u = f*f*(3.0-2.0*f);
  return mix(a, b, u.x) +
  (c - a) * u.y * (1.0 - u.x) +
  (d - b) * u.x * u.y;
}

void fragment() {
    vec2  uv      = UV;
    vec4  tex_col = texture(TEXTURE, uv);

    if (tex_col.a <= 0.0) {
        discard;
    }

    if (shaking) {
        float nx  = noise(uv * noise_scale + vec2(TIME * noise_speed, 0.0));
        float ny  = noise(uv * noise_scale + vec2(0.0, TIME * noise_speed));
        vec2 dir  = normalize(vec2(nx * 2.0 - 1.0, ny * 2.0 - 1.0));

        float n   = noise(uv * noise_scale + vec2(TIME * noise_speed));
        float off = (n * 2.0 - 1.0) * amplitude;

        uv       += dir * off * TEXTURE_PIXEL_SIZE;
        tex_col   = texture(TEXTURE, uv);
    }

    /* ---------- Transparence globale ---------- */
    tex_col.a *= opacity;

    /* ---------- Sursaturation ---------- */
    // luminance perceptuelle (ITU‑R BT.601)
    float lum   = dot(tex_col.rgb, vec3(0.299, 0.587, 0.114));
    vec3  gray  = vec3(lum);

    // interpolation : 0 ⇒ gris, 1 ⇒ original, >1 ⇒ couleurs amplifiées
    tex_col.rgb = mix(gray, tex_col.rgb, saturation);

    // facultatif : éviter des débordements >1
    tex_col.rgb = clamp(tex_col.rgb, 0.0, 1.0);

    COLOR = tex_col;
}

