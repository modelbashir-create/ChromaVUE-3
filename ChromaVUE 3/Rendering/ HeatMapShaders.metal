// Rendering/HeatMapShaders.metal
#include <metal_stdlib>
using namespace metal;

// Map scalar value [0, 1] to RGBA color (0–1 floats).
inline float4 heatmapColor(float v) {
    v = clamp(v, 0.0f, 1.0f);

    float r, g, b;

    if (v < 0.25f) {
        // blue -> cyan
        float t = v / 0.25f;
        r = 0.0f;
        g = t;
        b = 1.0f;
    } else if (v < 0.5f) {
        // cyan -> green
        float t = (v - 0.25f) / 0.25f;
        r = 0.0f;
        g = 1.0f;
        b = 1.0f - t;
    } else if (v < 0.75f) {
        // green -> yellow
        float t = (v - 0.5f) / 0.25f;
        r = t;
        g = 1.0f;
        b = 0.0f;
    } else {
        // yellow -> red
        float t = (v - 0.75f) / 0.25f;
        r = 1.0f;
        g = 1.0f - t;
        b = 0.0f;
    }

    return float4(r, g, b, 1.0f);
}

// Compute kernel:
//  - input: scalarTex (r32Float), index 0
//  - output: colorTex (rgba8Unorm), index 1
kernel void heatmapKernel(
    texture2d<float, access::read>  scalarTex [[texture(0)]],
    texture2d<float, access::write> colorTex  [[texture(1)]],
    uint2 gid [[thread_position_in_grid]]
) {
    if (gid.x >= colorTex.get_width() || gid.y >= colorTex.get_height()) {
        return;
    }

    float s = scalarTex.read(gid).r;   // scalar value
    float4 c = heatmapColor(s);
    colorTex.write(c, gid);
}