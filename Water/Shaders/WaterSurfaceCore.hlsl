#include"WaterSurfaceFunctions.hlsl"

struct appdata
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};

struct v2f
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    //float3 lightDir:TEXCOORD1;
    float3 SH : TEXCOORD1;
    float3 normalOS : NORMAL;
    float3 normalWS : TEXCOORD2;
    float3 viewDir : TEXCOORD3;
    float3 worldPos : TEXCOORD4;
};

struct PatchTess
{
    float edgeFactor[3] : SV_TESSFACTOR;
    float insideFactor : SV_INSIDETESSFACTOR;
};

struct HullOut
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    //float3 lightDir:TEXCOORD1;
    float3 SH : TEXCOORD1;
    float3 normalOS : NORMAL;
    float3 normalWS : TEXCOORD2;
    float3 viewDir : TEXCOORD3;
    float3 worldPos : TEXCOORD4;
};

struct DomainOut
{
    float2 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    //float3 lightDir:TEXCOORD1;
    float3 SH : TEXCOORD1;
    float3 normalOS : NORMAL;
    float3 normalWS : TEXCOORD2;
    float3 viewDir : TEXCOORD3;
    float3 worldPos : TEXCOORD4;
};


v2f vert(appdata v)
{
    v2f o;
    o.vertex = TransformObjectToHClip(v.vertex);
    float3 worldPos = TransformObjectToWorld(v.vertex);
    o.uv = v.uv;
    o.normalWS = TransformObjectToWorldNormal(v.normal);
    o.normalOS = v.normal;
    //o.SH = SampleSH(lerp(o.normalWS, float3(0, 0, 0), _IndirectLightFlattenNormal));
    o.worldPos = TransformObjectToWorld(v.vertex);
    o.viewDir = _WorldSpaceCameraPos.xyz - worldPos;
    //float3 positionWS = TransformObjectToWorld(v.vertex);
    return o;
}

PatchTess PatchConstant(InputPatch<v2f, 3> patch, uint patchID : SV_PrimitiveID)
{
    PatchTess o;
    o.edgeFactor[0] = _EdgeFactor;
    o.edgeFactor[1] = _EdgeFactor;
    o.edgeFactor[2] = _EdgeFactor;
    o.insideFactor = _InsideFactor;
    return o;
}

[domain("tri")]
#if _PARTITIONING_INTEGER
            [partitioning("integer")] 
#elif _PARTITIONING_FRACTIONAL_EVEN
            [partitioning("fractional_even")] 
#elif _PARTITIONING_FRACTIONAL_ODD
            [partitioning("fractional_odd")]    
#endif 

#if _OUTPUTTOPOLOGY_TRIANGLE_CW
            [outputtopology("triangle_cw")] 
#elif _OUTPUTTOPOLOGY_TRIANGLE_CCW
            [outputtopology("triangle_ccw")] 
#endif

[patchconstantfunc("PatchConstant")]
[outputcontrolpoints(3)]
[maxtessfactor(64.0f)]
HullOut FlatTessControlPoint(InputPatch<v2f, 3> patch, uint id : SV_OutputControlPointID)
{
    HullOut o;
    o.vertex = patch[id].vertex;
    o.uv = patch[id].uv;
    o.SH = patch[id].SH;
    o.normalOS = patch[id].normalOS;
    o.normalWS = patch[id].normalWS;
    o.viewDir = patch[id].viewDir;
    o.worldPos = patch[id].worldPos;
    return o;
}


