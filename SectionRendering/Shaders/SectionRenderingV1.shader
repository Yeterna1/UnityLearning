Shader "Custom/SectionRenderingV1"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _SectionTex("Section Texture",2D) = "white"{}
        _SectionColor ("Section Color", Color) = (1,0,0,1)
        _CutoffPlane ("Cutoff Plane", Vector) = (0,1,0,0)

        [Header(Cone)]
        // 在Properties块中声明
        _ConeTipWorldPos ("Cone Tip Position", Vector) = (0,0,0,0)
        _ConeDirectionWorld ("Cone Direction", Vector) = (0,0,1,0)
        _ConeHeight ("Cone Height", Float) = 5.0
        _ConeBaseRadius ("Cone Base Radius", Float) = 2.0

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
                float dist = dot(i.worldPos, _CutoffPlane.xyz) + _CutoffPlane.w;
                clip(dist);
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

            struct appdata { 
                float4 vertex : POSITION;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float4 screenPos : TEXCOORD0;  // 新增屏幕坐标
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            sampler2D _SectionTex;
            float4 _CutoffPlane;
            float4 _SectionColor;

            v2f vert(appdata v)
            {
                v2f o;
                o.pos = TransformObjectToHClip(v.vertex.xyz);
                o.worldPos = TransformObjectToWorld(v.vertex.xyz);
                
                // 计算屏幕坐标（包含透视除法）
                o.screenPos = ComputeScreenPos(o.pos);
                return o;
            }

            half4 frag(v2f i) : SV_Target
            {
                // 平面裁剪逻辑
                float dist = dot(i.worldPos, _CutoffPlane.xyz) + _CutoffPlane.w;


                clip(dist);

                // 计算标准化屏幕UV
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                
                // 采样主纹理
                half4 texColor = tex2D(_SectionTex, screenUV);
                
                // 混合截面颜色（可根据需要调整混合方式）
                return texColor;
            }
            ENDHLSL
        }
    }
}