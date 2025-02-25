#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" 
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" 
#include "Assets/ShaderLibrary/Droplet.hlsl" 


CBUFFER_START(UnityPerMaterial)
float _OutlineWidth;

float _ShadowThresholdCenter;
float _ShadowThresholdSoftness;

float4 _TintColor;

sampler2D _BaseMap;
float4 _BaseMap_ST;


float _IndirectLightFlattenNormal;
float _IndirectLightUsage;
float _IndirectLight0cclusionUsage;
float _IndirectLightMixBaseColor;

sampler2D _MagicMap;

#if NORMALMAP
sampler2D _NormalMap;
float _BumpScale;
#if HEIGHTMAP
sampler2D _HeightMap;
#endif
#endif

#if COLORRAMP
sampler2D _BaseColorRampMap;
#else
float4 _BaseColorFront;
float4 _BaseColorBehind;
#endif

float _SpecularExpon;
float _SpecularKsNonMetal;
float _SpecularKsMetal;
float _SpecularBrightness;
float _SpecularThreshold;

float _RimLightWidth;
float _RimLightThreshold;
float _RimLightFadeout;
float4 _RimLightTintColor;
float _RimLightBrightness;
float _RimLightMixAlbedo;
float _FresnelIntensity;
float4 _FresnelColor;
float _StructureHiighLitIntensity;


float _Metallic;
#if METALLICMAP
    sampler2D _MetallicMap;
#endif

#if SSR
    float _RaySteps;
    float _RayLength;
    float _MinLostDist;
#endif

//sampler2D _CameraDepthTexture;

#if RAIN
    float _DesaturationFraction;
    float _DesaturationLerp;
    float _DesaturationDarkness;

    sampler2D _DropletMask;
    sampler2D _WetMap;
    float _WetRegionSize;
    float4 _DropletParams;
    float4 _DynamicDropParams;

    sampler2D _RainDropNormalMap;
    float _RainDropBumpScale;
#endif

CBUFFER_END
