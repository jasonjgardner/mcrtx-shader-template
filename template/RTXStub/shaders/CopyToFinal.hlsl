#include "Include/Generated/Signature.hlsl"

[numthreads({{RTXStub.passes.CopyToFinal.group_size}})]
void CopyToFinal(
    uint3 dispatchThreadID : SV_DispatchThreadID,
    uint3 groupThreadID : SV_GroupThreadID,
    uint groupIndex : SV_GroupIndex, 
    uint3 groupID : SV_GroupID
    )
{
    // *cricket noises*
    // Note that g_rootConstant0 from FinalCombine pass is accessible here

    if (any(dispatchThreadID.xy >= g_view.displayResolution)) return;

    bool enabledUpscaling = !g_view.enableTAA && g_view.renderResolution.x < g_view.displayResolution.x;
    if (enabledUpscaling) {
        // Pick up upscaled results from inputThisFrameTAAHistory
        float4 upscaledColor = inputThisFrameTAAHistory[dispatchThreadID.xy];
        outputBufferFinal[dispatchThreadID.xy] = upscaledColor;
    } 
}