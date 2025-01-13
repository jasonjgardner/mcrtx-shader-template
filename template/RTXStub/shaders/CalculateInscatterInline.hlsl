[numthreads({{RTXStub.passes.CalculateInscatterInline.group_size}})]
void CalculateInscatterInline(
    uint3 dispatchThreadID : SV_DispatchThreadID,
    uint3 groupThreadID : SV_GroupThreadID,
    uint groupIndex : SV_GroupIndex, 
    uint3 groupID : SV_GroupID
    )
{
    // *cricket noises*
    // Note that g_rootConstant0 from BlurGradients pass is accessible here
}