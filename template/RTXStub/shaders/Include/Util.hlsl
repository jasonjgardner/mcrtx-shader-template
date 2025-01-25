#ifndef __UTIL_HLSL__
#define __UTIL_HLSL__

#include "Generated/Signature.hlsl"

float2 computeMotionVector(float3 steveSpacePositon, float3 steveSpaceMotion) {
    float4 clipPos = mul(float4(steveSpacePositon, 1), g_view.viewProj);
    float2 ndcPos = clipPos.xy / clipPos.w;

    float3 prevHitPos = steveSpacePositon - steveSpaceMotion;
    float4 prevClipPos = mul(float4(prevHitPos, 1), g_view.prevViewProj);
    float2 prevNdcPos = prevClipPos.xy / prevClipPos.w;

    return (prevNdcPos - ndcPos) * float2(0.5, -0.5); // Offset in UV space.
}

float3 rayDirFromNDC(float2 ndc) {
    // Note: as far as I can tell, view origin is always 0, hence it's not necessary to subtract it or even 
    // divide resulting vector by W. But I'm keeping the code here in case view origin becomes something else in the future.
    const float NDC_Z_Offset = 0.5;
    #if 0
    // Slightly faster but less precise.
    float3 rayDir = mad(ndc.x, g_view.posNdcToDirection[0].xyz, g_view.posNdcToDirection[2].xyz);
    rayDir = mad(ndc.y, g_view.posNdcToDirection[1].xyz, rayDir);
    return normalize(rayDir/mad(g_view.invViewProj._m23, NDC_Z_Offset, g_view.invViewProj._m33) - g_view.viewOriginSteveSpace);
    #else
    float4 steveSpacePos = mul(float4(ndc, NDC_Z_Offset, 1), g_view.invViewProj);
    steveSpacePos.xyz /= steveSpacePos.w;
    return normalize(steveSpacePos.xyz - g_view.viewOriginSteveSpace);
    #endif
}

// Returns true both for upscaling (e.g. DLSS) and anti-aliasing (e.g. DLAA)
bool isUpscalingEnabled() {
    return !g_view.enableTAA;
}

float2 getNDCjittered(uint2 pixelCoord) {
    float2 ndc = g_view.recipRenderResolution * (pixelCoord + 0.5 + (isUpscalingEnabled() ? g_view.subPixelJitter : 0));
    return mad(ndc, float2(2, -2), float2(-1, 1));
}

float4 unpackNormal(uint packedNormal) {
    return float4(
        (int)((packedNormal << 8*3) & 0xff000000) >> 24, 
        (int)((packedNormal << 8*2) & 0xff000000) >> 24, 
        (int)((packedNormal << 8*1) & 0xff000000) >> 24, 
        (int)((packedNormal << 8*0) & 0xff000000) >> 24
    ) / 127.0;
}

uint packNormal(float4 normal) {
    int4 normalInt = int4(round(normal*127));
    return (
        ((uint)(normalInt.x << 24) >> 8*3) | 
        ((uint)(normalInt.y << 24) >> 8*2) | 
        ((uint)(normalInt.z << 24) >> 8*1) | 
        ((uint)(normalInt.w << 24) >> 8*0)
    );
}

float4 unpackVertexColor(uint packedColor) {
    return float4(
        (packedColor >> 8 * 0) & 0xff, 
        (packedColor >> 8 * 1) & 0xff, 
        (packedColor >> 8 * 2) & 0xff, 
        (packedColor >> 8 * 3) & 0xff
    ) / 255.0;
}

float4 unpackObjectInstanceTintColor(uint packedColor) {
    return float4(
        (packedColor >> 8 * 3) & 0xff, 
        (packedColor >> 8 * 2) & 0xff, 
        (packedColor >> 8 * 1) & 0xff, 
        (packedColor >> 8 * 0) & 0xff
    ) / 255.0;
}

float2 unpackVertexUV(uint packedUV) {
    float2 uv = float2(packedUV & 0xffff, packedUV >> 16) * (1. / 0xffff);
    // Quantize UVs according to max possible atlas size (32k on NVidia), fixes visible texture seams on certain objects.
    uv = round(uv*32768)/32768.0;
    return uv;
}

#endif