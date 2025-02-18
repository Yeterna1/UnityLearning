#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" 
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" 



CBUFFER_START(UnityPerMaterial)
float _OutlineWidth;

float _ShadowThresholdCenter;
float _ShadowThresholdSoftness;

vector _HeadForward;
vector _HeadRight;

sampler2D _BaseMap;
float4 _BaseMap_ST;

#ifdef _AREA_FACE
    sampler2D _FaceColorMap;
    sampler2D _FaceMap;
    sampler2D _FaceSDFMap;
    sampler2D _BodyCoolRamp;
    sampler2D _BodyWarmRamp;
    float _FaceShadow0ffset;
    float _FaceShadowTransitionSoftness;

#elif _AREA_HAIR
    sampler2D _HairColorMap;
    sampler2D _HairLightMap;
    sampler2D _HairCoolRamp;
    sampler2D _HairWarmRamp;

#elif _AREA_UPPERBODY
    sampler2D _UpperBodyColorMap;
    sampler2D _UpperBodyLightMap;
    sampler2D _BodyCoolRamp;
    sampler2D _BodyWarmRamp;

#elif _AREA_LOWERBODY
    sampler2D _LowerBodyLightMap;
    sampler2D _LowerBodyColorMap;
    sampler2D _BodyCoolRamp;
    sampler2D _BodyWarmRamp;

#elif _AREA_WEAPON
    sampler2D _WeaponColorMap;
    sampler2D _WeaponLightMap;
    sampler2D _BodyCoolRamp;
    sampler2D _BodyWarmRamp;
#endif

#if Ramp
    float _ShadowRamp0ffset;
#endif

float4 _FrontFaceTintColor;
float4 _BackFaceTintColor;

float _Alpha;
float _AlphaClip;

float _IndirectLightFlattenNormal;
float _IndirectLightUsage;
float _IndirectLight0cclusionUsage;
float _IndirectLightMixBaseColor;

sampler2D _NormalMap;

sampler2D _BaseColorRampMap;

float _MainLightColorUsage;

float _SpecularExpon;
float _SpecularKsNonMetal;
float _SpecularKsMetal;
float _SpecularBrightness;

float _RimLightWidth;
float _RimLightThreshold;
float _RimLightFadeout;
float4 _RimLightTintColor;
float _RimLightBrightness;
float _RimLightMixAlbedo;

CBUFFER_END