[domain("tri")]
DomainOut FlatTessDomain(PatchTess tessFactors, const OutputPatch<HullOut, 3> patch, float3 bary : SV_DOMAINLOCATION)
{

    float4 vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
    float2 uv = patch[0].uv * bary.x + patch[1].uv * bary.y + patch[2].uv * bary.z;
    float3 SH = patch[0].SH * bary.x + patch[1].SH * bary.y + patch[2].SH * bary.z;
    float3 normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
    float3 normalWS = patch[0].normalWS * bary.x + patch[1].normalWS * bary.y + patch[2].normalWS * bary.z;
    float3 viewDir = patch[0].viewDir * bary.x + patch[1].viewDir * bary.y + patch[2].viewDir * bary.z;
    float3 worldPos = patch[0].worldPos * bary.x + patch[1].worldPos * bary.y + patch[2].worldPos * bary.z;

    DomainOut output;
    //output.vertex = TransformObjectToHClip(vertex);
    //output.uv = uv;
    //output.normalWS = TransformObjectToWorldNormal(normalOS);
    //output.normalOS = normalOS;
    ////o.SH = SampleSH(lerp(o.normalWS, float3(0, 0, 0), _IndirectLightFlattenNormal));
    //output.worldPos = TransformObjectToWorld(vertex);
    //output.viewDir = _WorldSpaceCameraPos.xyz - output.worldPos;
    //float3 positionWS = TransformObjectToWorld(vertex.xyz);
    //// 通过世界坐标获取阴影坐标位置
    //output.shadowCoord = TransformWorldToShadowCoord(positionWS);
    float4 displcae = tex2Dlod(_WaterSurfaceDisplace, float4(uv, 0, 0));
    output.vertex = vertex + float4(0,displcae.y,0, 0) * _DisplaceIntensity;
    output.uv = uv;
    output.normalWS = normalWS;
    output.normalOS = normalOS;
    //o.SH = SampleSH(lerp(o.normalWS, float3(0, 0, 0), _IndirectLightFlattenNormal));
    output.worldPos = worldPos;
    output.viewDir = viewDir;
    // 通过世界坐标获取阴影坐标位置

    return output;
}

