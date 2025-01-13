# mcrtx-shader-template

This is a basic template shader for Bedrock RTX, written from scratch. It utilizes some auto-generation scripts to extract information such as buffers and structs from material.bin files and insert that information into code, which allows to easily adapt to any changes in shaders that may be introduced with game updates and it also provides some transparency for where some of the code here is coming from.

## Work In Progress!

This is still a WIP as I'm releasing this earlier than planned and I will be actively refactoring and updating this repository in the near future (and also intend to maintain & update it in the long term, to accommodate every game update that may change something in RTX). This section will be removed once I am happy with the state of this project.

## Repository Structure

This repository can be divided into 4 folders:

- `src/` - auto generation scripts written in Python. Those scripts analyze and extract useful information from material.bin files and insert it into hlsl code.
- `template/` - [lazurite](https://github.com/veka0/lazurite) project, with shader source code that is augmented with templating tokens (e.g. `{{RTXStub.passes.TAA.group_size}}`)
- `project/` - copy of a `template/` folder, except with all templating tokens replaced with their actual data. This folder is automatically populated when running generation script, and it can be compiled as a valid [lazurite](https://github.com/veka0/lazurite) project.
- `vanilla/` - folder where you need to place your vanilla RTX material.bin files in order to use templating engine script or to compile shaders.

## How To Use

Generally, there are 3 things you can do with this repository. You can take the compilable shader project from `project/` folder and use it as a starting point for your brand-new shader. Or, you can watch for changes in commits, in order to update your own RTX shader in case there are any changes introduced with game updates. Lastly, you can utilize the templating engine that is provided in this repository and set it up for your own shaders, in order to update them accordingly as the game updates and changes something in BRTX.

## Automation Scripts

The main script is located at `src/script.py` and it's responsible for analyzing material.bin files in a `vanilla/` folder and generating a compilable project, by copying all files from `template/` folder, replacing templating tokens with appropriate data which was extracted from materials, and saving results into the `project/` folder. Running it requires python and [lazurite](https://github.com/veka0/lazurite).

There is also a secondary helper script `src/process_signature.py` which can be provided with Root Signature data from PIX and output template tokens assigned to each resource. This script was used when creating `Signature.hlsl` file.

## How To Compile

In order to compile RTX shaders in `project/` folder, the following is required:

- Python 3.10+ (3.12 is recommended, and it's best to install it from Microsoft Store)
- [Lazurite](https://github.com/veka0/lazurite), which is a python library & CLI tool for creating and working with bedrock shaders
- [DXC](https://github.com/microsoft/DirectXShaderCompiler/releases) compiler executable, necessary to compile core ray tracing shaders from RTXStub
- [Shaderc](https://github.com/veka0/bgfx-mcbe/releases/tag/binaries) compiler executable, necessary to compile PostFX shaders, written in a GLSL-like language
- Copying vanilla material.bin files into the `vanilla/` folder. Specifically, `RTXStub.material.bin`, `RTXPostFX.Bloom.material.bin` and `RTXPostFX.Tonemapping.material.bin` are required

Once all requirements are satisfied, place compiler executables into the root folder of this repository, then open a command prompt and run `lazurite build project/ -o ./` which will compile all shaders and output material.bin files in the current directory. See lazurite [documentation](https://veka0.github.io/lazurite/) for additional customization options.

## Pipeline Overview

### RTXStub

This is a table with high-level description of MCRTX pipeline

Dispatch Grid legend

- Screen - dispatches a thread for every pixel of game window
- Render - dispatched a thread for every pixel of internal rendering buffer
- Denoiser - set of denoiser buffers, 1px = 4x4 Render pixels
- Inscatter - volumetric buffers, 256 x 128 x 64
- Gi Inscatter - volumetric GI buffers, 128 x 64 x 32

| Pass                                     | Group Size  | Dispatch Grid                            | Notes                                                                              |
| ---------------------------------------- | ----------- | ---------------------------------------- | ---------------------------------------------------------------------------------- |
| PreBlasSkinning                          | (64, 1, 1)  | (X, 1, 1)                                | Dispatched before building BVH, for every vertex of animated via skinning geometry |
| CalculateFaceData                        | (128, 1, 1) | (X, 1, 1)                                | Dispatched for every face of every object (?)                                      |
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

### PostFX

- BloomDownscaleUniformPass (RTXPostFX.Bloom)
- BloomDownscaleGaussianPass (RTXPostFX.Bloom, renders 4 times)
- BloomUpscalePass (RTXPostFX.Bloom, renders 4 times)
- TonemapPass (RTXPostFX.Tonemapping)
