// If enabled, will match vanilla graphics and cull transparent back faces. Refer to Renderer.hlsl to see what it does.
#define CULL_GLASS_BACK_FACES 1

#include "Include/Renderer.hlsl"

[numthreads(4, 8, 1)]
void PrimaryCheckerboardRayGenInline(
    uint3 dispatchThreadID: SV_DispatchThreadID,
    uint3 groupThreadID: SV_GroupThreadID,
    uint groupIndex: SV_GroupIndex,
    uint3 groupID: SV_GroupID)
{
    // *cricket noises*
    // Note that g_rootConstant0 from AdaptiveDenoiserCalculateGradients pass is accessible here
    

    // Below is an implementation of a basic ray traced vanilla-like shader.
    if (any(dispatchThreadID.xy >= g_view.renderResolution)) return;

    bool enabledUpscaling = !g_view.enableTAA && g_view.renderResolution.x < g_view.displayResolution.x;

    float2 UV = g_view.recipRenderResolution * (dispatchThreadID.xy + 0.5 + (enabledUpscaling ? g_view.subPixelJitter : 0));
    UV = 2 * UV - 1;
    UV.y *= -1;

    RayDesc rayDesc;
    rayDesc.Origin = g_view.viewOriginSteveSpace;
    rayDesc.TMin = 0;
    rayDesc.TMax = 10000;

    float4 steveSpacePos = mul(float4(UV, 0.5, 1), g_view.invViewProj);
    steveSpacePos.xyz /= steveSpacePos.w;
    float3 rayDir = normalize(steveSpacePos.xyz - g_view.viewOriginSteveSpace);
    rayDesc.Direction = rayDir;

    float dist = 0;
    float3 motion = 0;
    float3 color = RenderRay(rayDesc, dist, motion);

    float3 pos = g_view.viewOriginSteveSpace + dist * rayDir;
    float3 prevPos = pos - motion;

    float4 projPos = mul(float4(pos, 1), g_view.viewProj);
    float4 prevProjPos = mul(float4(prevPos, 1), g_view.prevViewProj);

    float2 ndcPos = projPos.xy / projPos.w;
    float2 prevNdcPos = prevProjPos.xy / prevProjPos.w;

    float2 motionVector = (prevNdcPos - ndcPos) * float2(0.5, -0.5);

    // Basic debug views for NaNs and Infinity
    #if 1
    if (any(isinf(color)) || any(isinf(motionVector)) || isinf(dist))
        color = (dispatchThreadID.x / 32 + dispatchThreadID.y / 32) & 1 ? float3(1, 1, 0) : 0;
    if (any(isnan(color)) || any(isnan(motionVector)) || isnan(dist))
        color = (dispatchThreadID.x / 32 + dispatchThreadID.y / 32) & 1 ? float3(1, 0, 1) : 0;
    #endif

    // The only 3 buffers necessary for upscaling (e.g. DLSS)
    outputBufferFinal[dispatchThreadID.xy] = float4(color, 1);
    outputBufferMotionVectors[dispatchThreadID.xy] = motionVector;
    outputBufferReprojectedPathLength[dispatchThreadID.xy] = dist;
}
