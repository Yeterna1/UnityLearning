Shader "Unlit/Tree"
{
    Properties
    {
        //_BaseMap ("Texture", 2D) = "white" {}
        [MainTexture] _BaseMap("Albedo", 2D) = "white" {}
        [MainColor] _BaseColor("Color", Color) = (1,1,1,1)
        
        [Header(Tint)]
        _TopLeaveColor("Top Leave Color",color) = (1,1,1,1)
        _BottomLeaveColor("Bottom Leave Color",color) = (0,0,0,1)

        [Header(Clip)]
        [Toggle(_ALPHATEST_ON)] _AlphaTestToggle("Alpha Clip", Float) = 0
        _Cutoff("Clip Value(Default 0)",float) = 0

        [Header(Shadow)]
        _ReceiveShadowIntensity("Receive Shadow Intensity",float) = 0
        _DiffuseIntensity("Diffuse Intensity(Default 0.9)",float) = 0.9

        [Header(Transmission)]
        _TransmissionThreshold("Transmission Threshold(Default 0)",float) = 0
        _TransmissionIntensity("Transmission Intensity(Default 0)",float) = 0
        _BackSubsurfaceDistortion("Back Subsurface Distortion(Default 0)",float) = 0

        [Header(Rim Lighting)]
        _RimIntensity("Rim Intensity",float) = 0

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
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        // Pass {
        //     Name "DepthNormals"
        //     Tags {
        //         "LightMode" = "DepthNormals"
        //     }

        //     HLSLPROGRAM
        //     #pragma vertex DepthNormalsVertex
        //     #pragma fragment DepthNormalsFragment

        //     //- Material- Keywords
        //     #pragma shader_feature_local _NORMALMAP
        //     #pragma shader_feature_local _PARALLAXMAP
        //     #pragma shader_feature_local _DETAIL_MULX2 _DETATL_SCALED
        //     #pragma shader_feature_local_fragment _ALPHATEST_ON
        //     #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

        //     sampler2D _MainTex;
        //     float _ClipValue;
            
        //     //-GPU- Instancing
        //     #pragma multi_compile_instancing
        //     #pragma multi_compile_DOTS_INSTANCING_ON

        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        //     #include "MyLitDepthNormalsPass.hlsl"
        //     ENDHLSL
        // }

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

            #pragma multi_compile _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" 
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl" 

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

            sampler2D _BaseMap;
            float4 _BaseMap_ST;

            float4 _TopLeaveColor;
            float4 _BottomLeaveColor;

            float _TransmissionThreshold;
            float _TransmissionIntensity;
            float _BackSubsurfaceDistortion;

            float _ReceiveShadowIntensity;
            float _DiffuseIntensity;

            float _Cutoff;

            float _RimIntensity;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = TransformObjectToHClip(v.vertex);
                float3 worldPos = TransformObjectToWorld(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _BaseMap);
                o.normalWS = TransformObjectToWorldNormal(v.normal);
                o.normalOS = v.normal;
                //o.SH = SampleSH(lerp(o.normalWS, float3(0, 0, 0), _IndirectLightFlattenNormal));
                o.worldPos = TransformObjectToWorld(v.vertex);
                o.viewDir = _WorldSpaceCameraPos.xyz - worldPos;
                
                return o;
            }

            float4 frag(v2f i,bool isFrontFace:SV_IsFrontFace) : SV_Target{
                // ambient
                float3 ambient = float3(unity_SHAr.w, unity_SHAg.w, unity_SHAb.w);
                // main light
                float4 shadowCoord = TransformWorldToShadowCoord(i.worldPos);
            //#if _MAIN_LIGHT_SHADOWS_CASCADE || _MAIN_LIGHT_SHADOWS
                Light mainLight = GetMainLight(shadowCoord);
            // #else
            //     Light mainLight = GetMainLight();
            // #endif
                float shadow = mainLight.shadowAttenuation;
                //基本量的计算
                float3 lightDir = mainLight.direction;
    
                float3 V = normalize(i.viewDir);
                            //float3 L = normalize(i.lightDir);
                float3 L = normalize(lightDir);
                float3 N = normalize(i.normalWS);
                float3 H = normalize(L + V);

                float NdotL = saturate(dot(N, L));
                float NdotH = saturate(dot(N, H));
                float NdotV = saturate(dot(N, V));
                float LdotH = saturate(dot(L, H));
                float VdotH = saturate(dot(V, H));
                // 采样基础纹理
                float4 baseMap = tex2D(_BaseMap,i.uv);
                float lerpValue = i.normalWS.y/2+0.5;
                lerpValue = smoothstep(0,1,lerpValue);
                float4 tint = lerp(_BottomLeaveColor,_TopLeaveColor,lerpValue);
                clip(baseMap.a - _Cutoff);

                // 基础阴影计算
                float3 diffuse = 0;
                float lambert = dot(N,L)*0.1+0.9;
                diffuse = lambert * _DiffuseIntensity;

                // 基础高光计算
                float3 specular = 0;
                float3 blinPhong = NdotH;
                specular = blinPhong*(1-_DiffuseIntensity);

                // 透射计算(sss)
                float3 transmission = 0;
                float3 transmissionhalf = N * _BackSubsurfaceDistortion+ L;
                //transmission = saturate(dot(-transmissionhalf, V)-_TransmissionThreshold);
                transmission = saturate(pow(dot(-transmissionhalf, V),3));
                transmission  =lerp(1+0.5*_TransmissionIntensity,1+_TransmissionIntensity,transmission);

                // 计算rim
                float fresnel = 1 - NdotV;
                float3 rim = baseMap.g * fresnel;
                rim *= _RimIntensity;

                // ReceiveShadoe计算                
                float3 receiveShadow = shadow * _ReceiveShadowIntensity + (1-_ReceiveShadowIntensity);

                float3 col = (ambient+diffuse+specular+rim)*tint*receiveShadow*transmission;
                //col = transmission;

                float4 albedo = float4(col,1);
                //albedo = tint;

                return albedo;
            }

            ENDHLSL
        }


        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // -------------------------------------
            // Render State Commands
            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma target 2.0

            // -------------------------------------
            // Shader Stages
            #pragma vertex ShadowPassVertex
            #pragma fragment ShadowPassFragment

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            // -------------------------------------
            // Universal Pipeline keywords

            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // -------------------------------------
            // Includes
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }
    }
}
