#include "Include/Generated/Signature.hlsl"

[numthreads(64, 1, 1)]
void PreBlasSkinning(
    uint3 dispatchThreadID : SV_DispatchThreadID,
    uint3 groupThreadID : SV_GroupThreadID,
    uint groupIndex : SV_GroupIndex, 
    uint3 groupID : SV_GroupID
    )
{
    // Below is a basic implementation of skinning, which is necessary to animate geometry as well as to propagate previous position for motion vectors.

    // TODO: explore caching vertex data in array so that we separate buffer reads and writes; 
    // and explore increasing buffer load/store transaction size (e.g. uint4) so that we operate on larger chunks of data.  
    if (dispatchThreadID.x >= g_meshSkinningData.vertexCount) return;

    RWByteAddressBuffer sourceBuffer = vertexBuffersRW[g_meshSkinningData.sourceVBIndex];
    RWByteAddressBuffer destBuffer = vertexBuffersRW[g_meshSkinningData.destVBIndex];

    uint addressFrom = dispatchThreadID.x * g_meshSkinningData.sizeOfVertex + g_meshSkinningData.sourceVBOffset;
    uint addressTo = dispatchThreadID.x * g_meshSkinningData.sizeOfVertex + g_meshSkinningData.destVBOffset;

    float16_t4 prevPos;
    if (g_meshSkinningData.offsetToPrevPos != 0xFFFFFFFF) {
        prevPos = destBuffer.Load<float16_t4>(addressTo + g_meshSkinningData.offsetToPosition); // TODO: do we use addressTo or subtract destVBOffset?
    }

    for (uint i=0; i < g_meshSkinningData.sizeOfVertex; i+=4) destBuffer.Store(addressTo+i, sourceBuffer.Load(addressFrom+i));

    if (g_meshSkinningData.offsetToPrevPos != 0xFFFFFFFF) {
        destBuffer.Store<float16_t4>(addressTo + g_meshSkinningData.offsetToPrevPos, prevPos);
    }
    
    uint boneIndex = sourceBuffer.Load<uint16_t>(addressFrom + g_meshSkinningData.offsetToBoneIndex);
    if (boneIndex > 7) return; // We only have 8 bones.
    
    float4x4 bone = g_meshSkinningData.bones[boneIndex];

    float16_t4 pos = sourceBuffer.Load<float16_t4>(addressFrom + g_meshSkinningData.offsetToPosition);
    pos = (float16_t4)mul(bone, pos);
    destBuffer.Store<float16_t4>(addressTo + g_meshSkinningData.offsetToPosition, pos);

    uint normalPacked = sourceBuffer.Load<uint>(addressFrom + g_meshSkinningData.offsetToNormal);
    float4 normal = float4((int)((normalPacked << 8*3) & 0xff000000) >> 24, (int)((normalPacked << 8*2) & 0xff000000) >> 24, (int)((normalPacked << 8*1) & 0xff000000) >> 24, (int)((normalPacked << 8*0) & 0xff000000) >> 24) / 127.0;
    normal = mul(bone, normal);
    normal.xyz = normalize(normal.xyz);
    int4 normalInt = int4(round(normal*127));
    normalPacked = ((uint)(normalInt.x << 24) >> 8*3) | ((uint)(normalInt.y << 24) >> 8*2) | ((uint)(normalInt.z << 24) >> 8*1) | ((uint)(normalInt.w << 24) >> 8*0);
    destBuffer.Store(addressTo + g_meshSkinningData.offsetToNormal, normalPacked);
}