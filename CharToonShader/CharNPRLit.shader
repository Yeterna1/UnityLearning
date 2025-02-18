Shader "Unlit/CharNPRLit"
{
    Properties
    {
        [KeywordEnum(None,Face,Hair,UpperBody,LowerBody,Weapon)] _Area("Material Area",float) = 0
        [HideInInspector] _HeadForward("", Vector) = (0,0,1)
        [HideInInspector] _HeadRight("", Vector) = (1,0,0)

        [Header(Base Color)]
        [HideinInspector] _BaseMap("", 2D) = " white" {}
        [NoScale0ffset] _FaceColorMap("Face color map(Default white)", 2D) = " white" {}
        [NoScaleOffset] _HairColorMap("Hair color map(Default white)", 2D) = "white" {}
        [NoScaleOffset] _UpperBodyColorMap("Upper body color map(Default white)", 2D) =" white" {}
        [NoScaleOffset] _LowerBodyColorMap("Lower body color map(Default white)", 2D) = " white" {}
        [NoScaleOffset] _WeaponColorMap("Weapon color map(Default white)", 2D) = " white" {}
        _FrontFaceTintColor("Front face tint color(Default white)", Color) = (1,1,1)
        _BackFaceTintColor("Back face tint color(Default white)", Color) = (1,1,1)
        _Alpha (" Alpha ( Default 1)", Range(0,1)) = 1
        _AlphaClip (" Alpha clip (Default 0.333)", Range(0, 1)) = 0.333

        [Header(Light Map)]
        [NoScaleOffset] _HairLightMap("Hair light map(Default black)", 2D) =" black" {}
        [NoScale0ffset] _UpperBodyLightMap("Upper body light map(Default black)", 2D) =" black" {}
        [NoScale0ffset] _LowerBodyLightMap("Lower body light map(Default black)", 2D) =" black" {}
        [NoScale0ffset] _WeaponLightMap("Weapon light map(Default black)", 2D) =" black" {}

        [Header(Ramp Map)]
        [Toggle(Ramp)]_Ramp("Enable RampMap(Defalut Enable)",float) = 1
        [NoScale0ffset] _HairCoolRamp(" Hair cool ramp ( Default white)", 2D) = " white"{}
        [NoScaleOffset] _HairWarmRamp(" Hair warm ramp ( Default white)", 2D) =" white" {}
        [NoScale0ffset] _BodyCoolRamp(" Body cool ramp ( Default white)", 2D) = " white"{}
        [NoScale0ffset] _BodyWarmRamp(" Body warm ramp ( Default white)", 2D) = " white"{}
        _ShadowRamp0ffset(" Shadow ramp offset(Default 0.75)", Range(0, 1)) = 0.75

        [Header(Face)]
        [NoScaleOffset] _FaceMap(" Face map( Default black)", 2D) = " black" {}
        _FaceShadow0ffset(" Face shadow offset ( Default -0.01)", Range(-1, 1)) = -0.01
        _FaceShadowTransitionSoftness(" Face shadow transition softness ( Default 0.05)", Range(0, 1)) = 0.05

        [Header(Outline)]
        [Toggle(OUTLINE)]_Outline("Enable Outline(Default On)",float) = 1
        [Toggle(OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL)]_OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL("Enable OUTLINE VERTEX COLOR SMOOTH NORMAL",float) = 0
        _OutlineWidth("Outline Width",float) = 1

        [Header(Normal)]
        [Toggle(NORMALMAP)]_NORMAL_MAP("Enable Input Normal",float) = 0
        _NormalMap("Normal Map",2D) = "white"{}


        [Header(IndirectLight)]
        _IndirectLightFlattenNormal("Indirect Light Flatten Normal(Default 0)",Range(0,1)) = 0
        _IndirectLightUsage("Indirect light usage(Defalut 0.5)", Range(0, 1)) = 0.5
        _IndirectLight0cclusionUsage("Indirect light occlusion usage(Default 0.5)", Range(0, 1)) =0.5
        _IndirectLightMixBaseColor("Indirect light mix base color(Defalut 1)", Range(0, 1)) = 1

        [Header(RecieveShadows)]
        _RecieveShadowIntensity("Recieved Shadow Intensity",float) = 0.5

        [Header(MainLightShadow)]
        _MainLightColorUsage("Main light color usage(Default 1)", Range(0, 1)) = 1
        _ShadowThresholdCenter("ShadowThreshold Center",Range(-1,1)) = 0
        _ShadowThresholdSoftness("ShadowThreshold Softness",Range(0,1)) = 0.1

        [Header(Specular)]
        _SpecularExpon("Specular exponent (Default 50)",Range(1,128)) = 50
        _SpecularKsNonMetal("Specular Ks non-metal (Default 0.04)",Range(0,1))= 0.04
        _SpecularKsMetal( "Specular Ks metal (Default 1)",Range(0,1))= 1
        _SpecularBrightness ( "Specular brightness (Default 1)",Range(0,10))= 1

        [Header(Rim Lighting)]
        _RimLightWidth(" Rim light width ( Default 1)", Range(0, 10)) = 0.1
        _RimLightThreshold(" Rim light threshold ( Default 0.05)", Range(-1, 1)) = 0.05
        _RimLightFadeout(" Rim light fadeout ( Default 1)", Range(0.01, 1)) = 1
        [HDR]_RimLightTintColor("Rim light tint color(Default white)", Color) = (1,1,1)
        _RimLightBrightness(" Rim light brightness ( Default 1)", Range(0, 10)) = 1
        _RimLightMixAlbedo(" Rim light mix albedo ( Default 0.9)", Range(0, 1)) = 0.9

        [Header(Emission)]
        [Toggle(EMISSION)] _UseEmission(" Use emission ( Default NO)", float) = 0
        _EmissionMixBaseColor(" Emission mix base color ( Default 1)", Range(0, 1)) = 1
        _EmissionTintColor(" Emission tint color ( Default white)", Color) = (1,1,1)
        _EmissionIntensity(" Emission intensity ( Default 1)", Range(0, 100)) = 1
        

        [Header(Color)]
        //[HideInInspector]_BaseColorGradient("BaseColorGradient",2D) = "white"{}
        _BaseColorRampMap("BaseColorRampMap",2D) = "white"{}

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
        [Enum(UnityEngine.Rendering.BlendMode)]_SrcBlendModeOverlay ("Overlay pass src blend mode(Default One)", Float) =1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendModeOverlay ("Overlay pass dst blend mode(Default Zero)", Float) =0
        [Enum(UnityEngine.Rendering.BlendOp)]_BlendOpOverlay ("Overlay pass blend operation (Default Add)", Float) =0
        _StencilRefOverlay("Overlay pass stencil reference(Default 0)", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilCompOverlay ("Dverlay pass stencil comparison(Default disabled)", Int) =0
    }
    SubShader
    {
        //Tags { "RenderType"="Opaque" }
        LOD 100

        HLSLINCLUDE

        #pragma shader_feature_local _AREA_FACE
        #pragma shader_feature_local _AREA_HAIR
        #pragma shader_feature_local _AREA_UPPERBODY
        #pragma shader_feature_local _AREA_LOWERBODY
        #pragma shader_feature_local _AREA_WEAPON

        #pragma shader_feature Ramp

        #pragma shader_feature EMISSION
        #pragma shader_feature_local DRAW_OVERLAY
        #pragma shader_feature OUTLINE
        #pragma shader_feature OUTLINE_VERTEX_COLOR_SMOOTH_NORMAL
        #pragma shader_feature NORMALMAP
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
            #pragma shader_feature_local _NORMALMAP
            #pragma shader_feature_local _PARALLAXMAP
            #pragma shader_feature_local _DETAIL_MULX2 _DETATL_SCALED
            #pragma shader_feature_local_fragment _ALPHATEST_ON
            #pragma shader_feature_local_fragment _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            
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

            #pragma multi_compile _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _SHADOWS_SOFT

            #include"Assets/ShaderLibrary/CharNPRInputs.hlsl"
            #include"Assets/ShaderLibrary/YRFunctions.hlsl"
            #include"Assets/ShaderLibrary/CharNPRLitPass.hlsl"

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

        Pass{
            Name "DrawOverlay"
            Tags{
                "LightMode" = "UniversalForward"
                "RenderPipeline"="UniversalPipeline"
                "RenderType" = "Opaque"
            }
            Cull[_Cull]
            Stencil{
                Ref [_StencilRefOverlay]
                Comp [_StencilCompOverlay]
            }
            Blend [_SrcBlendModeOverlay] [_DstBlendModeOverlay]
            BlendOP [_BlendOpOverlay]
            ZWrite [_ZWrite]
            HLSLPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #pragma multi_compile _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _SHADOWS_SOFT

            #if DRAW_OVERLAY
                #include"Assets/ShaderLibrary/CharNPRInputs.hlsl"
                #include"Assets/ShaderLibrary/YRFunctions.hlsl"
                #include"Assets/ShaderLibrary/CharNPRLitPass.hlsl"
            #else
                struct Attributes{};
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
    }
}
