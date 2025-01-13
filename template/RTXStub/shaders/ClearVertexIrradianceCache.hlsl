#include "Include/Generated/Signature.hlsl"

[numthreads({{RTXStub.passes.ClearVertexIrradianceCache.group_size}})]
void ClearVertexIrradianceCache(
    uint3 dispatchThreadID : SV_DispatchThreadID,
    uint3 groupThreadID : SV_GroupThreadID,
    uint groupIndex : SV_GroupIndex, 
    uint3 groupID : SV_GroupID
    )
{
    uint vertexBufferIndex = g_rootConstant0 & 0xfff; // equal to ObjectInstance.vbIdx
    uint numOfVertices = g_rootConstant0 >> 12;
    uint firstVertexOffset = g_rootConstant1;
    uint vertexId = dispatchThreadID.x;

    if(vertexId >= numOfVertices) return;
    vertexId += firstVertexOffset;
}