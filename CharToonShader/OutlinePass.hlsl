#include "Assets/ShaderLibrary/CharNPRFunctions.hlsl"

struct Attributes
{
    float3 positionOS : POSITION;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float4 color : COLOR;
    float2 uv : TEXCOORD0;
    float4 uv7 : TEXCOORD7;
};
    
struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORDO;
    float fogFactor : TEXCOORD1;
    float4 color : TEXCOORD2;
};

Varyings vert(Attributes input)
{
    Varyings output = (Varyings) 0;
    
    VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    
    float width = _OutlineWidth;
    //width *= 0.001;
    width *= GetOutlineCameraFovAndDistanceFixMultiplier(vertexPositionInput.positionVS.z);
    
    output.uv = input.uv;
    
    float3 positionWS = vertexPositionInput.positionWS;
#if OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL
    float3x3 tbn = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
    positionWS += mul(input.uv7.rgb, tbn) * width;
#else
    positionWS += vertexNormalInput.normalWS * width;
#endif
    output.positionCS = TransformWorldToHClip(positionWS);
    output.uv = input.uv;
    output.fogFactor == ComputeFogFactor(vertexPositionInput.positionCS.z);
    
    return output;
}

float4 frag(Varyings input) : SV_TARGET
{
//    float4 lightMap = 0;
//#if _AREA_HAIR
//    lightMap = tex2D(_HairLightMap,input.uv);
//#elif _AREA_UPPERBODY
//    lightMap = tex2D(_UpperBodyLightMap,input.uv);
//#elif _AREA_LOWERBODY
//    lightMap = tex2D(_LowerBodyLightMap,input.uv);
//#endif
    
//    float layer = floor(lightMap.a * 8)*0.125;
//    float3 outlineColor = 0;
    
//    #if LUT
//        outlineColor = tex2D(_BodyDiffuseLUT,float2(layer,0.125*2));
//        //outlineColor = 1;
//    #endif
    
//    float3 coolRamp = 0;
//    float3 warmRamp = 0;
//#if _AREA_HAIR
//    float2 outlineUV = float2(0,0.5);
//    coolRamp = tex2D(_HairCoolRamp, outlineUV).rgb;
//    warmRamp = tex2D(_HairWarmRamp, outlineUV).rgb;
//#elif _AREA_UPPERBODY || _AREA_LOWERBODY
//    float4 lightMap = 0;
//#if _AREA_UPPERBODY
//        lightMap = tex2D(_UpperBodyLightMap,input.uv);
//#elif _AREA_LOWERBODY
//        lightMap = tex2D(_LowerBodyLightMap,input.uv);
//#endif
//    float materialEnum = lightMap.a;
//    float materialEnumOffset = materialEnum+ 0.0425;
//    float outlineUVy = lerp(materialEnumOffset,materialEnumOffset + 0.5> 1 ? materialEnumOffset + 0.5-1 : materialEnumOffset + 0.5,fmod((round(materialEnumOffset/0.0625)- 1)/2, 2));
//    float2 outlineUV = float2(0,outlineUVy);
//    coolRamp = tex2D(_BodyCoolRamp, outlineUV).rgb;
//    warmRamp = tex2D(_BodyWarmRamp, outlineUV).rgb;
//#elif _AREA_FACE
//    float2 outlineUV = float2(0,0.0625);
//    coolRamp = tex2D(_BodyCoolRamp, outlineUV).rgb;
//    warmRamp = tex2D(_BodyWarmRamp, outlineUV).rgb;
//#endif
//    float3 ramp = lerp(coolRamp, warmRamp, 0.5);
//    float3 albedo = pow(saturate(ramp), _OutlineGamma);
//    float4 color = float4(albedo, 1);
//    color.rgb = MixFog(color.rgb, input.fogFactor);
    float4 color = 0;
    color = float4(0,0,0,1);
    //float4 color = float4(outlineColor, 1);
    return color;
}