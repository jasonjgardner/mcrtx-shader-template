#ifndef __RENDERER_HLSL__
#define __RENDERER_HLSL__

#include "Generated/Signature.hlsl"
#include "Material.hlsl"

struct LightData
{
    float3 color;
    float intensity;
    bool isLarge;
};

LightData UnpackLight(uint packedData)
{
    LightData lightData;
    lightData.isLarge = (packedData >> 24) & 0x80;
    lightData.color = float3(
        (float)((packedData >> 24) & 0x7f) / 127.0,
        (float)((packedData >> 16) & 0xff) / 255.0,
        (float)((packedData >> 8) & 0xff) / 255.0);
    lightData.intensity = (float)((packedData >> 0) & 0xff) / 255.0;
    return lightData;
}

struct RayState
{
    RayDesc rayDesc;

    float3 color;
    float3 throughput;

    float distance;
    float3 motion;

    uint instanceMask; // 8 bits, see INSTANCE_MASK macros.

    void Init()
    {
        color = 0;
        throughput = 1;
        distance = 0;
        motion = 0;
        instanceMask = 0xff;
    }
};

void RenderSky(inout RayState rayState)
{
    if (all(rayState.throughput == 0)) return;

    const float3 skyColor = float3(170, 209, 254) / 255;
    const float3 gradientColor = float3(121, 167, 255) / 255;

    float lerpfactor = max(0.0, lerp(-0.15, 1.0, rayState.rayDesc.Direction.y));
    lerpfactor = pow(lerpfactor, 0.5);

    float3 color = lerp(skyColor, gradientColor, lerpfactor);
    rayState.color += rayState.throughput * color;
}

void RenderVanilla(HitInfo hitInfo, inout RayState rayState)
{
    ObjectInstance objectInstance = objectInstances[hitInfo.objectInstanceIndex];
    GeometryInfo geometryInfo = GetGeometryInfo(hitInfo, objectInstance);
    SurfaceInfo surfaceInfo = MaterialVanilla(hitInfo, geometryInfo, objectInstance);

    float3 worldPos = surfaceInfo.position - g_view.waveWorksOriginInSteveSpace;
    worldPos = worldPos - floor(worldPos / 1024) * 1024; // Bedrock may reset position every 1024 blocks, so we can only reliably calculate world position within 1024 blocks chunk.

    // Vanilla-like shading
    float3 light = lerp(
        lerp(0.6, 0.8, abs(dot(surfaceInfo.normal, float3(0, 0, 1)))),
        lerp(0.45, 1, mad(dot(surfaceInfo.normal, float3(0, 1, 0)), 0.5, 0.5)),
        abs(dot(surfaceInfo.normal, float3(0, 1, 0))));

    // Force alphatest and opaque materials to have full alpha.
    if (hitInfo.materialType == MATERIAL_TYPE_OPAQUE || hitInfo.materialType == MATERIAL_TYPE_ALPHA_TEST) surfaceInfo.alpha = 1;

    if (objectInstance.flags & kObjectInstanceFlagClouds)
    {
        light = geometryInfo.color.rgb; // Clouds have vanilla shading baked into vertex color.
        surfaceInfo.alpha = 0.7;        // Match vanilla clouds alpha
    }

    // Apply emissive lighting.
    light = lerp(light, 1, surfaceInfo.emissive);

    // Calculate point lights.
    for (int i = 0; i < min(10, g_view.cpuLightsCount); i++)
    {
        LightInfo lightInfo = inputLightsBuffer[i];
        LightData lightData = UnpackLight(lightInfo.packedData);

        float3 lDir = lightInfo.position - surfaceInfo.position;
        float lDist = length(lDir);
        lDir /= lDist;

        float attenuation = max(0, dot(surfaceInfo.normal, lDir)) / (lDist * lDist);
        light += 100 * attenuation * lightData.intensity * lightData.color;
    }

    float3 throughput;
    float3 emission;
    if (objectInstance.flags & (kObjectInstanceFlagSun | kObjectInstanceFlagMoon))
    {
        // Use additive blending for sun and moon
        throughput = 1;
        emission = surfaceInfo.color * ((objectInstance.flags & kObjectInstanceFlagSun ? g_view.sunMeshIntensity : g_view.moonMeshIntensity) * surfaceInfo.alpha);
    }
    else
    {
        // Use alphablend for everything else
        throughput = 1 - surfaceInfo.alpha;
        emission = surfaceInfo.color * surfaceInfo.alpha * light;
    }

    // Glint
    if (objectInstance.flags & kObjectInstanceFlagGlint)
        emission += (sin(3.0 * g_view.time) * 0.5 + 0.5) * (float3(077, 23, 255) / 255.0);

    uint mediaType = objectInstance.offsetPack5 >> 8; // See MEDIA_TYPE macros.

    // Advance ray forward
    rayState.rayDesc.TMin = hitInfo.rayT;

    // Accumulate surface emission and throughput
    rayState.color += emission * rayState.throughput;
    rayState.throughput *= throughput;

    // Update other ray properties
    rayState.distance = hitInfo.rayT;
    rayState.motion = surfaceInfo.position - surfaceInfo.prevPosition;
}

