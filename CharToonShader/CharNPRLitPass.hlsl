struct Attributes
{
    float4 positionOS : POSITION;
    float2 uv : TEXCOORD0;
    float3 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
    float4 uv7 : TEXCOORD7;
};
struct Varyings
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 SH : TEXCOORD1;
    float3 normalOS : NORMAL;
    float3 normalWS : TEXCOORD2;
    float3 viewDirectionWS : TEXCOORD3;
    float3 positionWS : TEXCOORD4;
};
Varyings vert(Attributes input)
{
    Varyings output;
    
    VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    
    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
//#if NORMALMAP
//    //float3x3 tbn = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
//    //output.normalWS = mul(input.uv7.rgb, tbn);
//    //output.normalWS = normalize(tex2Dlod(_NormalMap,float4(output.uv,0,0))*2-1);
//#else
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
//#endif
    output.SH = SampleSH(lerp(output.normalWS, float3(0, 0, 0), _IndirectLightFlattenNormal));
    output.normalOS = input.normalOS;
    output.viewDirectionWS = _WorldSpaceCameraPos.xyz - output.positionWS;
    return output;
}
float4 frag(Varyings input,bool isFrontFace:SV_IsFrontFace) : SV_TARGET
{
    float3 positionWS = input.positionWS;
    float shadowMask = 1;

    float3 normalWS = input.normalWS;

    //获取基础的颜色/数据贴图
    float4 baseColor = 1;
    baseColor = tex2D(_BaseMap, input.uv);
    // 采样baseColor
#if _AREA_FACE
    baseColor = tex2D(_FaceColorMap,input.uv);
#elif _AREA_HAIR
    baseColor = tex2D(_HairColorMap,input.uv);
#elif _AREA_UPPERBODY
    baseColor = tex2D(_UpperBodyColorMap,input.uv);
#elif _AREA_LOWERBODY
    baseColor = tex2D(_LowerBodyColorMap,input.uv);
#elif _AREA_WEAPON
    baseColor = tex2D(_WeaponColorMap,input.uv);
#endif
    baseColor *= lerp(_BackFaceTintColor, _FrontFaceTintColor, isFrontFace);
    
    float4 lightMap = 0;
// 采样lightmap
#if _AREA_HAIR
    lightMap = tex2D(_HairLightMap,input.uv);
#elif _AREA_UPPERBODY
    lightMap = tex2D(_UpperBodyLightMap,input.uv);
#elif _AREA_LOWERBODY
    lightMap = tex2D(_LowerBodyLightMap,input.uv);
#elif _AREA_WEAPON
    lightMap = tex2D(_WeaponLightMap,input.uv);
#endif
    
    float4 faceMap = 0;
    //采样faceMap
#if _AREA_FACE
    faceMap = tex2D(_FaceMap,input.uv);
#endif
    
    // 主光源阴影/颜色计算
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    // Get Recieve Shadows And MainLight Shadow
    Light mainLight = GetMainLight(shadowCoord, positionWS, shadowMask);
    half NdotL = 0;//smoothstep(0, 0.1, dot(normalWS, mainLight.direction));
    float3 lightDir = normalize(mainLight.direction);
    NdotL = dot(normalWS, mainLight.direction);
    float lambert = NdotL* 0.5 + 0.5;
    float mainLightShadow = 0;
    float3 V = normalize(input.viewDirectionWS);
    float3 H = normalize(lightDir + V);
    float3 mainLightColor = lerp(desaturation(mainLight.color), mainLight.color, _MainLightColorUsage);
    // RampMap的应用
    int rampRowIndex = 0;
    int rampRowNum = 1;
#if _AREA_UPPERBODY||_AREA_LOWERBODY||_AREA_HAIR||_AREA_WEAPON
    mainLightShadow = smoothstep(1-lightMap.g+_ShadowThresholdCenter-_ShadowThresholdSoftness,1-lightMap.g+_ShadowThresholdCenter+_ShadowThresholdSoftness,lambert);
    
    float recieveShadow = mainLight.distanceAttenuation * mainLight.shadowAttenuation * mainLightShadow; // > 0 ? 1 : 0;
    mainLightShadow = recieveShadow * lightMap.r;
    
    #if Ramp && _AREA_HAIR
        rampRowIndex = 0;
        rampRowNum = 1;
    #elif Ramp && (_AREA_UPPERBODY||_AREA_LOWERBODY || _AREA_WEAPON)
        // setting1
        rampRowIndex = floor(lightMap.a*8);
        // setting2
        int rawIndex = (round((lightMap.a+0.0425)/0.0625)-1)/2;
        rampRowIndex = lerp(rawIndex,rawIndex+4<8?rawIndex+4:rawIndex+4-8,fmod(rawIndex,2));
        rampRowNum = 8;
    #endif
    
#elif _AREA_FACE
    // 计算头部的向量
    float3 headForward = normalize(_HeadForward);
    float3 headRight = normalize(_HeadRight);
    float3 headUp = cross(headForward,headRight);
    
    // 防止倒置模型sdf发生反装
    float3 fixedLightDirectionWS = normalize(lightDir-dot(lightDir,headUp)*headUp);
    float2 sdfUV = float2(sign(dot(fixedLightDirectionWS,headRight)),1)*input.uv*float2(-1,1);
    
    // 如果SDF在faceMap中是下面这句
    float sdfValue = tex2D(_FaceMap,sdfUV).a;
    //float sdfValue = tex2D(_FaceSDFMap,sdfUV).r;
    // 防止背面变白
    sdfValue += _FaceShadow0ffset;
    
    float sdfThreshold = 1-(dot(fixedLightDirectionWS,headForward) *0.5 +0.5);
    float sdf = smoothstep(sdfThreshold-_FaceShadowTransitionSoftness,sdfThreshold+_FaceShadowTransitionSoftness,sdfValue);
    
    mainLightShadow = lerp(faceMap.g,sdf,step(faceMap.r,0.5));
    
    rampRowIndex = 0;
    rampRowNum = 8;
#endif
    
    // Get Additional Light Shadow
    float3 additionLightColor = 0;
    uint pixelLightCount = GetAdditionalLightsCount();

    for (uint lightIndex = 0; lightIndex < pixelLightCount; lightIndex++)
    {
        //FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, positionWS, shadowMask);
        NdotL = dot(normalWS, light.direction);
        
        lambert = smoothstep(_ShadowThresholdCenter - _ShadowThresholdSoftness, _ShadowThresholdCenter + _ShadowThresholdSoftness, NdotL * 0.5 + 0.5);
        additionLightColor += light.color * light.distanceAttenuation * light.shadowAttenuation * lambert;

    }
    
    // Indirect Light
    float3 indirectLightColor = 0;
    float occlusion = 0;
#if _AREA_UPPERBODY||_AREA_LOWERBODY||_AREA_HAIR||_AREA_WEAPON
    occlusion = lightMap.r;
#elif _AREA_FACE
    occlusion = lerp(faceMap.g,1,step(faceMap.r,0.5));
#endif
    occlusion = lerp(1, occlusion, _IndirectLight0cclusionUsage);
    indirectLightColor = input.SH * occlusion * _IndirectLightUsage;
    indirectLightColor *= lerp(1, baseColor, _IndirectLightMixBaseColor);

    // direct light
// 计算RampColor
    float3 rampColor = 1;
#if Ramp
    float rampUVx = mainLightShadow * (1-_ShadowRamp0ffset)+_ShadowRamp0ffset;
    float rampUVy = (2*rampRowIndex + 1) * (1.0/(rampRowNum*2));
    float2 rampUV = float2(rampUVx,rampUVy);
    float3 coolRamp = 1;
    float3 warmRamp = 1;
    
#if _AREA_HAIR
        coolRamp = tex2D(_HairCoolRamp,rampUV).rgb;
        warmRamp = tex2D(_HairWarmRamp,rampUV).rgb;
#elif _AREA_FACE || _AREA_UPPERBODY||_AREA_LOWERBODY||_AREA_WEAPON
        coolRamp = tex2D(_BodyCoolRamp,rampUV).rgb;
        warmRamp = tex2D(_BodyWarmRamp,rampUV).rgb;
#endif
    float isDay = lightDir.y*0.5+0.5;
    rampColor = lerp(coolRamp,warmRamp,isDay);
#endif  
    
    // 计算直接光颜色
    float3 directLightColor = mainLightColor;
    directLightColor *= baseColor.rgb * rampColor;
    
    // 计算高光
    float3 specularColor = 0;
#if _AREA_HAIR || _AREA_UPPERBODY||_AREA_LOWERBODY || _AREA_WEAPON
    float blinnPhong = pow(saturate(dot(normalWS,H)),_SpecularExpon);
    float nonMetalSpecular = step(1.04-blinnPhong,lightMap.b) * _SpecularKsNonMetal;
    float metalSpecular = blinnPhong * lightMap.b * _SpecularKsMetal;
    
    float metallic = 0;
    #if _AREA_UPPERBODY||_AREA_LOWERBODY || _AREA_WEAPON
        metallic = saturate((abs(lightMap.a-0.9)-0.1)/(0-0.1));
    #endif
    
    specularColor = lerp(nonMetalSpecular,metalSpecular *baseColor,metallic);
    specularColor *= mainLightColor;
    specularColor *= _SpecularBrightness;

#endif
    
    // 边缘光计算
    float linearEyeDepth = LinearEyeDepth(input.positionCS.z, _ZBufferParams);
    float3 normalVS = mul((float3x3) UNITY_MATRIX_V, normalWS);
    float2 uvOffset = float2(sign(normalVS.x), 0) * _RimLightWidth / (1 + linearEyeDepth) / 100;
    int2 loadTexPos = input.positionCS.xy + uvOffset * _ScaledScreenParams.xy;
    loadTexPos = min(max(loadTexPos, 0), _ScaledScreenParams - 1);
    float offsetSceneDepth = LoadSceneDepth(loadTexPos);
    float offsetLinearEyeDepth = LinearEyeDepth(offsetSceneDepth, _ZBufferParams);
    float rimLight = saturate(offsetLinearEyeDepth - (linearEyeDepth + _RimLightThreshold)) / _RimLightFadeout;
    float3 rimLightColor = rimLight * mainLight.color.rgb;
    rimLightColor *= _RimLightTintColor;
    rimLightColor *= _RimLightBrightness;
    
        // 自发光计算
    float3 emissionColor = 0;
#if EMISSION
    emissionColor = faceMap.a;
    emissionColor *= lerp(1,baseColor,_EmissionMixBaseColor);
    emissionColor *= _EmissionTintColor;
    emissionColor *= _EmissionIntensity;
#endif
    
    float alpha = _Alpha;
    
#if DRAW_OVERLAY
    float3 headForward = normalize(_HeadForward);
    alpha = lerp(1,alpha,saturate(dot(headForward,V)));
#endif
    
    float3 color = 0;
    color = baseColor.rgb;
    color = indirectLightColor;
    color += directLightColor;
    color += additionLightColor;
    color += specularColor;
    color += rimLightColor;
    color += emissionColor;
    
    float4 res = float4(color, alpha);
    return res;
}