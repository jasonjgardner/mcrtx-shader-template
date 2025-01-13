# MCRTX Shader Template

## Pipeline Overview

### RTXStub

This is a table with high-level desription of MCRTX pipeline

Screen - dispatches a thread for every pixel of game window
Render - dispatched a thread for every pixel of internal rendering buffer
Denoiser - set of denoiser buffers, quarter resolution of render buffers
Inscatter - volumetric buffers, 256 x 128 x 64
Gi Inscatter - volumetric GI buffers, 128 x 64 x 32

| Pass                                     | Group Size  | Dispatch Grid                            | Notes                                                                              |
| ---------------------------------------- | ----------- | ---------------------------------------- | ---------------------------------------------------------------------------------- |
| PreBlasSkinning                          | (64, 1, 1)  | (X, 1, 1)                                | Dispatched before building BVH, for every vertex of animated via skinning geometry |
| CalculateFaceData                        | (128, 1, 1) | (X, 1, 1)                                | Dispatched for every face of every object ??                                       |
| ClearVertexIrradianceCache               | (128, 1, 1) | (X, 1, 1)                                |                                                                                    |
| ClearFaceIrradianceCache                 | (128, 1, 1) | (X, 1, 1)                                |                                                                                    |
| UpdateVertexIrradianceCacheInline        | (32, 1, 1)  | (X\*, 1, 1)                              | \*Shouldn't dispatch more than 1024 groups                                         |
| UpdateFaceIrradianceCacheInline          | (32, 1, 1)  | (X\*, 1, 1)                              | \*Shouldn't dispatch more than 1024 groups                                         |
| IncidentLightMeterInline                 | (4, 4, 2)   | (4, 4, 1)                                |                                                                                    |
| ResolveLightMeasurement                  | (1, 1, 1)   | (1, 1, 1)                                |                                                                                    |
| AdaptiveDenoiserCalculateGradientsInline | (4, 8, 1)   | Denoiser                                 |                                                                                    |
| PrimaryCheckerboardRayGenInline          | (4, 8, 1)   | Render                                   |                                                                                    |
| SunShadowRayGenInline                    | (4, 8, 1)   | Render                                   |                                                                                    |
| AdaptiveDenoiserGenerateReferenceInline  | (4, 8, 1)   | Denoiser                                 |                                                                                    |
| TileClassification                       | (16, 16, 1) | Render                                   |                                                                                    |
| BlurGradients                            | (128, 1, 1) | Denoiser\*                               | Alternates between XY and YX coordinates, dispatched 4 times                       |
| RefractionRayGenInline                   | (4, 8, 1)   | Render                                   |                                                                                    |
| DiffuseRayGenCombinedInline              | (4, 8, 1)   | Render                                   |                                                                                    |
| ExplicitLightSamplingInline              | (4, 8, 1)   | Render                                   |                                                                                    |
| SpecularRayGenInline                     | (4, 8, 1)   | Render                                   |                                                                                    |
| CalculateInscatterInline                 | (4, 4, 2)   | (64, 32, 32) (Inscatter)                 |                                                                                    |
| CalculateGIInscatterInline               | (4, 4, 2)   | (32, 16, 16) (GI Inscatter)              |                                                                                    |
| BlurGIInscatter                          | (16, 16, 1) | (8, 4, 32) (GI Inscatter)                | Dispatched twice                                                                   |
| AccumulateInscatter                      | (16, 16, 1) | (16, 8, 1) (Inscatter (2D slice only))   |                                                                                    |
| AccumulateGIInscatter                    | (16, 16, 1) | (8, 4, 1) (GI Inscatter (2D slice only)) |                                                                                    |
| ReprojectSH                              | (16, 16, 1) | Render                                   |                                                                                    |
| SpecularFireflyFilter                    | (16, 16, 1) | Render                                   |                                                                                    |
| FilterMomentsSH                          | (16, 16, 1) | Render                                   | Disabled if SHDiffuse is disabled                                                  |
| FilterMoments                            | (16, 16, 1) | Render                                   |                                                                                    |
| AtrousSH and Atrous                      | (16, 8, 1)  | Render                                   | Dispatches 4 pairs of AtrousSH and Atrous, then dispatches AtrousSH twice.         |
| TemporalDenoising                        | (16, 16, 1) | Render                                   |                                                                                    |
| ShadowDenoising                          | (16, 16, 1) | Render                                   | Dispatched twice                                                                   |
| FinalizeDenoising                        | (16, 16, 1) | Render                                   |                                                                                    |
| BlendCheckerboardFieldsShadow            | (16, 16, 1) | Render                                   |                                                                                    |
| FinalCombine                             | (16, 16, 1) | Screen                                   |                                                                                    |
| CheckerboardInterleave                   | (16, 16, 1) | Screen\*                                 | +1 on each dispatch dimension if upscaling is enabled                              |
| TAA                                      | (16, 16, 1) | Screen                                   | If upscaling is enabled, this pass would be replaced with DLSS calls               |
| CopyToFinal                              | (16, 16, 1) | Screen\*                                 | + extra padding (approx 1/7 of resolution) if upscaling is enabled                 |
| ToneMappingHistogram                     | (16, 16, 1) | Screen                                   |                                                                                    |
| ToneCurve                                | (256, 1, 1) | (1, 1, 1)                                |                                                                                    |

Unused passes

| Pass                      | Notes                                         |
| ------------------------- | --------------------------------------------- |
| Reproject                 | Replaces ReprojectSH if SHDiffuse is disabled |
| DiffuseFireflyFilterSH    | Disabled by default                           |
| DiffuseFireflyFilter      | Disabled by default                           |
| BlendCheckerboardFields   |                                               |
| BlendCheckerboardFieldsSH |                                               |
| CheckerboardUpscale       |                                               |
| CheckerboardUpscaleSH     |                                               |
| PathTracingRayGenInline   | Reference path tracer                         |
| ReprojectSpecularOnly     |                                               |
| WFTest                    | White furnace test                            |
| DrawLights                | Debug visualization of lights                 |