float4 frag(DomainOut i) : SV_Target
{
    float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
    // 计算阴影但是目前有误
    Light mainLight = GetMainLight(shadowCoord);
    float shadow = mainLight.shadowAttenuation;
    
    //基本量的计算
    float3 lightDir = mainLight.direction;
    
    
    float3 V = normalize(i.viewDir);
    //float3 L = normalize(i.lightDir);
    float3 L = normalize(lightDir);
    //float3 N = normalize(i.normalWS);
    float3 N = normalize(tex2D(_WaterSurfaceNormal, i.uv));
    float3 H = normalize(L + V);

    float NdotL = saturate(dot(N, L));
    float NdotH = saturate(dot(N, H));
    float NdotV = saturate(dot(N, V));
    float LdotH = saturate(dot(L, H));
    float VdotH = saturate(dot(V, H));
                
    // 计算水体基础颜色
    float3 baseColor = 1;
    // 物体像素的距离
    float linearEyeDepth = LinearEyeDepth(i.vertex.z, _ZBufferParams) * _WaterDepthRemap;
    // 实际深度
    int2 loadTexPos = i.vertex.xy;
    float sceneDepth = LoadSceneDepth(loadTexPos);
    float linearSceneDepth = LinearEyeDepth(sceneDepth, _ZBufferParams) * _WaterDepthRemap;
    float depthDifference = pow(linearSceneDepth - linearEyeDepth, _WaterDepthCoef);
#if DepthRampMap_Based_SurfaceColor
    float2 depthRampUV = float2(depthDifference,0);
    baseColor = tex2D(_DepthRamp,depthRampUV);
#else
    // 根据深度计算颜色
    baseColor = lerp(_ShallowWaterColor, _DeepWaterColor, depthDifference);
    //baseColor = depthDifference;
    //baseColor = _ShallowWaterColor;
    //baseColor = _DeepWaterColor;
#endif
    // 计算反射颜色
    float2 screenPos = i.vertex.xy / _ScreenParams.xy;
    float2 screenUV = screenPos;
    screenUV += N.zx * half2(0.01, 0.15) * sin(_Time.y) * step(_ReflectDistortScale, depthDifference) * _ReflectDistortIntensity;
    
    //float3 reflectColor = 1;
#if _REFLECTTYPE_PANELREFL
    float3 reflectColor = tex2D(_ReflectMap, screenUV);
#elif _REFLECTTYPE_SSR
    float3 reflectColor = tex2D(_SSRTexture, screenUV);
#endif
    // under mask
    float underMask = depthDifference > 0 ? 1 : 0;
    // 计算折射颜色
    screenUV = screenPos;
    screenUV += N.zx * half2(0.01, 0.15) * cos(_Time.y) * _RefractIntensity * underMask;
    float3 refractColor = tex2D(_CameraOpaqueTexture, screenUV);// * underMask;
    
    // 计算菲涅尔系数插值反射/折射
    float fresnel = CalculateFresnelTerm(N, V);
    
    // 计算高光
    float3 specular = 0;
    specular = CookTorranceSpec(NdotL, LdotH, NdotH, NdotV, _Roughness, 1) * mainLight.color;

    
    // 计算foam
    float3 foam = 0;
    float2 foamUV = TRANSFORM_TEX(i.uv,_FoamMap);
    float4 foamMap = tex2D(_FoamMap, foamUV);
    foam = foamMap.g;
    //foam += foamMap.r;
    float foamMask = step(depthDifference, _FoamScale);
    foam *= foamMask * (1 - depthDifference) * _FoamIntensity;
    // 别人的做法
    //float depthEdge = saturate(depthDifference * 20 + 1);
    //float edgeFoam = saturate(1 - depthDifference * 0.5 - 0.25) * depthEdge;
    //float foamValue = saturate((foamMap.yyy * edgeFoam));
    //foamMask = float4(foamValue.xxx * 1.5 + saturate(1 - depthDifference * 4) * 0.5, 1);
    
    // 计算焦散
    float3 caustics = 0;
    float2 causticsUV = TRANSFORM_TEX(i.uv, _CausticsMap);
     // 定义采样器状态
    // 采样屏幕空间深度
    float mydepth = SampleSceneDepth(screenUV); // 获取非线性深度值
    float3 underPlaneWS = ReconstructWorldPos(screenPos, mydepth);
    float causticsMask = step(depthDifference, _CausticsScale) * (1 - depthDifference / _CausticsScale) / _CausticsScale;
    float3 causticsMap = tex2D(_CausticsMap, underPlaneWS.xz * _CausticsDensity + N.zx  * cos(_Time.y) * _CausticsTransIntensity).b * causticsMask * _CausticsIntensity;
    //float3 causticsMap = tex2D(_CausticsMap, underPlaneWS.xz * 0.01f).b * causticsMask * _CausticsIntensity;
    
    // 计算浮沫
    float3 bubbles = 0;
    float4 bubblesMap = tex2D(_WaterSurfaceBubbles, i.uv);
    bubbles = bubblesMap.rgb * _BubblesIntensity;
    
    // 计算接受阴影
    float shadowReceive = shadow * _ShadowReceiveIntensity + 1 - _ShadowReceiveIntensity;
    
   
    
    // 计算因为深度吸收导致水底颜色减弱  boatAtk使用的是一张ramp图进行减弱计算感觉这个计算有点垃圾
    float3 surfaceColor = baseColor;

    surfaceColor = lerp(refractColor, baseColor, pow(0.5, _Transmission * (1 + depthDifference)/100));
    //surfaceColor = lerp(refractColor, baseColor, 1-underMask);
    surfaceColor = lerp(surfaceColor, reflectColor, fresnel * _ReflectIntensity);
    //surfaceColor = reflectColor;
    // 计算反射与折射作用下的表面颜色
    //surfaceColor = lerp(surfaceColor, reflectColor, fresnel);
    //surfaceColor = lerp(surfaceColor, baseColor, depthDifference);
    //surfaceColor *= baseColor;
    
    //surfaceColor = refractColor;
    // sample the texture
    float3 col = 0;
    //col = saturate(depthDifference - 1 + _ReflectDistortScale) * _ReflectDistortIntensity;
    col += surfaceColor;
    col += foam;
    col += causticsMap;
    col += bubbles;
    col += specular;
    //col *= shadowReceive;
    //col = depthDifference;
    //col = causticsMask;
    //col = causticsMap;
    //col = shadow;
    //col = reflectColor;
    //col = depthDifference;
    //col = reflectColor;
    //col = float3(i.worldPos.xz, 0);
    //col = depthDifference;
    //col += refractColor;
    //col = specular;
    
    float4 albedo = 0;
    albedo = float4(col, 1);
    //albedo = causticsMap;

    return albedo;
}