Shader "Unlit/MeshSpotLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _MainTint("Main Color",color) = (0,0,0,0)

        
        _Pow("Pow",float) = 0
        _Brightness("Brightness",float) = 1

        _Params("Params",vector) = (1,1,1,1)

        [Header(Settings)]
        // xy:aspect
        // z:size
        // w:speed
        _DropletParams("DropletParams",vector) = (1,1,1,1)
        // x:size
        // y:density
        // z:
        // w:speed
        _DynamicDropParams("DynamicDropParams",vector) = (1,1,1,1)
        // x:size
        // y:density
        // z:interSize
        // w:speed
        _StaticDropParams("StaticDropParams",vector) = (1,1,1,1)

        _TestParams1("Test 1",vector) = (1,1,1,1)
        _TestParams2("Test 2",vector) = (1,1,1,1)
        _TestParams3("Test 3",vector) = (1,1,1,1)

        
        

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

        // Pass
        // {

        //     Tags{
        //         "RenderPipeline"="UniversalRenderPipeline"
        //         "RenderType" = "Opaque"
        //     }

        //     Cull[_Cull]
        //     Stencil{
        //         Ref [_StencilRef]
        //         Comp [_StencilComp]
        //         Pass [_StencilPassOp]
        //         Fail [_StencilFailOp]
        //         ZFail [_StencilZFailOp]
        //     }
        //     Blend [_SrcBlendMode] [_DstBlendMode]
        //     BlendOp [_BlendOp]
        //     ZWrite [_ZWrite]
        //     HLSLPROGRAM
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        //     struct Attributes
        //     {
        //         float4 positionOS : POSITION;
        //         float2 uv : TEXCOORD0;
        //         float3 normalOS : NORMAL;
        //         float4 tangentOS : TANGENT;
        //     };
        //     struct Varyings
        //     {
        //         float4 positionCS : SV_POSITION;
        //         float2 uv : TEXCOORD0;
        //         //float3 SH : TEXCOORD1;
        //         float3 normalOS : NORMAL;
        //         float3 normalWS : TEXCOORD2;
        //         float3 viewDirectionWS : TEXCOORD3;
        //         float3 positionWS : TEXCOORD4;
        //         float4 tangentOS : TEXCOORD5;
        //         float4 positionOS : TEXCOORD6;
        //     };

        //     sampler2D _MainTex;
        //     float4 _MainTex_ST; // 添加纹理缩放偏移变量
        //     float4 _MainTint;
        //     float _Pow;
        //     float _Brightness;

        //     float4 _Params;

        //     Varyings vert(Attributes input)
        //     {
        //         Varyings output;
    
        //         output.positionOS = input.positionOS;
        //         VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(input.positionOS);
        //         VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                
        //         output.positionCS = TransformObjectToHClip(input.positionOS);
        //         output.positionWS = TransformObjectToWorld(input.positionOS);
        //         output.uv = TRANSFORM_TEX(input.uv, _MainTex);
        //         output.normalWS = TransformObjectToWorldNormal(input.normalOS);
        //         //output.SH = SampleSH(lerp(output.normalWS, float3(0, 0, 0), _IndirectLightFlattenNormal));
        //         output.normalOS = input.normalOS;
        //         output.viewDirectionWS = _WorldSpaceCameraPos.xyz - output.positionWS;
        //         output.tangentOS = input.tangentOS;
        //         return output;
        //     }

        //     half4 frag(Varyings input) : SV_Target
        //     {
        //         float3 N = input.normalWS;
        //         float3 V = input.viewDirectionWS;

        //         float fresnel = pow(saturate(dot(N,V)),_Pow);
                
        //         float3 col = _MainTint.xyz * _Brightness;

        //         float dist = -input.positionOS.y;
        //         dist = saturate(_Params.x + input.positionOS.y * _Params.y);

        //         col *= dist;

        //         float alpha = _MainTint.w * fresnel;
        //         //alpha *= _Brightness;

        //         //clip(alpha);

        //         float4 res = float4(col,alpha);

        //         return res;
        //     }
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
            };

            float4 _TestParams1;
            float4 _TestParams2;
            float4 _TestParams3;
            float4x4 _WorldToCustomMatrix;


            

            float2 GetMeteor(float2 aspect, float size, float density, float time, float speed, float normaly, float2 uv)
            {
                // 应用速度 两小时一个循环
                float t = fmod(time * speed, 7200);

                float2 inituv = uv;
                // UV旋转
                float2 uv_centered = inituv - float2(0.5, 0.5);
                // 转换为弧度（建议使用内置函数）
                float radians = 30 * 0.01745329;
                float cos_theta = cos(radians);
                float sin_theta = sin(radians);
                // 应用旋转矩阵
                float x_rotated = uv_centered.x * sin_theta + uv_centered.y * cos_theta;
                float y_rotated = uv_centered.x * cos_theta - uv_centered.y * sin_theta;
                // 平移回原坐标系
                float2 uv_rotated = float2(x_rotated, y_rotated);// + float2(0.5, 0.5);
                // 将uv划分成多个小块
                uv_rotated *= aspect * size;
                uv_rotated.y += t * 0.25;
                // 将块的中心变换为（0，0）
                float2 cuv = frac(uv_rotated);
                // id应用于每一块自己的特殊随机变化
                half2 id = floor(uv_rotated);
                float offset = N21(id);
                offset = N(id.x);
                t += 3.1415 * 2 * offset;
                offset -= 0.5;
                offset *= 0.8;


                // 获取复杂的变换得到drop点的pos
                float w = inituv.y * 10;
                float2 dynamicDrop = float2(offset + (0.4 - abs(offset)) * sin(3 * w) * pow(sin(w), 6) * 0.45, -sin(t + sin(t + sin(t) * 0.5)) * 0.4);
                dynamicDrop = float2(0,offset);
                float2 dropPos = cuv - dynamicDrop;
                cuv.y = frac(uv_rotated.y+offset);

                offset = N21(float2(id.x,floor(uv_rotated.y+offset)));
                cuv.y = cuv.y  +  offset;

                float uZheZhao = smoothstep(_TestParams1.x * 0.01,  _TestParams1.y* 0.01, cuv.x);
                float vZheZhao = smoothstep(_TestParams2.x * 0.01, _TestParams2.y *0.01, cuv.y);
                float smooth = smoothstep(_TestParams3.x * 0.01,_TestParams3.y *0.01, cuv.y);

                float2 res = dropPos;
                res = float2(uZheZhao,vZheZhao);
                res = uZheZhao * vZheZhao * smooth;
                return res;
            }

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _DropletParams;
            float4 _DynamicDropParams;
            float4 _StaticDropParams;

            Varyings vert(Attributes input)
            {
                Varyings output;
    
                VertexPositionInputs vertexPositionInput = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs vertexNormalInput = GetVertexNormalInputs(input.normalOS, input.tangentOS);
    
                output.positionCS = TransformObjectToHClip(input.positionOS);
                output.positionWS = TransformObjectToWorld(input.positionOS);
                output.uv = TRANSFORM_TEX(input.uv, _MainTex);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                //output.SH = SampleSH(lerp(output.normalWS, float3(0, 0, 0), _IndirectLightFlattenNormal));
                output.normalOS = input.normalOS;
                output.viewDirectionWS = _WorldSpaceCameraPos.xyz - output.positionWS;
                output.tangentOS = input.tangentOS;
                return output;
            }

            float4 frag(Varyings input) : SV_TARGET
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
                float3 viewDirTS = mul(TBN, cameraDir) * float3(1, 1, -1);
                //viewDirTS = mul(TBN, V) * float3(1, 1, -1);
    
                float3 oneDivideViewDirTS = 1 / viewDirTS;

                float NdotL = saturate(dot(normalWS, L));
                float NdotH = saturate(dot(normalWS, H));
                float NdotV = saturate(dot(normalWS, V));
                float LdotH = saturate(dot(L, H));
                float VdotH = saturate(dot(V, H));

                float3 viewPos = TransformWorldToView(positionWS);
			    float3 objectOriginViewPos = TransformWorldToView(TransformObjectToWorld(float3(0.0, 0.0, 0.0)).xyz);
                float2 vSubT = float2((viewPos-objectOriginViewPos).xy);

                float3 customPos = positionWS;

    
                float3 color = 0;
                float t = fmod(_Time.y * _DropletParams.w,7200);
    
                float2 aspect = _DropletParams.xy;
                float size = _DropletParams.z;
    
                float2 uv = input.uv;
                //uv = StaticDroplet(aspect, _StaticDropParams.x, _StaticDropParams.y, input.uv);
                uv = GetMeteor(aspect, _DynamicDropParams.x, _DynamicDropParams.y, _Time.y, _DynamicDropParams.w,normalWS.y, customPos.xy);
    
                float3 baseTint = tex2D(_MainTex, uv);

                color = tex2D(_MainTex, input.uv + uv);
                color = float3(uv,0);
                //color = float3(customPos.xy,0);

                float4 res = float4(color, 1);
                return res;
            }
            ENDHLSL
        }
    }
}
