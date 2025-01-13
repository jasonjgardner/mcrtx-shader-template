#include "Include/Generated/Signature.hlsl"

[numthreads({{RTXStub.passes.FinalizeDenoising.group_size}})]
void FinalizeDenoising(
    uint3 dispatchThreadID : SV_DispatchThreadID,
    uint3 groupThreadID : SV_GroupThreadID,
    uint groupIndex : SV_GroupIndex, 
    uint3 groupID : SV_GroupID
    )
{
    // Use these for indexing shadowDenoisingInputs[] or shadowDenoisingOutputs[] arrays
    uint shadowDenoisingInputBufferIndex = (g_rootConstant0 >> 8) & 0xff;
    uint shadowDenoisingOutputBufferIndex = (g_rootConstant0 >> 16) & 0xff;
}