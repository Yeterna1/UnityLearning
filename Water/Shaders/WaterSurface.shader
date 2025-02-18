Shader "Unlit/WaterSurface"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}

        [Header(Tint Color)]
        [Toggle(DepthRampMap_Based_SurfaceColor)]_DepthRampMap_Based_SurfaceColor("DepthRampMap_Based_SurfaceColor(Default No)",float) = 0
        _DepthRamp("Depth Ramp",2D) = "white"{}
        _ShallowWaterColor("Shallow Water Color",color) = (0,0,0,0)
        _DeepWaterColor("Deep Water Color",color) = (1,1,1,1)
        _WaterDepthRemap("Water Depth Remmap(Default 1)",float) = 1
        _WaterDepthCoef("Water Depth Coefficient(Default 1)",float) = 1
        _FresnelIntensity("Fresnel Intensity(Default 1)",float) = 1
        _Transmission("Transmission",Range(0,75)) = 1

        [Header(Reflection)]
        [KeywordEnum(PanelRefl,SSR)]_ReflectType("Reflection Strategy",float) = 0
        _ReflectMap("Reflect Map",2D) = "white"{}
        _ReflectDistortMap("Reflect Distortion Map(Tem)",2D) = "white"{}
        _ReflectDistortIntensity("Reflect Distortion Intensity(Default 0)",float) = 0
        _ReflectDistortScale("Reflect Distortion Scale(Default 0)",Range(0,1)) = 0
        _ReflectIntensity("Reflect Intesnsity(Default 1)",float) = 1
        
        [Header(Refraction)]
        _RefractIntensity("Refract Intensity(Default 0)",Range(0,1)) = 0

        [Header(HighLit)]
        _Roughness("Roughness",Range(0,1)) = 0.9

        [Header(Foam)]
        _FoamMap("Foam Map",2D) = "white" {}
        _FoamScale("Foam Scale(Default 0)",float) = 0
        _FoamIntensity("Foam Intensity",float) = 0

        [Header(Caustics)]
        _CausticsMap("Caustics Map",2D) = "white" {}
        _CausticsScale("Caustics Scale(Default 0)",float) = 0
        _CausticsDensity("Caustics Density(Default 0.2)",float) = 0.2
        _CausticsTransIntensity("Caustics Transform Intensity(Default 1)",float) = 1
        _CausticsIntensity("Caustics Intensity",float) = 0

        [Header(FFT)]
        _DisplaceIntensity("Displace Intensity(Default 0)",Float) = 0
        _BubblesIntensity("Bubbles Intensity(Default 0)",float) = 0
        [HideinInspector]_WaterSurfaceDisplace("",2D) = "black"{}

        [Header(ShadowReceive)]
        _ShadowReceiveIntensity("Shadow Receive Intensity",Range(0,1)) = 0

        [Header(Surface Options)]
        [Enum(UnityEngine.Rendering.CullMode)] _Cull("Cull(Default back)", Float) = 2
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlendMode (" Src blend mode(Default One)", Float) =1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlendMode (" Dst blend mode(Default Zero)", Float) =0 
        [Enum(UnityEngine.Rendering.BlendOp)] _BlendOp(" Blend operation (Default Add)", Float) = 0
        [Enum(Off,0,On,1)] _ZWrite("ZWrite(Default On)", Float) = 1
        _StencilRef ("Stencil reference(Default 0)", Range(0,255)) = 0
        [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp("Stencil comparison(Default disabled)", Int) =0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilPassOp ("Stencil pass operation(Default keep)", Int) =0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilFailOp ("Stencil fail operation(Default keep)", Int) =0
        [Enum(UnityEngine.Rendering.StencilOp)] _StencilZFailOp("5tencil Z fail operation(Default keep)", Int) =0

        [Header(Tess)][Space]
        [KeywordEnum(integer, fractional_even, fractional_odd)]_Partitioning ("Partitioning Mode", Float) = 0
        [KeywordEnum(triangle_cw, triangle_ccw)]_Outputtopology ("Outputtopology Mode", Float) = 0
        _EdgeFactor ("EdgeFactor", Range(1,8)) = 4 
        _InsideFactor ("InsideFactor", Range(1,8)) = 4 
        
    }
    SubShader
    {
        Tags { "Queue" = "Transparent"  "RenderPipeline" = "UniversalRenderPipeline"}
        LOD 100

        HLSLINCLUDE

        #pragma shader_feature DepthRampMap_Based_SurfaceColor
        #pragma shader_feature_local _REFLECTTYPE_PANELREFL
        #pragma shader_feature_local _REFLECTTYPE_SSR

        ENDHLSL

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
            
        //     //-GPU- Instancing
        //     #pragma multi_compile_instancing
        //     #pragma multi_compile_DOTS_INSTANCING_ON

        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/LitDepthNormalsPass.hlsl"
        //     ENDHLSL
        // }

        // Pass
        // {
        //     Name "ShadowCaster"
        //     Tags
        //     {
        //         "LightMode" = "ShadowCaster"
        //     }

        //     // -------------------------------------
        //     // Render State Commands
        //     ZWrite On
        //     ZTest LEqual
        //     ColorMask 0
        //     Cull[_Cull]

        //     HLSLPROGRAM
        //     #pragma target 2.0

        //     // -------------------------------------
        //     // Shader Stages
        //     #pragma vertex ShadowPassVertex
        //     #pragma fragment ShadowPassFragment

        //     // -------------------------------------
        //     // Material Keywords
        //     #pragma shader_feature_local _ALPHATEST_ON
        //     #pragma shader_feature_local_fragment _GLOSSINESS_FROM_BASE_ALPHA

        //     // -------------------------------------
        //     // Unity defined keywords
        //     #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

        //     //--------------------------------------
        //     // GPU Instancing
        //     #pragma multi_compile_instancing
        //     #include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"

        //     // This is used during shadow map generation to differentiate between directional and punctual light shadows, as they use different formulas to apply Normal Bias
        //     #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

        //     // -------------------------------------
        //     // Includes
        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/SimpleLitInput.hlsl"
        //     #include "Packages/com.unity.render-pipelines.universal/Shaders/ShadowCasterPass.hlsl"
        //     ENDHLSL
        // }

        Pass
        {
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

            #pragma prefer_hlslcc gles
            #pragma exclude_renderers d3d11_9x


            #pragma target 4.6 

            #pragma hull FlatTessControlPoint
            #pragma domain FlatTessDomain
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _PARTITIONING_INTEGER _PARTITIONING_FRACTIONAL_EVEN _PARTITIONING_FRACTIONAL_ODD 
            #pragma multi_compile _OUTPUTTOPOLOGY_TRIANGLE_CW _OUTPUTTOPOLOGY_TRIANGLE_CCW 
            
            // #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile  _MAIN_LIGHT_SHADOWS
			#pragma multi_compile  _MAIN_LIGHT_SHADOWS_CASCADE
			//#pragma multi_compile  _SHADOWS_SOFT

            

            #include"WaterSurfaceInputs.hlsl"
            #include"WaterSurfaceCore.hlsl"

            ENDHLSL
        }

    }
}
