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
    float4 tangentOS : TEXCOORD5;
    float3 tangentWS : TEXCOORD6;
};
Varyings vert(Attributes input)
{
    Varyings output;
    
    VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(input.positionOS);
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    
    output.positionCS = TransformObjectToHClip(input.positionOS);
    output.positionWS = TransformObjectToWorld(input.positionOS);
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
#if NORMALMAP
    output.normalWS = normalize(tex2Dlod(_NormalMap,float4(output.uv,0,0))*2-1);
#else
    output.normalWS = TransformObjectToWorldNormal(input.normalOS);
#endif
    output.SH = SampleSH(lerp(output.normalWS, float3(0, 0, 0), _IndirectLightFlattenNormal));
    output.normalOS = input.normalOS;
    output.viewDirectionWS = _WorldSpaceCameraPos.xyz - output.positionWS;
    output.tangentOS = input.tangentOS;
    output.tangentWS = vertexNormalInput.tangentWS;
    return output;
}
float4 frag(Varyings input) : SV_TARGET
{
    float4 positionCS = input.positionCS;
    float3 positionWS = input.positionWS;
    float shadowMask = 1;
    float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
    float3 normalWS = normalize(input.normalWS);
    float3 cameraDir = GetViewForwardDir();

#if RAIN
    float dropletMaskMap = tex2D(_DropletMask, input.uv).r;
#endif

#if NORMALMAP
    
    // 获取使用NormalMap的法线
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float4 N = tex2D(_NormalMap, input.uv);
    float3 tangentNormal = UnpackNormal(N); // 使用Unity内置的方法，从颜色值得到法线在切线空间的方向
    tangentNormal.xy = tangentNormal.xy * _BumpScale; // 控制凹凸程度
    #if HEIGHTMAP
       tangentNormal.xy *= tex2D(_HeightMap,input.uv).g;
    #endif
    tangentNormal = normalize(tangentNormal);
    float3x3 tbn = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
    normalWS = mul(tangentNormal, tbn);
#elif RAIN
    VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    float3 tangentNormal = UnpackNormal(tex2D(_RainDropNormalMap, input.uv));
    //float3 tangentNormal = UnpackNormal(N); // 使用Unity内置的方法，从颜色值得到法线在切线空间的方向
    tangentNormal.xy = tangentNormal.xy * _RainDropBumpScale; // 控制凹凸程度
    tangentNormal = normalize(tangentNormal);
    float3x3 tbn = float3x3(vertexNormalInput.tangentWS, vertexNormalInput.bitangentWS, vertexNormalInput.normalWS);
    normalWS = lerp(normalWS,mul(tangentNormal, tbn),dropletMaskMap);
    
#endif
    
    Light mainLight = GetMainLight(shadowCoord, positionWS, shadowMask);
    float3 L = normalize(mainLight.direction);
    float3 V = normalize(input.viewDirectionWS);
    float3 H = normalize(mainLight.direction + V);

    float NdotL = saturate(dot(normalWS, L));
    float NdotH = saturate(dot(normalWS, H));
    float NdotV = saturate(dot(normalWS, V));
    float LdotH = saturate(dot(L, H));
    float VdotH = saturate(dot(V, H));
    // fersnel
    float Fresnel4 = pow(1-NdotV, 4);
    
    // Indirect Light
    float3 texColor = 0;
#if COLORTEX
    texColor = tex2D(_BaseMap, input.uv).rgb;
    #if RAIN

        float2 aspect = _DropletParams.xy;

        float dropletMask = step(normalWS.y,_DynamicDropParams.z);
        dropletMask *= dropletMaskMap;

        float2 tuv1 = DynamicDroplet(aspect, _DynamicDropParams.x, _DynamicDropParams.y, _Time.y, _DynamicDropParams.w, normalWS.y, positionWS.xy) * dropletMask;
        float2 tuv2 = DynamicDroplet(aspect, _DynamicDropParams.x, _DynamicDropParams.y, _Time.y, _DynamicDropParams.w, normalWS.y, positionWS.zy) * dropletMask;
        
        float2 fuv = lerp(tuv1,tuv2,normalWS.x);
        //float3 baseColor1 =  tex2D(_BaseMap,input.uv+tuv1);
        //float3 baseColor2 =  tex2D(_BaseMap,input.uv+tuv2);

        //texColor = lerp(baseColor1,baseColor2,normalWS.x);
        texColor = tex2D(_BaseMap,input.uv+fuv);
    
        float isWet = step(_WetRegionSize,tex2D(_WetMap,input.uv).r) * dropletMaskMap;
    
        texColor = CalColorWetness(texColor,_DesaturationDarkness,_DesaturationDarkness,isWet,_DesaturationLerp);
    #endif
#else
    texColor = _TintColor.rgb;
#endif
    
    float3 indirectLightColor = 0;
    float occlusion = tex2D(_MagicMap, input.uv).g;
    occlusion = lerp(1, occlusion, _IndirectLight0cclusionUsage);
    indirectLightColor = input.SH * occlusion * _IndirectLightUsage;
    indirectLightColor *= lerp(1, texColor, _IndirectLightMixBaseColor);
    
    // 计算平行光颜色
    float3 baseColor = 1;
    baseColor = texColor;
    float lambert = smoothstep(_ShadowThresholdCenter - _ShadowThresholdSoftness, _ShadowThresholdCenter + _ShadowThresholdSoftness, dot(normalWS,L) * 0.5 + 0.5);
    lambert *= mainLight.distanceAttenuation * mainLight.shadowAttenuation;
    lambert = lerp(0.01, 0.99, lambert);
#if COLORRAMP
    float3 rampColor = tex2D(_BaseColorRampMap, float2(lambert, 0.5));
    baseColor *= rampColor * mainLight.color * occlusion;
#else
    float3 rampColor = lerp(_BaseColorBehind,_BaseColorFront, lambert);
    baseColor *= rampColor * mainLight.color * occlusion;
#endif
    
    // Specular
    float3 specularColor = 0;
    float specularIntensity = 0;
    float specularThreshold = _SpecularThreshold;
#if _SPECULARSORT_BLINNPHONG
    specularIntensity = pow(NdotH,_SpecularExpon);
#elif _SPECULARSORT_PARALLEL
    float t = 0;
    float d = distance(_WorldSpaceCameraPos.xyz,positionWS);
    float3 virLightPosWS = positionWS + L * d;
    float3 rayEye2Light = virLightPosWS - _WorldSpaceCameraPos.xyz;
    t = -dot(H,rayEye2Light);
    //t = dot(H,input.tangentWS);
    specularIntensity = t;
#endif    
    float nonMetalSpecular = step(1.04 - specularIntensity, specularThreshold) * _SpecularKsNonMetal;
    float metalSpecular = specularIntensity * specularThreshold * _SpecularKsMetal;
    
    float metallic = 0;
 #if METALLICMAP
    metallic = tex2D(_MetallicMap,input.uv).r;
#else
    metallic = _Metallic;
#endif
 
    //metallic = saturate((abs(blinnPhongThreshold - 0.52) - 0.1) / (0 - 0.1));
    specularColor = lerp(nonMetalSpecular,metalSpecular *baseColor,metallic);
    specularColor *= mainLight.color * mainLight.distanceAttenuation * mainLight.shadowAttenuation;
    specularColor *= _SpecularBrightness;

    
    // Get Additional Light Shadow
    float3 additionLightColor = 0;
    uint pixelLightCount = GetAdditionalLightsCount();

    for (uint lightIndex = 0; lightIndex < pixelLightCount; lightIndex++)
    {
        //FORWARD_PLUS_SUBTRACTIVE_LIGHT_CHECK

        Light light = GetAdditionalLight(lightIndex, positionWS, shadowMask);
        
        lambert = smoothstep(_ShadowThresholdCenter - _ShadowThresholdSoftness, _ShadowThresholdCenter + _ShadowThresholdSoftness, dot(normalWS,light.direction) * 0.5 + 0.5);
        additionLightColor += light.color * light.distanceAttenuation * light.shadowAttenuation * lambert;

    }
    
    
    
    // 边缘光计算
    float3 rimLightColor = 0;
#if RIMLIGHT
    float linearEyeDepth = LinearEyeDepth(positionCS.z, _ZBufferParams);
    float3 normalVS = mul((float3x3) UNITY_MATRIX_V, normalWS);
    float2 uvOffset = float2(sign(normalVS.x), 0) * _RimLightWidth / (1 + linearEyeDepth) / 100;
    int2 loadTexPos = positionCS.xy + uvOffset * _ScaledScreenParams.xy;
    loadTexPos = min(max(loadTexPos, 0), _ScaledScreenParams - 1);
    float offsetSceneDepth = LoadSceneDepth(loadTexPos);
    float offsetLinearEyeDepth = LinearEyeDepth(offsetSceneDepth, _ZBufferParams);
    float rimLight = saturate(offsetLinearEyeDepth - (linearEyeDepth + _RimLightThreshold)) / _RimLightFadeout;
    rimLightColor = rimLight * mainLight.color.rgb;
    rimLightColor *= _RimLightTintColor;
    rimLightColor *= _RimLightBrightness * NdotL;
#endif
    
    // frenelColor
    float3 fresnelColor = 0;
#if FRESNELBRIGHTEN
    fresnelColor = _FresnelIntensity * Fresnel4 * _FresnelColor;
#endif
    //curvature
        float4 tangentOS = input.tangentOS;
    float curvature = 0;
    //1 / length(cross(input.normalOS, tangentOS));
    curvature = dot(normalize(ddx(normalWS)), normalize(ddy(normalWS))) * _StructureHiighLitIntensity;
    curvature = length(fwidth(normalWS)) / length(fwidth(positionWS)) * _StructureHiighLitIntensity;
    curvature = length(fwidth(normalWS));
    curvature = abs(ddx(positionWS));
    
    curvature *= _StructureHiighLitIntensity;
    
#if SSR
    float3 SSRColor = 0;
    float3 reflectionDir = reflect(cameraDir, normalWS);
    SSRColor = SSRRayMarching(positionWS, reflectionDir, normalWS, _RayLength,_RaySteps, _MinLostDist);
#endif

    
    float depth = 0;
    float2 uv = positionCS.xy / _ScreenParams.xy;
    float tdepth = LinearEyeDepth(SampleSceneDepth(uv), _ZBufferParams);
    //depth = TransformViewToClipDepth(positionCS.w);
    //depth = positionCS.w;
    float dist = distance(_WorldSpaceCameraPos.xyz, positionWS);
    depth = tdepth < positionCS.w ? 1 : 0;
    
    float3 color = 0;
    color = baseColor;
    
    //color = lambert;
    
    color += indirectLightColor;
    color += additionLightColor;
    color += specularColor;
    color += rimLightColor;
    color += fresnelColor;
    
    //color = recieveShadow;
    //color = curvature;
    //color =  normalWS;
    //color = lambert;
    //color = dot(normalWS, L);
    //color = occlusion;
    //color = depth;
    //color = float3(uv, 0);
    //float3 rDir = normalize(reflect(V, normalWS));
    //color = rDir;
    //color = positionWS + rDir *2;
    //color = H;
    //color = additionLightColor;
    //color += baseColor;
    
    //color = specularIntensity;
    //color = input.tangentWS;
    //color = normalWS;
    //color = specularColor;
#if SSR
    color = SSRColor;
#endif
    
    float4 res = float4(color, 1);
    return res;
}