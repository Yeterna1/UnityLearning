Shader "Unlit/NPRWetLit"
{
    Properties
    {
        // _MainTex ("Texture", 2D) = "white" {}
        // [Header(MagicMap)]
        // _MagicMap("Magic Map",2D) = "white"{}

        _Alpha("Alpha",Range(0,1)) = 1

        [Header(Outline)]
        [Toggle(OUTLINE)]_Outline("Enable Outline(Default On)",float) = 1
        [Toggle(OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL)]_OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL("Enable OUTLINE VERTEX COLOR SMOOTH NORMAL",float) = 0
        // [Toggle(OUTLINE_IMAGE_BASED_COLOR)]_OUTLINE_IMAGE_BASED_COLOR("Enable Image Based Color",float) = 0
        // [Toggle(OUTLINE_IMAGE_BASED_WIDTH)]_OUTLINE_IMAGE_BASED_WIDTH("Enable Image Based Color",float) = 0
        _OutlineWidth("Outline Width",float) = 1
        //_OutlineWidthMap("Outline Width Map",2D) = "white"{}
        [Header(Normal)]
        [Toggle(NORMALMAP)]_NORMAL_MAP("Enable Input Normal",float) = 0
        _NormalMap("Normal Map",2D) = "white"{}
        _BumpScale("BumpScale",float) = 0
        [Toggle(HEIGHTMAP)]_HEIGHT_MAP("Enable Height Map",float) = 0
        _Height("Height Map",2D) = "white"{}


        [Header(IndirectLight)]
        _IndirectLightFlattenNormal("Indirect Light Flatten Normal(Default 0)",Range(0,1)) = 0
        _IndirectLightUsage("Indirect light usage(Defalut 0.5)", Range(0, 1)) = 0.5
        _IndirectLight0cclusionUsage("Indirect light occlusion usage(Default 0.5)", Range(0, 1)) =0.5
        _IndirectLightMixBaseColor("Indirect light mix base color(Defalut 1)", Range(0, 1)) = 1

        [Header(RecieveShadows)]
        _RecieveShadowIntensity("Recieved Shadow Intensity",float) = 0.5

        [Header(MainLightShadow)]
        _ShadowThresholdCenter("ShadowThreshold Center",Range(0,1)) = 0.5
        _ShadowThresholdSoftness("ShadowThreshold Softness",Range(0,1)) = 0
        
        [Header(Emission)]
        [Toggle(EMISSION)]_EMISSION("Enable Emission",float) = 0
        [HDR]_EmissionColor("Emission Color",color) = (0,0,0,0)

        [Header(Diffuse)]
        _TintColor("Tint Color",color) = (1,1,1,1)
        [Toggle(COLORTEX)]_COLORTEX("enable texture",float) = 0
        _BaseMap("Base Color Map",2D) = "white"{}
        //[HideInInspector]_BaseColorGradient("BaseColorGradient",2D) = "white"{}
        [Toggle(COLORRAMP)]_COLORRAMP("enable texture ramp",float) = 0
        _BaseColorRampMap("BaseColorRampMap",2D) = "white"{}
        _BaseColorFront("BaseColor Towards sun light",color) = (1,1,1,1)
        _BaseColorBehind("BaseColor Back sun light",color) = (0,0,0,0)

        [Header(Specular)]
        [KeywordEnum(None,BlinnPhong,Parallel)]_SpecularSort("SpecualrSort",float) = 1
        _SpecularExpon("Specular exponent (Default 50)",Range(1,128)) = 50
        _SpecularKsNonMetal("Specular Ks non-metal (Default 0.04)",Range(0,1))= 0.04
        _SpecularKsMetal("Specular Ks metal (Default 1)",Range(0,1))= 1
        _SpecularBrightness ("Specular brightness (Default 1)",Range(0,10))= 1
        _SpecularThreshold("Blinn Phong Threshold",Range(0,1)) = 0.8

        [Header(Highlight)]
        [Toggle(RIMLIGHT)]_RimLight("Enable Rim Light",Range(0,1)) = 0
        _RimLightWidth("Rim light width ( Default 1)", Range(0, 10)) = 1
        _RimLightThreshold("Rim light threshold ( Default 0.05)", Range(-1, 1)) = 0.05
        _RimLightFadeout(" Rim light fadeout ( Default 1)", Range(0.01, 1)) = 1
        [HDR]_RimLightTintColor("Rim light tint color(Default white)", Color) = (1,1,1)
        _RimLightBrightness(" Rim light brightness ( Default 1)", Range(0, 10)) = 1
        _RimLightMixAlbedo(" Rim light mix albedo ( Default 0.9)", Range(0, 1)) = 0.9
        [Toggle(FRESNELBRIGHTEN)]_FresnelBrighten("Enable Fresnel Brighten",Range(0,1)) = 0
        _FresnelIntensity("Fresnel Intensity(Defalut 0)",range(0,1)) = 0
        _FresnelColor("Fresnel Color",color) = (1,1,1,1)
        [Toggle(STRUCTUREHIGHLIGHT)]_StuctureHightlight("Enable Stucture Highlight",float) = 0
        _StructureHiighLitIntensity("Struct Highlight Intensity",Range(0,1)) = 0

        [Header(Metallic)]
        _Metallic("Metallic",Range(0,1)) = 0
        [Toggle(METALLICMAP)]_MATALLIC_MAP("Enable MetallicMap",float) = 0
        _MetallicMap("Metallic Map",2D) = "white"{}
        
        [Header(Roughness)]
        _Roughness("Roughness",float) = 0
        _RoughnessMap("Roughness Map",2D) = "white"{}

        [Header(SSR)]
        [Toggle(SSR)]_SSR("Enable SSR",float) = 0
        _RaySteps("Ray Max Steps",float) = 10
        _RayLength("Ray Length",float) = 1
        _MinLostDist("Min Lost Distance",float) = 2

        [Header(Rain)]
        [Toggle(RAIN)]_RAIN("Enable Rainy",float) = 0
        [Header(Desaturation)]
        _DesaturationFraction("Desaturation Fraction",float) = -0.5
        _DesaturationLerp("BaseColor&Desaturation Lerp",range(0,1)) = 0.5
        _DesaturationDarkness("Desaturation Darkness",float) = 0.5

        [Header(RainyRegion)]
        _DropletMask("Droplet Mask Texture",2D) = "white"{}
        _WetMap("Wet Region",2D) = "white"{}
        _WetRegionSize("Wet Region Size",Range(0,1)) = 0.5

        [Header(RainDroplet)]
        _RainDropNormalMap("Rain Drop Normal Map",2D) = "white"{}
        _RainDropBumpScale("Bump Scale",float) = 1
        // xy:aspect
        // z:size
        // w:speed
        _DropletParams("DropletParams(xy:ASPECT/z:SIZE/w:SPEED)",vector) = (1,1,1,1)
        // x:size
        // y:density
        // z:regionThreshold
        // w:speed
        _DynamicDropParams("DynamicDropParams(x:SIZE/y:DENSITY/z:regionThreshold/w:SPEED)",vector) = (1,1,1,1)


        [Header(Surface Options)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull(" Cull ( Default back)", Float) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendMode (" Src blend mode( Default One)", Float) =1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendMode (" Dst blend mode ( Default Zero)", Float) =0 
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp(" Blend operation ( Default Add)", Float) = 0
        [Enum(Off,0,On,1)] _ZWrite("ZWrite ( Default On)", Float) = 1
        _StencilRef (" Stencil reference ( Default 0)", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil comparison(Default disabled)", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPassOp ("Stencil pass operation(Default keep)", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFailOp ("Stencil fail operation(Default keep)", Int) = 0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilZFailOp("5tencil Z fail operation(Default keep)", Int) = 0
    }
    SubShader
    {
        //Tags { "RenderType"="Opaque" }
        LOD 100

        HLSLINCLUDE
        #pragma shader_feature OUTLINE
        #pragma shader_feature OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL

        #pragma shader_feature NORMALMAP
        #pragma shader_feature HEIGHTMAP

        #pragma shader_feature COLORTEX
        #pragma shader_feature COLORRAMP


        #pragma shader_feature METALLICMAP
        #pragma shader_feature EMISSION

        #pragma shader_feature_local _SPECULARSORT_BLINNPHONG
        #pragma shader_feature_local _SPECULARSORT_PARALLEL

        #pragma shader_feature RIMLIGHT
        #pragma shader_feature FRESNELBRIGHTEN
        #pragma shader_feature STRUCTUREHIGHLIGHT
        #pragma shader_feature SSR

        #pragma shader_feature StaticDrop
        #pragma shader_feature RAIN
        ENDHLSL

        Pass{
            Name "ShadowCaster"
            Tags {"LightMode" = "ShadowCaster"}

            ZWrite [_ZWrite]
            ZTest LEqual
            ColorMask 0
            Cull[_Cull]

            HLSLPROGRAM
            #pragma exclude_renderers gles gles3 glcore
            # pragma target 4.5
            // Material Keywords
            # pragma shader_feature_local_fragment _ALPHATEST_ON
            # pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GPU Instancing
            # pragma multi_compile_instancing
            # pragma multi_compile _ DOTS_INSTANCING_ON
            // Universal Pipeline keywords
            // This is used during shadow map generation to differentitate between directional and punctu al Light shadows , as they use different formula s to apply Nomal Bias
            # pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            # pragma vertex ShadowPassVertex
            # pragma fragment ShadowPassFragment

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
            ENDHLSL
        }

        Pass {
            Name "DepthNormals"
            Tags {
                "LightMode" = "DepthNormals"
            }

            HLSLPROGRAM
            #pragma vertex DepthNormalsVertex
            #pragma fragment DepthNormalsFragment

            //- Material- Keywords
            // #pragma shader_feature_local _NORMALMAP
            // #pragma shader_feature_local _PARALLAXMAP
            // #pragma shader_feature_local _DETAIL_MULX2 _DETATL_SCALED
            // #pragma shader_feature_local_fragment _ALPHATEST_ON
            // #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            
            //-GPU- Instancing
            #pragma multi_compile_instancing
            #pragma multi_compile_DOTS_INSTANCING_ON

            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
            ENDHLSL
        }

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

            #pragma target 2.0

            // -------------------------------------
            // Material Keywords
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local _ _DETAIL_MULX2 _DETAIL_SCALED
            #pragma shader_feature_local_fragment _SURFACE_TYPE_TRANSPARENT
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _ _ALPHAPREMULTIPLY_ON _ALPHAMODULATE_ON
            #pragma shader_feature_local_fragment _EMISSION
            #pragma shader_feature_local_fragment _METALLICSPECGLOSSMAP
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature_local_fragment _OCCLUSIONMAP
            #pragma shader_feature_local_fragment _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature_local_fragment _ENVIRONMENTREFLECTIONS_OFF
            #pragma shader_feature_local_fragment _SPECULAR_SETUP

            // -------------------------------------
            // Universal Pipeline keywords
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile _ EVALUATE_SH_MIXED EVALUATE_SH_VERTEX
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BLENDING
            #pragma multi_compile_fragment _ _REFLECTION_PROBE_BOX_PROJECTION
            #pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
            #pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
            #pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
            #pragma multi_compile_fragment _ _LIGHT_COOKIES
            #pragma multi_compile _ _LIGHT_LAYERS
            #pragma multi_compile _ _FORWARD_PLUS
            #include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"


            // -------------------------------------
            // Unity defined keywords
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE
            #pragma multi_compile_fog
            #pragma multi_compile_fragment _ DEBUG_DISPLAY

            //--------------------------------------
            // GPU Instancing
            #pragma multi_compile_instancing
            #pragma instancing_options renderinglayer
            #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

            #include"Assets/ShaderLibrary/NPRWetInputs.hlsl"
            #include"Assets/ShaderLibrary/YRFunctions.hlsl"
            #include"Assets/ShaderLibrary/NPRWetLitPass.hlsl"

            ENDHLSL
        }

        Pass{
            Name "DrawOutline"
            Tags{
                "RenderPipeline"="UniversalPipeline"
                "RenderType"="Opaque"
                "LightMode" = "UniversalForwardOnly"
            }

            Cull Front
            ZWrite [_ZWrite]
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog


            #if OUTLINE
                #include "Assets/ShaderLibrary/NPRInputs.hlsl"
                #include "Assets/ShaderLibrary/OutlinePass.hlsl"
            #else
                struct Attributes {};
                struct Varyings
                {
                    float4 positioncs : SV_POSITION;
                };
                Varyings vert(Attributes input){
                    return (Varyings)0;
                }
                float4 frag(Varyings input) : SV_TARGET{
                    return 0;
                }
            #endif
            ENDHLSL
        }

        // Pass{
        //     Name "DrawOverlay"
        //     Tags{
        //         "LightMode" = "UniversalForward"
        //         "RenderPipeline"="UniversalPipeline"
        //         "RenderType" = "Opaque"
        //     }
        //     Cull[_Cull]
        //     Stencil{
        //         Ref [_StencilRefOverlay]
        //         Comp [_StencilCompOverlay]
        //     }
        //     Blend [_SrcBlendModeOverlay] [_DstBlendModeOverlay]
        //     BlendOP [_BlendOpOverlay]
        //     ZWrite [_ZWrite]
        //     HLSLPROGRAM
            
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #pragma multi_compile_fog

        //     #pragma multi_compile _MAIN_LIGHT_SHADOWS
        //     #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
        //     #pragma multi_compile _SHADOWS_SOFT

        //     #if DRAW_OVERLAY
        //         #include"inputs.hlsl"
        //         #include"core.hlsl"
        //     #else
        //         struct Attributes{};
        //         struct Varyings
        //         {
        //             float4 positioncs : SV_POSITION;
        //         };
        //         Varyings vert(Attributes input){
        //             return (Varyings)0;
        //         }
        //         float4 frag(Varyings input) : SV_TARGET{
        //             return 0;
        //         }
        //     #endif
        //     ENDHLSL
        // }
    }
}
