$input v_texcoord0

#include "../../include/bgfx_shader.sh"

/*
Macros:
{{RTXPostFX.Bloom.passes}}
*/

{ {RTXPostFX.Bloom.uniforms}}

vec4 ViewRect;
mat4 Proj;
mat4 View;
vec4 ViewTexel;
mat4 InvView;
mat4 InvProj;
mat4 ViewProj;
mat4 InvViewProj;
mat4 PrevViewProj;
mat4 WorldArray[4];
mat4 World;
mat4 WorldView;
mat4 WorldViewProj;
vec4 PrevWorldPosOffset;
vec4 AlphaRef4;
float AlphaRef;

struct FragmentInput {
    vec2 texcoord0;
};

struct FragmentOutput {
    vec4 Color0;
};

{ {RTXPostFX.Bloom.buffers}}

// MCRTX bloom pipeline passes:

// - BloomDownscaleUniformPass

// - BloomDownscaleGaussianPass
// - BloomDownscaleGaussianPass
// - BloomDownscaleGaussianPass
// - BloomDownscaleGaussianPass

// - BloomUpscalePass
// - BloomUpscalePass
// - BloomUpscalePass
// - BloomUpscalePass

// TonemapPass does the final upscaling

// Note: BloomFinalPass is not used in the game

vec4 applyDownscaleGaussianPass(FragmentInput fragInput) {
    return texture2D(s_RasterColor, fragInput.texcoord0);
}
vec4 applyDownscaleUniformPass(FragmentInput fragInput) {
    return texture2D(s_RasterColor, fragInput.texcoord0);
}
vec4 applyUpscalePass(FragmentInput fragInput) {
    return texture2D(s_RasterColor, fragInput.texcoord0);
}
vec4 applyBloomFinalPass(FragmentInput fragInput) {
    return texture2D(s_RasterColor, fragInput.texcoord0);
}

void Frag(FragmentInput fragInput, inout FragmentOutput fragOutput) {
    #ifdef BLOOM_DOWNSCALE_GAUSSIAN_PASS
    fragOutput.Color0 = applyDownscaleGaussianPass(fragInput);
    #endif
    #ifdef BLOOM_DOWNSCALE_UNIFORM_PASS
    fragOutput.Color0 = applyDownscaleUniformPass(fragInput);
    #endif
    #ifdef BLOOM_UPSCALE_PASS
    fragOutput.Color0 = applyUpscalePass(fragInput);
    #endif
    #ifdef BLOOM_FINAL_PASS
    fragOutput.Color0 = applyBloomFinalPass(fragInput);
    #endif
}
void main() {
    FragmentInput fragmentInput;
    FragmentOutput fragmentOutput;
    fragmentInput.texcoord0 = v_texcoord0;
    fragmentOutput.Color0 = vec4(0, 0, 0, 0);
    ViewRect = u_viewRect;
    Proj = u_proj;
    View = u_view;
    ViewTexel = u_viewTexel;
    InvView = u_invView;
    InvProj = u_invProj;
    ViewProj = u_viewProj;
    InvViewProj = u_invViewProj;
    PrevViewProj = u_prevViewProj;
    {
        WorldArray[0] = u_model[0];
        WorldArray[1] = u_model[1];
        WorldArray[2] = u_model[2];
        WorldArray[3] = u_model[3];
    }
    World = u_model[0];
    WorldView = u_modelView;
    WorldViewProj = u_modelViewProj;
    PrevWorldPosOffset = u_prevWorldPosOffset;
    AlphaRef4 = u_alphaRef4;
    AlphaRef = u_alphaRef4.x;
    Frag(fragmentInput, fragmentOutput);
    gl_FragColor = fragmentOutput.Color0;
}

