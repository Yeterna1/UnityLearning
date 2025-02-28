Shader "Custom/SectionRenderingV2"
{
    Properties
    {
        [Header(RenderType)]
        [Toggle]_RenderType("InnerRender",float) = 0
        
        [Header(FrontParams)]
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Edge)]
        _EdgeThreshold("Edge THreshold",float) = 0.1
        _EdgeFadeout("Edge Fadeout",Range(0,1)) = 0.5
        [HDR]_EdgeColor("Edge Color",color) =  (1,1,1,1)

        [Header(Section)]
        _SectionTex("Section Texture",2D) = "white"{}
        _SectionColor ("Section Color", Color) = (1,0,0,1)
        _CutoffPlane ("Cutoff Plane", Vector) = (0,1,0,0)

        [Header(SectionRayMarch)]
        [Toggle]_Inverse("Inverse",float) = 0
        _MaxStep("MaxStep",float) = 20

        [Header(UV)]
        [Space(20)]
        _UVSuoFang("Scale UV",vector) = (0,0,0,0)
        _Tling("Tling",vector) = (0,0,0,0)

        [Header(Params)]
        _VniuquV("VV",float) = 1
        _VniuquU("VU",float) = 1
        _VniuquInt("Vint",float) = 1

        [Header(Starry Sky)]
        [NoScaleOffset]_StarrySkyTex("Starry Sky Texture", 2D) = "white" {}
        [HDR]_StarrySkyColor("Starry Sky Color",color) = (1,1,1,1)
        _StarrySkyParams("Starry Sky Speed Scale",vector) = (0.01,0.01,1,1)
        _StarrySkyPow("Starry Sky Brightness Pow",float) = 1
        _StarrySkyParallax("Starry Sky Parallax Intensity",float) = 1
        

        [Header(Star)]
        [NoScaleOffset]_StarTex1("Star Texture(First)",2D) = "white" {}
        _StarColor1("Star1 Color",color) = (1,1,1,1)
        _StarParams1("Star1 Speed Scale",vector) = (0.01,0.01,1,1)
        [NoScaleOffset]_StarTex2("Star Texture(Second)",2D) = "white" {}
        _StarColor2("Star2 Color",color) = (1,1,1,1)
        _StarParams2("Star2 Speed Scale",vector) = (0.01,0.01,1,1)

        [Header(Sky)]
        _SkyPow("Sky Pow",float) = 1
        _SkyBrightness("Sky Brightness",float) = 1
        _SkyColor("Sky Color",color) = (1,1,1,1)

        [Header(Meteor)]
        _MeteorColor("Meteor Color",color) = (1,1,1,1)
        _MeteorParams("Meteor Aspect(xy) Size(z)",vector) = (1,0.5,1,1)
        _Rotate("Meteor MoveDirection Rotate",float) = 1
        _MeteorSpeed("Meteor Speed",float) = 1
        _YMask("World Space Y Aixs Mask Pow",float) = 1

        [Header(MeteorTrailing)]
        _MeteorTrailParams("MeteorTrailParams SizeXY(x>y) Eclosion",vector) = (1,0,1,0)


        [Header(Noise)]
        _NoiseTex("Noise Texture",2D) = "white"{}
        _NoiseSpeed("Noise Speed",float) = 1



        [Header(Surface Options)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull(" Cull ( Default back)", Float) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendMode (" Src blend mode( Default One)", Float) =1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendMode (" Dst blend mode ( Default Zero)", Float) =0 
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp(" Blend operation ( Default Add)", Float) = 0
        [Enum(Off,0,On,1)] _ZWrite("ZWrite ( Default On)", Float) = 1
        _StencilRef (" Stencil reference ( Default 0)", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil comparison(Default disabled)", Int) =0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPassOp ("Stencil pass operation(Default keep)", Int) =0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFailOp ("Stencil fail operation(Default keep)", Int) =0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilZFailOp("5tencil Z fail operation(Default keep)", Int) =0

        [Header( Draw Overlay)]
        [Toggle(DRAW_OVERLAY)] _UseDrawOverlay("Use draw overlay (Default NO)", float) = 0
        [Enum(UnityEngine.Rendering.CullMode)] _OverDrawCull("OverDraw Cull ( Default back)", Float) = 2
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlendModeOverlay ("Overlay pass src blend mode(Default One)", Float) =1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendModeOverlay ("Overlay pass dst blend mode(Default Zero)", Float) =0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOpOverlay ("Overlay pass blend operation (Default Add)", Float) =0
        _StencilRefOverlay("Overlay pass stencil reference(Default 0)", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilCompOverlay ("Dverlay pass stencil comparison(Default disabled)", Int) =0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPassOpOverlay ("Stencil pass operation(Default keep)", Int) =0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFailOpOverlay ("Stencil fail operation(Default keep)", Int) =0
    }

    SubShader
    {
        //Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        HLSLINCLUDE

        #pragma shader_feature_local DRAW_OVERLAY

        float _RenderType;
        float4 _ConeParams;
        float4 _ConeParams2;
        float4x4 _WorldToConeSpace;

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" 
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" 
        #include "Assets/ShaderLibrary/MyFunctions.hlsl"

        // SDF函数定义
            float sdCone(float3 p, float2 c, float h) {
                float2 q = h * float2(c.x/c.y, -1.0);
                float2 w = float2(length(p.xz), p.y);
                float2 a = w - q*clamp( dot(w,q)/dot(q,q), 0.0, 1.0 );
                float2 b = w - q*float2( clamp( w.x/q.x, 0.0, 1.0 ), 1.0 );
                float k = sign( q.y );
                float d = min(dot(a,a), dot(b,b));
                float s = max( k*(w.x*q.y - w.y*q.x), k*(w.y - q.y) );
                return sqrt(d) * sign(s);
            }

            float3 ProjectToConeSurface(float3 localPos)
            {
                // SDF参数提取
                float2 c = _ConeParams.xy; // (sinθ, cosθ)
                float h = _ConeParams.z;   // 高度

                // 几何参数计算
                float2 q = h * float2(c.x/max(c.y,0.001), -1.0); // 底面边缘点参数化
                float2 w = float2(length(localPos.xz), localPos.y); // 二维投影

                // 计算两种可能投影方式
                float2 a = w - q * clamp(dot(w,q)/dot(q,q), 0.0, 1.0); // 锥面投影
                float2 b = w - q * float2(clamp(w.x/q.x, 0.0, 1.0), 1.0); // 底面投影

                // 选择最近投影方式
                float2 nearest = dot(a,a) < dot(b,b) ? w-a : w-a;

                // 重建三维坐标
                float3 surfacePos = float3(
                    nearest.x * localPos.xz,// / max(w.x, 0.01), // 防止除零
                    nearest.y
                );
    
                return surfacePos;
            }

            float2 CalculateConeUV(float3 localPos)
            {
                // 参数解包
                float invHeight = 1/max(_ConeParams.x,1e-5);    // 1/高度
                float angleFactor = _ConeParams.w;  // 1/(2π)
                float maxRadius = (_ConeParams.x/max(_ConeParams.y,0.001))*_ConeParams.z;    // 底面最大半径
                float tiling = 1.0;       // 平铺系数

                // 高度分量计算
                float u = localPos.y;// * invHeight);  // 归一化到[0,1]

                // 圆周分量计算
                float radius = length(localPos.xz);          // 当前高度的半径
                float angle = atan2(localPos.z, localPos.x); // 极角计算（-π到π）
                angle = angle < 0 ? angle + 1/angleFactor : angle;    // 转换到0-2π范围
                float v = angle * angleFactor;               // 归一化到[0,1]

                // 径向缩放补偿
                float circumference = 1/angleFactor * maxRadius * u; // 当前高度的周长
                v *= circumference / maxRadius * tiling;     // 动态缩放补偿
                v = localPos.x;

                return float2(v,u);
            }

            // rayMarching 获取hitPos作为映射Pos
            float3 RayMarchingConeSpace(float3 rayStart,float3 rayEnd,float2 sdfc,float sdfh,float maxStep,float reverse){
                float3 curPos= rayStart+(rayEnd-rayStart)*reverse;
                float3 rayDir = normalize(rayEnd - rayStart +2*(rayStart-rayEnd)*reverse);
                //float totalLength = length(rayEnd-rayStart);
                float rayStep = abs(sdCone(curPos,sdfc,sdfh));

                UNITY_LOOP
                for (int i = 0; i < maxStep && rayStep > 0.01; i++) {  
                    // 步近  
                    curPos += rayDir * rayStep;
                    rayStep = abs(sdCone(curPos,sdfc,sdfh));
                }
                return curPos;
            }

            float GetMeteor(float2 aspect, float size, float density, float time, float speed, float rotate, float2 uv)
            {
                // 应用速度 两小时一个循环
                float t = fmod(time * speed, 7200.0);

                float2 inituv = uv * aspect;
                // UV旋转
                float2 uv_centered = inituv - float2(0.5, 0.5);
                // 转换为弧度（建议使用内置函数）
                float radians = rotate * 0.01745329;
                float cos_theta = cos(radians);
                float sin_theta = sin(radians);
                // 应用旋转矩阵
                float y_rotated = uv_centered.x * sin_theta + uv_centered.y * cos_theta;
                float x_rotated = uv_centered.x * cos_theta - uv_centered.y * sin_theta;
                // 平移回原坐标系
                float2 uv_rotated = float2(x_rotated, y_rotated);// + float2(0.5, 0.5);
                // 将uv划分成多个小块
                uv_rotated *= size;
                uv_rotated.y += t * 0.25;


                // id应用于每一块自己的特殊随机变化
                float id = N21(floor(uv_rotated));
                float offsety = N(floor(uv_rotated.x));
                float2 offset = float2( 0 , N(floor(uv_rotated.x))*0.1);
                //t += 3.1415 * 2.0 * offset.x;
    
                float2 cuv = frac(uv_rotated+offset);
    
                offset = float2(0,N(floor(uv_rotated+offset)));
                cuv -= offset*0.5;
    
                float uZheZhao = smoothstep(10.0 * 0.01, 7.0 * 0.01, cuv.x);
                float vZheZhao = smoothstep(9.0 * 0.01, 11.0 * 0.01, cuv.y);
                float smoothness = smoothstep(100.0 * 0.01, -100.0 * 0.01, cuv.y);
    
                float res = uZheZhao * vZheZhao * smoothness;
                //res = smoothness;
                //res = uZheZhao * vZheZhao;
                res *= res;
                res *= 2.0;

                return res;
            }

            float2 GetMeteorUV(float2 aspect, float size, float density, float time, float speed, float rotate, float2 uv)
            {
                // 应用速度 两小时一个循环
                float t = fmod(time * speed, 7200.0);

                float2 inituv = uv * aspect;
                // UV旋转
                float2 uv_centered = inituv - float2(0.5, 0.5);
                // 转换为弧度（建议使用内置函数）
                float radians = rotate * 0.01745329;
                float cos_theta = cos(radians);
                float sin_theta = sin(radians);
                // 应用旋转矩阵
                float y_rotated = uv_centered.x * sin_theta + uv_centered.y * cos_theta;
                float x_rotated = uv_centered.x * cos_theta - uv_centered.y * sin_theta;
                // 平移回原坐标系
                float2 uv_rotated = float2(x_rotated, y_rotated) + float2(0.5, 0.5);
                // 将uv划分成多个小块
                uv_rotated *= size;
                uv_rotated +=float2(0, t * 0.25);
                //uv_rotated += float2(0,0.5);


                // id应用于每一块自己的特殊随机变化
                float id = N21(floor(uv_rotated));
                float offsety = N(floor(uv_rotated.x));
                float2 offset = float2( 0 , N(floor(uv_rotated.x))*0.1);
                //t += 3.1415 * 2.0 * offset.x;
    
                float2 cuv = frac(uv_rotated+offset);
    
                offset = float2(0,N(floor(uv_rotated+offset)));
                cuv -= offset*0.5;
    
    
                float2 res = cuv;
   

                return res;
            }

        ENDHLSL

        // Pass 1: 正常渲染正面并裁剪
        Pass
        {
            Tags{
                "RenderPipeline"="UniversalRenderPipeline"
                "RenderType" = "Opaque"
            }

            Cull[_Cull]
            Stencil{
                Ref [_StencilRef]
                Comp [_StencilComp]
                Pass [_StencilPassOp]
                Fail [_StencilFailOp]
                ZFail [_StencilZFailOp]
            }
            Blend [_SrcBlendMode] [_DstBlendMode]
            BlendOp [_BlendOp]
            ZWrite [_ZWrite]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            // #include "Assets/ShaderLibrary/SectionRender.hlsl"

            struct appdata { 
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0; // 添加UV输入
            };
            struct v2f { 
                float4 pos : SV_POSITION; 
                float3 worldPos : TEXCOORD0; 
                float2 uv : TEXCOORD1; 
            };

            sampler2D _MainTex;
            float4 _MainTex_ST; // 添加纹理缩放偏移变量
            float4 _CutoffPlane;

            // ConeParams
            float4 _ConeTipWorldPos;
            float4 _ConeDirectionWorld;
            float _ConeHeight;
            float _ConeBaseRadius;

            // Edge
            float _EdgeThreshold;
            float _EdgeFadeout;
            float4 _EdgeColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex); // 正确传递UV
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                float3 localPos = mul(_WorldToConeSpace,float4(i.worldPos,1)).xyz;
                float isInnerRender = -_RenderType*2+1;
                float distance = sdCone(localPos,_ConeParams.xy,_ConeParams.z) * isInnerRender;

                clip(distance);

                float outEdgeMask = smoothstep(_EdgeThreshold*_EdgeFadeout-0.001,_EdgeThreshold,distance); 

                float3 col = tex2D(_MainTex, i.uv);
                col = col * outEdgeMask + (1-outEdgeMask) * _EdgeColor;

                return float4(col,1);
            }
            ENDHLSL
        }

        //Pass 2: 渲染背面截面
        Pass
        {
            Name "DrawOverlay"
            Tags {
                "LightMode" = "UniversalForward"
                "RenderPipeline" = "UniversalPipeline"
                "RenderType" = "Opaque"
            }

            Cull[_OverDrawCull]
            Stencil{
                Ref [_StencilRefOverlay]
                Comp [_StencilCompOverlay]
                Pass [_StencilPassOpOverlay]
                Fail [_StencilFailOpOverlay]
            }
            Blend [_SrcBlendModeOverlay] [_DstBlendModeOverlay]
            BlendOP [_BlendOpOverlay]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                //float3 SH : TEXCOORD1;
                float3 normalOS : NORMAL;
                float3 normalWS : TEXCOORD2;
                float3 viewDirectionWS : TEXCOORD3;
                float3 positionWS : TEXCOORD4;
                float4 tangentOS : TEXCOORD5;
                float4 positionOS:TEXCOORD6;
            };

            sampler2D _MainTex;
            sampler2D _SectionTex;
            float4 _CutoffPlane;
            float4 _SectionColor;

            float _Inverse;
            float _MaxStep;

            float4 _ConeTipWorldPos;
            float4 _ConeDirectionWorld;
            float _ConeHeight;
            float _ConeBaseRadius;

            // maybe delete
            float4 _UVSuoFang;
            float4 _Tling;
            float _LiuXingSpeed;
            float4 _XingKong1Speed;
            float4 _XingKong2Speed;
            float4 _XingKongOffset;
            

            float _MainTexPow;
            float _XingkongPow;
            float _XingKongLiangDu;
            float _VniuquV;
            float _VniuquU;
            float _VniuquInt;
            float2 _YuandianDaXiao;
            float2 _Tuowei;
            float _TuoweiYuHua;

            // Starry Sky
            sampler2D _StarrySkyTex;
            float4 _StarrySkyTex_ST;
            float4 _StarrySkyColor;
            float4 _StarrySkyParams;
            float _StarrySkyPow;
            float _StarrySkyParallax;

            // Star
            sampler2D _StarTex1;
            float4 _StarColor1;
            float4 _StarParams1;
            sampler2D _StarTex2;
            float4 _StarColor2;
            float4 _StarParams2;

            //Sky
            float _SkyPow;
            float _SkyBrightness;
            float4 _SkyColor;

            //Meteor
            float4 _MeteorColor;
            float4 _MeteorParams;
            float _Rotate;
            float _MeteorSpeed;
            float _YMask;

            // MeteorTrailing
            float4 _MeteorTrailParams;

            //Noise
            sampler _NoiseTex;
            float _NoiseSpeed;


            Varyings vert(Attributes input)
            {
                Varyings output;
                
                output.positionOS =input.positionOS;

                VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    
                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.positionWS = TransformObjectToWorld(input.positionOS);
                output.uv = TRANSFORM_TEX(input.uv, _StarrySkyTex);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                //output.SH = SampleSH(lerp(output.normalWS, float3(0, 0, 0), _IndirectLightFlattenNormal));
                output.normalOS = input.normalOS;
                output.viewDirectionWS = _WorldSpaceCameraPos.xyz - output.positionWS;
                output.tangentOS = input.tangentOS;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {

                float4 positionCS = input.positionCS;
                float3 positionWS = input.positionWS;
                float shadowMask = 1;
                float4 shadowCoord = TransformWorldToShadowCoord(positionWS);
                float3 normalWS = normalize(input.normalWS);
                Light mainLight = GetMainLight(shadowCoord, positionWS, shadowMask);
                float3 L = normalize(mainLight.direction);
                float3 V = normalize(input.viewDirectionWS);
                float3 H = normalize(mainLight.direction + V);
                //float3 cameraDir = _WorldSpaceCameraDir;
    
                // 假设你已经有了世界空间的法线和切线
                float3 worldNormal = TransformObjectToWorldNormal(input.normalOS);
                float3 worldTangent = TransformObjectToWorldDir(input.tangentOS.xyz);
                float3 cameraDir = GetViewForwardDir();
                float tangentSign = input.tangentOS.w; // 切线.w分量，用于确定副切线的方向
                float3 worldBitangent = cross(worldNormal, worldTangent) * tangentSign;

                // 构建TBN矩阵
                float3x3 TBN = float3x3(worldTangent, worldBitangent, worldNormal);
                float3 cameraDirTS = TransformWorldToTangentDir(V, TBN);
                float3 viewDirTS = mul(TBN, cameraDir) * float3(1,1,-1);
                //viewDirTS = mul(TBN, V) * float3(1, 1, -1);
    
                float3 oneDivideViewDirTS = 1 / viewDirTS;

                float NdotL = saturate(dot(normalWS, L));
                float NdotH = saturate(dot(normalWS, H));
                float NdotV = saturate(dot(normalWS, V));
                float LdotH = saturate(dot(L, H));
                float VdotH = saturate(dot(V, H));


                // 获取锥体坐标系的位置
                float3 localPos = mul(_WorldToConeSpace,float4(positionWS,1)).xyz;
                float3 cameraPosConeLocalSpace = mul(_WorldToConeSpace,float4(_WorldSpaceCameraPos.xyz,1)).xyz;
                //localPos = mul(_WorldToConeSpace,positionWS);

                float3 surfacePos = RayMarchingConeSpace(cameraPosConeLocalSpace,localPos,_ConeParams.xy,_ConeParams.z,_MaxStep,_Inverse);
                // 获取重映射uv
                float2 uv = CalculateConeUV(surfacePos);
                /////////////////
                //// end ////////
                ////////////////

                float isInnerRender = -_RenderType*2+1;
                float distance = sdCone(localPos,_ConeParams.xy,_ConeParams.z) * isInnerRender;
                //float isOutside = IsPointInsideCone(positionWS,_ConeTipWorldPos,_ConeDirectionWorld,_ConeHeight,_ConeBaseRadius);

                clip(distance);

                float3 viewPos = TransformWorldToView(positionWS);
			    float3 objectOriginViewPos = TransformWorldToView(TransformObjectToWorld(float3(0.0, 0.0, 0.0)).xyz);
                float2 vSubT = float2((viewPos-objectOriginViewPos).xy) * _StarrySkyParallax + 1 - _StarrySkyParallax;

                float nDotl = NdotL * 0.5 + 0.5;

                //向量计算
                float YMask = 1 - pow(abs(worldNormal.y), _YMask);

                //UV获取
                float2 texUV = (uv + (_StarrySkyParams.xy * _Time.y)) * _StarrySkyParams.zw;
                float2 star1UV = (uv + (_StarParams1.xy * _Time.y)) * _Tling.y + _StarParams1.zw;
                float2 star2UV = (uv + (_StarParams2.xy * _Time.y)) * _Tling.y + _StarParams2.zw;

                //星空贴图
                float noise = tex2D(_NoiseTex, (uv + (_NoiseSpeed * _Time.y)));
                float starrySky = tex2D(_StarrySkyTex, texUV).r * _StarrySkyPow;
                float star1 = tex2D(_StarTex1, star1UV).r;
                float star2 = tex2D(_StarTex2, star2UV).r;
                float skyPow = max(pow((starrySky + star1 + star2), _SkyPow), 0.0);
                float skyMask = noise * skyPow * _SkyBrightness;

                // 星空
                float3 starrySkyColor = _StarrySkyColor;
                float3 skyColor = _SkyColor;
                float3 starColor1 = _StarColor1;
                float3 starColor2 = _StarColor2;
                float3 sky = (starrySky * starrySkyColor + star1*starColor1  + star2*starColor2) * skyMask * skyColor;

                //流星
                float meteorMask = 0;//GetMeteor(_MeteorParams.xy, _MeteorParams.z,0.4, _Time.y, _MeteorSpeed,_Rotate, surfacePos.yx*0.1);
                //float2 meteorMask = GetMeteorUV(_MeteorParams.xy, _MeteorParams.z,0.4, _Time.y, _MeteorSpeed,_Rotate, surfacePos.xy);
                float3 meteor = meteorMask.x * _MeteorColor;

                float3 col = (sky * (1- meteor)+ meteor);

               // col = meteorMask;
                //col = float3(meteorMask,0);
                //col = float3(uv,0);
                
                //col = tex2D(_StarrySkyTex,float2(surfacePos.xy));
                //col = tex2D(_StarrySkyTex,float2(surfacePos.x,0));
                //col = tex2D(_StarrySkyTex,uv);
                // //col = tex2D(_StarrySkyTex,positionWS.xy);
                //col = float3(uv,0);
                //col = surfacePos;

                return float4(col,1);
            }

            ENDHLSL
        }
    }
}