// Set to false by default
#ifndef CULL_GLASS_BACK_FACES
#define CULL_GLASS_BACK_FACES 0
#endif

bool AlphaTestHitLogic(HitInfo hitInfo)
{
#if CULL_GLASS_BACK_FACES
    if (hitInfo.materialType == MATERIAL_TYPE_ALPHA_BLEND && !hitInfo.frontFacing)
        return false;
#endif
    // If this logic runs for non-alphatested things, always register a hit.
    if (hitInfo.materialType != MATERIAL_TYPE_ALPHA_TEST)
        return true;

    // Tip: instead of calculating material every time, you can calculate UVs during CalculateFaceData pass and cache them in faceUvBuffers.
    // Then during alpha testing, cached UVs can be used to sample texture(s) instead of using expensive material and geometry computations.
    ObjectInstance obj = objectInstances[hitInfo.objectInstanceIndex];
    GeometryInfo geometryInfo = GetGeometryInfo(hitInfo, obj);
    SurfaceInfo surfaceInfo = MaterialVanilla(hitInfo, geometryInfo, obj);

    return !surfaceInfo.shouldDiscard;
}

float3 RenderRay(RayDesc rayDesc, out float outputDistance, out float3 outputMotion)
{
    RayQuery<RAY_FLAG_NONE> q;

    RayState rayState;
    rayState.Init();
    rayState.rayDesc = rayDesc;

    // Limit to 100 overlapping translucent surfaces.
    for (int i = 0; i < 100; i++)
    {
        q.TraceRayInline(SceneBVH, RAY_FLAG_SKIP_PROCEDURAL_PRIMITIVES, rayState.instanceMask, rayState.rayDesc);
        while (q.Proceed())
        {
            HitInfo hitInfo = GetCandidateHitInfo(q);
            if (AlphaTestHitLogic(hitInfo))
            {
                q.CommitNonOpaqueTriangleHit();
            }
        }

        if (q.CommittedStatus() == COMMITTED_TRIANGLE_HIT)
        {
            HitInfo hitInfo = GetCommittedHitInfo(q);
            RenderVanilla(hitInfo, rayState);
        }
        else
        {
            break;
        }

        // Terminate rays that can't contribute anymore.
        if (all(rayState.throughput == 0))
            break;
    }

    const float maxDistance = 65504; // Maximum value depth buffer can contain.
    if (all(rayState.throughput == 0)) {
        // Eventually hit solid object
        outputDistance = min(rayState.distance, maxDistance);
        outputMotion = rayState.motion;
    } else {
        // Eventually hit sky
        outputDistance = maxDistance;
        outputMotion = 0;
    }

    RenderSky(rayState);
    return rayState.color;
}

#endif