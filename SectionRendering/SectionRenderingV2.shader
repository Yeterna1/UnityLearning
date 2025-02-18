Shader "Custom/SectionRenderingV2"
{
    Properties
    {
        [Header(FrontParams)]
        _MainTex ("Texture", 2D) = "white" {}

        _SectionTex("Section Texture",2D) = "white"{}
        _SectionColor ("Section Color", Color) = (1,0,0,1)
        _CutoffPlane ("Cutoff Plane", Vector) = (0,1,0,0)

        [Header(UVReference)]
        [KeywordEnum(Tex,ObjectSpace,WorldSpace,ViewSpace,ScreenSpace)] _Reference("UV Reference",float) = 0

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

        #pragma shader_feature_local _REFERENCE_TEX
        #pragma shader_feature_local _REFERENCE_OBJECTSPACE
        #pragma shader_feature_local _REFERENCE_WORLDSPACE
        #pragma shader_feature_local _REFERENCE_VIEWSPACE
        #pragma shader_feature_local _REFERENCE_SCREENSPACE

        #pragma shader_feature_local DRAW_OVERLAY

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

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Assets/ShaderLibrary/SectionRender.hlsl"

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
                float isOutside = IsPointInsideCone(i.worldPos,_ConeTipWorldPos,_ConeDirectionWorld,_ConeHeight,_ConeBaseRadius);

                clip(isOutside);
                return tex2D(_MainTex, i.uv);
            }
            ENDHLSL
        }

        // Pass 2: 渲染背面截面
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
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" 
            #include "Assets/ShaderLibrary/MyFunctions.hlsl"

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

                float isOutside = IsPointInsideCone(positionWS,_ConeTipWorldPos,_ConeDirectionWorld,_ConeHeight,_ConeBaseRadius);

                clip(isOutside);

                float3 viewPos = TransformWorldToView(positionWS);
			    float3 objectOriginViewPos = TransformWorldToView(TransformObjectToWorld(float3(0.0, 0.0, 0.0)).xyz);
                float2 vSubT = float2((viewPos-objectOriginViewPos).xy) * _StarrySkyParallax + 1 - _StarrySkyParallax;

                float nDotl = NdotL * 0.5 + 0.5;

                //向量计算
                float YMask = 1 - pow(abs(worldNormal.y), _YMask);

                //UV旋转
                // 平移至中心
                float2 uv_centered = input.uv - float2(0.5, 0.5);
                // 转换为弧度（建议使用内置函数）
                float radians = _Rotate * 0.01745329;
                float cos_theta = cos(radians);
                float sin_theta = sin(radians);
                // 应用旋转矩阵
                float x_rotated = uv_centered.x * sin_theta + uv_centered.y * cos_theta;
                float y_rotated = uv_centered.x * cos_theta - uv_centered.y * sin_theta;
                // 平移回原坐标系
                float2 uv_rotated = float2(x_rotated, y_rotated);// + float2(0.5, 0.5);

                //UV获取
                float2 uv1 = uv_rotated.xy * _UVSuoFang.xy * _Tling.x;
                float2 uv2 = float2(uv1.x, uv1.y + _Time.y * _MeteorSpeed);
                float2 uv3 = frac(uv2) + _UVSuoFang.zw;
                float2 texUV = (vSubT + (_StarrySkyParams.xy * _Time.y)) * _StarrySkyParams.zw;
                float2 star1UV = (input.uv + (_StarParams1.xy * _Time.y)) * _Tling.y + _StarParams1.zw;
                float2 star2UV = (input.uv + (_StarParams2.xy * _Time.y)) * _Tling.y + _StarParams2.zw;

                //星空贴图
                float noise = tex2D(_NoiseTex, (input.uv + (_NoiseSpeed * _Time.y)));
                float starrySky = tex2D(_StarrySkyTex, texUV).r * _StarrySkyPow;
                float star1 = tex2D(_StarTex1, star1UV).r;
                float star2 = tex2D(_StarTex2, star2UV).r;
                float skyPow = max(pow((starrySky + star1 + star2), _SkyPow), 0.0);
                float skyMask = noise * skyPow * _SkyBrightness;

                //运动速度随机值
                float2 suiji = dot(floor(uv2), float2( 12.9898,78.233 ));
                float suiji1 = lerp(0.0 ,1.0 ,frac((sin(suiji)*43758.55)));
                float Vspeed = cos(_Time.y + suiji1 * 3564.156) * -0.4;
                float Uspeed = tan(input.uv.y * _VniuquV * _VniuquU) * _VniuquInt;
                float u = (uv3.x - Uspeed);
                float v = (uv3.y - Vspeed);
                float2 uv4 = float2(u, v);

                // 星空
                float3 starrySkyColor = _StarrySkyColor;
                float3 skyColor = _SkyColor;
                float3 starColor1 = _StarColor1;
                float3 starColor2 = _StarColor2;
                float3 sky = (starrySky * starrySkyColor + star1*starColor1  + star2*starColor2) * skyMask * skyColor;

                //流星
                float2 ruv = float2(0,0);
                #if _REFERENCE_TEX
                    ruv = input.uv;
                #elif _REFERENCE_OBJECTSPACE
                    ruv = input.positionOS.xy;
                #elif _REFERENCE_WORLDSPACE
                    ruv = positionWS.xy;
                #elif _REFERENCE_VIEWSPACE
                    ruv = vSubT;
                #elif _REFERENCE_SCREENSPACE
                    //ruv = 
                #endif
                    
                float meteorMask = GetMeteor(_MeteorParams.xy, _MeteorParams.z, _Time.y, _MeteorSpeed, ruv);
                float3 meteor = meteorMask * _MeteorColor;

                float3 col = (sky * (1- meteor)+ meteor);

                return float4(col,1);
            }

            ENDHLSL
        }
    }
}