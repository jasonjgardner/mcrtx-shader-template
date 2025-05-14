/* MIT License
 * 
 * Copyright (c) 2025 veka0
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#ifndef __SIGNATURE_HLSL__
#define __SIGNATURE_HLSL__

#include "Structs.hlsl"

// The contents of this file were partially generated using process_signature.py
// while manually filling in uninitialized or missing buffers.

// Buffer types and resolutions were manually added from a PIX capture (see Debug.hlsl)

// Note that float3 buffers are often stored as float4
// so you can change their type to get an extra channel for storage.

// For the most part, every single buffer here is accessible in every single pass.
// The only exception is PreBlasSkinningCB buffer which is only accessible in PreBlasSkinning pass
// and that same pass only has access to PreBlasSkinningCB and a single descriptor table
// with the following buffers: indexBuffers, vertexBuffers, faceDataBuffers, faceUvBuffers, 
// vertexIrradianceCache, faceIrradianceCache, faceDataBuffersRW, faceUvBuffersRW, vertexBuffersRW

// 32BIT_CONSTANTS
{{RTXStub.buffers.b2_space0}}

// CBV
{{RTXStub.buffers.b0_space99}}

// DESCRIPTOR_TABLE [13]
// CBV[1]
{{RTXStub.buffers.b0_space0}}

// CBV[1]
{{RTXStub.buffers.b3_space0}}

// Buffer resolution legend:
// DISPLAY - game window resolution
// RENDER - internal rendering resolution (equal to DISPLAY if upscaling is disabled)
// DENOISER, 1px = 4x4 RENDER pixels
// TILE, 1px = 16x16 RENDER pixels

// UAV[46]
{{RTXStub.buffers.u0_space0}} // R32_FLOAT RENDER
{{RTXStub.buffers.u1_space0}} // R16G16_SNORM RENDER
{{RTXStub.buffers.u2_space0}} // R8G8_UNORM RENDER
{{RTXStub.buffers.u3_space0}} // R8G8B8A8_UNORM RENDER
{{RTXStub.buffers.u4_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u5_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u6_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u7_space0}} // R8G8_UNORM RENDER
// Uninitialized // {{RTXStub.buffers.u8_space0}}
// Uninitialized // {{RTXStub.buffers.u9_space0}}
{{RTXStub.buffers.u10_space0}} // R16G16_FLOAT RENDER
{{RTXStub.buffers.u11_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u12_space0}} // R16G16B16A16_FLOAT DISPLAY
RWTexture2D<float3> outputBufferDirectLightTransmission : register(u13); // {{RTXStub.buffers.u13_space0}} // R8G8B8A8_UNORM RENDER
{{RTXStub.buffers.u14_space0}} // R8G8B8A8_UNORM RENDER
{{RTXStub.buffers.u15_space0}} // R16_FLOAT RENDER
{{RTXStub.buffers.u16_space0}} // R16G16_FLOAT RENDER
{{RTXStub.buffers.u17_space0}} // R8_UNORM RENDER
{{RTXStub.buffers.u18_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u19_space0}} // R32_UINT RENDER
{{RTXStub.buffers.u20_space0}} // R32_FLOAT RENDER
{{RTXStub.buffers.u21_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u22_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u23_space0}} // R32G32B32A32_FLOAT RENDER
RWTexture2D<float4> outputBufferRayDirection : register(u24); // {{RTXStub.buffers.u24_space0}} // R16G16B16A16_FLOAT RENDER
RWTexture2D<float3> outputBufferRayThroughput : register(u25); // {{RTXStub.buffers.u25_space0}} // R11G11B10_FLOAT RENDER
{{RTXStub.buffers.u26_space0}} // R32_UINT 256⨯1
{{RTXStub.buffers.u27_space0}} // R32_FLOAT 256⨯1
{{RTXStub.buffers.u28_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u29_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u30_space0}} // R16G16B16A16_FLOAT DISPLAY
{{RTXStub.buffers.u31_space0}} // R8G8_SNORM RENDER
{{RTXStub.buffers.u32_space0}} // 32768
{{RTXStub.buffers.u33_space0}} // R32G32B32A32_FLOAT RENDER
{{RTXStub.buffers.u34_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u35_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u36_space0}} // R16G16_FLOAT DENOISER
// outputAdaptiveDenoiserGradients #1 // {{RTXStub.buffers.u37_space0}} // R16G16_FLOAT DENOISER
{{RTXStub.buffers.u38_space0}} // R16G16_FLOAT DENOISER
{{RTXStub.buffers.u39_space0}} // R32_UINT DENOISER
{{RTXStub.buffers.u40_space0}} // R16G16_FLOAT RENDER
RWTexture2D<float2> outputFinalDiffuseMoments : register(u41); // {{RTXStub.buffers.u41_space0}} // R16G16_FLOAT RENDER
{{RTXStub.buffers.u42_space0}} // R16G16_FLOAT RENDER
RWTexture2D<float2> outputFinalSpecularMoments : register(u43);  // {{RTXStub.buffers.u43_space0}} // R16G16_FLOAT RENDER
{{RTXStub.buffers.u44_space0}} // R32_UINT TILE
{{RTXStub.buffers.u45_space0}} // R32_UINT RENDER

// SRV[64]
{{RTXStub.buffers.t0_space0}}
{{RTXStub.buffers.t1_space0}} // 16384
{{RTXStub.buffers.t2_space0}} // 2048
{{RTXStub.buffers.t3_space0}} // 2048
{{RTXStub.buffers.t4_space0}} // R32_FLOAT RENDER
{{RTXStub.buffers.t5_space0}} // R16G16_SNORM RENDER
{{RTXStub.buffers.t6_space0}} // R8G8_UNORM RENDER
{{RTXStub.buffers.t7_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.t8_space0}} // R16G16B16A16_FLOAT RENDER
Texture2D<float2> inputBufferOrFinalDiffuseMoments : register(t9); // {{RTXStub.buffers.t9_space0}} // R16G16_FLOAT RENDER
Texture2D<float2> inputBufferOrFinalSpecularMoments : register(t10); // {{RTXStub.buffers.t10_space0}} // R16G16_FLOAT RENDER
{{RTXStub.buffers.t11_space0}} // R16G16B16A16_FLOAT 256⨯128x64
{{RTXStub.buffers.t12_space0}} // R16G16B16A16_FLOAT 256⨯128x64
{{RTXStub.buffers.t13_space0}} // R16G16B16A16_FLOAT 256⨯128x64
{{RTXStub.buffers.t14_space0}} // R32_FLOAT RENDER
{{RTXStub.buffers.t15_space0}} // R16G16_SNORM RENDER
{{RTXStub.buffers.t16_space0}} // R8G8B8A8_UNORM RENDER
{{RTXStub.buffers.t17_space0}} // R8G8_UNORM RENDER
{{RTXStub.buffers.t18_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.t19_space0}} // 515
Texture2D<float3> inputDirectLightTransmission : register(t20); // {{RTXStub.buffers.t20_space0}} // R8G8B8A8_UNORM RENDER
{{RTXStub.buffers.t21_space0}} // R16G16_FLOAT RENDER
{{RTXStub.buffers.t22_space0}} // R16G16_FLOAT RENDER
{{RTXStub.buffers.t23_space0}} // R16_FLOAT RENDER
{{RTXStub.buffers.t24_space0}} // R8_UNORM RENDER
{{RTXStub.buffers.t25_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.t26_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.t27_space0}} // R32_UINT RENDER
// Uninitialized // {{RTXStub.buffers.t28_space0}}
{{RTXStub.buffers.t29_space0}} // R32_FLOAT RENDER
{{RTXStub.buffers.t30_space0}} // R16G16B16A16_FLOAT RENDER
Texture2D<float4> referencePathTracerBuffer : register(t31); // {{RTXStub.buffers.t31_space0}} // R32G32B32A32_FLOAT RENDER
// Uninitialized // {{RTXStub.buffers.t32_space0}}
// Uninitialized // {{RTXStub.buffers.t33_space0}}
// Uninitialized // {{RTXStub.buffers.t34_space0}}
{{RTXStub.buffers.t35_space0}} // 12288
Texture2D<uint> inputBufferToneMappingHistogram : register(t36); // {{RTXStub.buffers.t36_space0}} // R32_UINT 256⨯1
Texture2D<float> inputBufferToneCurve : register(t37); // {{RTXStub.buffers.t37_space0}} // R32_FLOAT 256⨯1
{{RTXStub.buffers.t38_space0}} // R16G16B16A16_FLOAT 128⨯64x32
{{RTXStub.buffers.t39_space0}} // R16G16B16A16_FLOAT 128⨯64x32
{{RTXStub.buffers.t40_space0}} // R16G16B16A16_FLOAT DISPLAY
{{RTXStub.buffers.t41_space0}} // R16G16B16A16_FLOAT DISPLAY
{{RTXStub.buffers.t42_space0}} // R16G16B16A16_FLOAT DISPLAY
{{RTXStub.buffers.t43_space0}} // R8G8_SNORM RENDER
{{RTXStub.buffers.t44_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.t45_space0}} // R32G32B32A32_FLOAT RENDER
{{RTXStub.buffers.t46_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.t47_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.t48_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.t49_space0}} // R8G8_SNORM RENDER
{{RTXStub.buffers.t50_space0}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.t51_space0}} // R16G16_FLOAT DENOISER
// inputAdaptiveDenoiserGradients #1 // {{RTXStub.buffers.t52_space0}} // R16G16_FLOAT DENOISER
{{RTXStub.buffers.t53_space0}} // R16G16_FLOAT DENOISER
{{RTXStub.buffers.t54_space0}} // R32_UINT DENOISER
{{RTXStub.buffers.t55_space0}} // 20
{{RTXStub.buffers.t56_space0}} // 5
{{RTXStub.buffers.t57_space0}} // R32_UINT TILE
{{RTXStub.buffers.t58_space0}} // R16G16B16A16_UNORM 256⨯256[128]
{{RTXStub.buffers.t59_space0}} // R8G8B8A8_UNORM 64⨯32[8]
{{RTXStub.buffers.t60_space0}} // R8_UNORM 256⨯256[64]
{{RTXStub.buffers.t61_space0}} // R8G8B8A8_UNORM 128⨯128
{{RTXStub.buffers.t62_space0}} // R8G8B8A8_UNORM 256⨯256
{{RTXStub.buffers.t63_space0}} // R32_UINT RENDER

// UAV[1]
{{RTXStub.buffers.u0_space14}} // 515

// UAV[6]
{{RTXStub.buffers.u60_space0}} // R16G16B16A16_FLOAT 256⨯128x64
{{RTXStub.buffers.u61_space0}} // R16G16B16A16_FLOAT 256⨯128x64
{{RTXStub.buffers.u62_space0}} // R16G16B16A16_FLOAT 256⨯128x64
{{RTXStub.buffers.u63_space0}} // R16G16B16A16_FLOAT 128⨯64x32
{{RTXStub.buffers.u64_space0}} // R16G16B16A16_FLOAT 128⨯64x32
// volumetricGIInscatterRW #1 // {{RTXStub.buffers.u65_space0}} // R16G16B16A16_FLOAT 128⨯64x32

// SRV[12]
Texture2D<float4> denoisingInputs[8] : register(t0, space8); // {{RTXStub.buffers.t0_space8}} // R16G16B16A16_FLOAT RENDER
// denoisingInputs #1 // {{RTXStub.buffers.t1_space8}} // R16G16B16A16_FLOAT RENDER
// denoisingInputs #2 // {{RTXStub.buffers.t2_space8}} // R16G16B16A16_FLOAT RENDER
// denoisingInputs #3 // {{RTXStub.buffers.t3_space8}} // R16G16B16A16_FLOAT RENDER
// denoisingInputs #4 // {{RTXStub.buffers.t4_space8}} // R16G16B16A16_FLOAT RENDER
// denoisingInputs #5 // {{RTXStub.buffers.t5_space8}} // R16G16B16A16_FLOAT RENDER
// denoisingInputs #6 // {{RTXStub.buffers.t6_space8}} // R16G16B16A16_FLOAT RENDER
// denoisingInputs #7 // {{RTXStub.buffers.t7_space8}} // R16G16B16A16_FLOAT RENDER
Texture2D<float4> denoisingChromaAndVarianceInputs[4] : register(t8, space8); // {{RTXStub.buffers.t8_space8}} // R16G16B16A16_FLOAT RENDER
// denoisingChromaAndVarianceInputs #1 // {{RTXStub.buffers.t9_space8}} // R16G16B16A16_FLOAT RENDER
// denoisingChromaAndVarianceInputs #2 // {{RTXStub.buffers.t10_space8}} // R16G16B16A16_FLOAT RENDER
// denoisingChromaAndVarianceInputs #3 // {{RTXStub.buffers.t11_space8}} // R16G16B16A16_FLOAT RENDER

// UAV[12]
{{RTXStub.buffers.u0_space3}} // R16G16B16A16_FLOAT RENDER
// denoisingOutputs #1 // {{RTXStub.buffers.u1_space3}} // R16G16B16A16_FLOAT RENDER
// denoisingOutputs #2 // {{RTXStub.buffers.u2_space3}} // R16G16B16A16_FLOAT RENDER
// denoisingOutputs #3 // {{RTXStub.buffers.u3_space3}} // R16G16B16A16_FLOAT RENDER
// denoisingOutputs #4 // {{RTXStub.buffers.u4_space3}} // R16G16B16A16_FLOAT RENDER
// denoisingOutputs #5 // {{RTXStub.buffers.u5_space3}} // R16G16B16A16_FLOAT RENDER
// denoisingOutputs #6 // {{RTXStub.buffers.u6_space3}} // R16G16B16A16_FLOAT RENDER
// denoisingOutputs #7 // {{RTXStub.buffers.u7_space3}} // R16G16B16A16_FLOAT RENDER
{{RTXStub.buffers.u8_space3}} // R16G16B16A16_FLOAT RENDER
// denoisingChromaAndVarianceOutputs #1 // {{RTXStub.buffers.u9_space3}} // R16G16B16A16_FLOAT RENDER
// denoisingChromaAndVarianceOutputs #2 // {{RTXStub.buffers.u10_space3}} // R16G16B16A16_FLOAT RENDER
// denoisingChromaAndVarianceOutputs #3 // {{RTXStub.buffers.u11_space3}} // R16G16B16A16_FLOAT RENDER

// SRV[4]
Texture2D<float2> inputBufferDiffuseMoments : register(t0, space9); Texture2D<float2> denoisingMomentsInputs[4] : register(t0, space9); // {{RTXStub.buffers.t0_space9}} // R16G16_FLOAT RENDER
{{RTXStub.buffers.t1_space9}} // R16G16_FLOAT RENDER
Texture2D<float2> inputBufferSpecularMoments : register(t2, space9); // {{RTXStub.buffers.t2_space9}} // R16G16_FLOAT RENDER
{{RTXStub.buffers.t3_space9}} // R16G16_FLOAT RENDER

// SRV[2]
{{RTXStub.buffers.t0_space4}} // R16G16B16A16_FLOAT RENDER
// shadowDenoisingInputs #1 // {{RTXStub.buffers.t1_space4}} // R16G16B16A16_FLOAT RENDER

// UAV[2]
{{RTXStub.buffers.u0_space4}} // R16G16B16A16_FLOAT RENDER
// shadowDenoisingOutputs #1 {{RTXStub.buffers.u1_space4}} // R16G16B16A16_FLOAT RENDER

// UAV[2]
RWStructuredBuffer<LightInfo> outputLightsBuffer : register(u0, space13); // {{RTXStub.buffers.u0_space13}} // 98304
RWStructuredBuffer<LightInfo> outputReducedLightsBuffer : register(u1, space13); // {{RTXStub.buffers.u1_space13}} // 4096

// SRV[3]
{{RTXStub.buffers.t0_space13}} // 98304
{{RTXStub.buffers.t1_space13}} // 4096
{{RTXStub.buffers.t2_space13}} // 32

// DESCRIPTOR_TABLE [9]
// SRV[4096]
Buffer<uint16_t> indexBuffers[4096] : register(t0, space1); // {{RTXStub.buffers.t0_space1}} // 4096

// SRV[4096]
{{RTXStub.buffers.t0_space2}} // 4096

// SRV[4096]
StructuredBuffer<FaceData> faceDataBuffers[4096] : register(t0, space3); // {{RTXStub.buffers.t0_space3}} // 4096

// SRV[4096]
StructuredBuffer<uint4> faceUvBuffers[4096] : register(t0, space5); // {{RTXStub.buffers.t0_space5}} // 4096

// UAV[4096]
{{RTXStub.buffers.u0_space1}} // 4096

// UAV[4096]
{{RTXStub.buffers.u0_space2}} // 4096

// UAV[4096]
{{RTXStub.buffers.u0_space10}} // 4096

// UAV[4096]
{{RTXStub.buffers.u0_space11}} // 4096

// UAV[4096]
{{RTXStub.buffers.u0_space9}} // 4096

// DESCRIPTOR_TABLE [1]
// SRV[4096]
{{RTXStub.buffers.t0_space6}} // 4096

// DESCRIPTOR_TABLE [1]
// SAMPLER[4]
{{RTXStub.buffers.s0_space0}} // Filter MIN_LINEAR_MAG_POINT_MIP_LINEAR AddressU CLAMP AddressV CLAMP AddressW WRAP
{{RTXStub.buffers.s1_space0}} // Filter MIN_MAG_MIP_LINEAR AddressU CLAMP AddressV CLAMP AddressW CLAMP
{{RTXStub.buffers.s2_space0}} // Filter MIN_MAG_MIP_LINEAR AddressU WRAP AddressV WRAP AddressW WRAP
SamplerState pointSampler : register(s3); // {{RTXStub.buffers.s3_space0}} // Filter MIN_MAG_POINT_MIP_LINEAR AddressU CLAMP AddressV CLAMP AddressW WRAP
#endif