#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" 
//#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" 

// tint
sampler2D _DepthRamp;
float4 _ShallowWaterColor;
float4 _DeepWaterColor;
float _WaterDepthRemap;
float _WaterDepthCoef;
float _FresnelIntensity;
float _Transmission;

// reflection
sampler2D _ReflectDistortMap;
float _ReflectDistortIntensity;
float _ReflectDistortScale;
sampler2D _ReflectMap;
sampler2D _SSRTexture;
float _ReflectIntensity;

// highlight
float _Roughness;

sampler2D _CameraOpaqueTexture;
//sampler2D _CameraDepthTexture;

// refraction
float _RefractIntensity;

// foam
sampler2D _FoamMap;
float4 _FoamMap_ST;
float _FoamScale;
float _FoamIntensity;

// Caustics
sampler2D _CausticsMap;
float4 _CausticsMap_ST;
float _CausticsScale;
float _CausticsDensity;
float _CausticsTransIntensity;
float _CausticsIntensity;

// tessallation properties
float _EdgeFactor;
float _InsideFactor;

// FFT input
sampler _WaterSurfaceDisplace;
float _DisplaceIntensity;
sampler _WaterSurfaceNormal;
sampler _WaterSurfaceBubbles;
float _BubblesIntensity;

// shadowReceive
float _ShadowReceiveIntensity;

//sampler2D _CameraDepthTexture;






