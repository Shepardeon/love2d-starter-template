extern number saturation;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 _)
{
    vec4 pixel = Texel(texture, uv);
    vec4 result;
    result.rgb = mix(vec3(dot(pixel.rgb, vec3(0.299, 0.587, 0.114))), pixel.rgb, saturation);
    result.a = pixel.a;

    return result;
}