Shader "M/SSRRenderFeature"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        // SSR Ray Marching pass0 (WithOutHiZ)
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment SSRPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"  
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl" 

            #define MAXDISTANCE 10
            #define STEP_COUNT 1200
            #define THICKNESS 0.15
            #define STRIDE 2

            float4 _ProjectionParams2;  
            float4 _CameraViewTopLeftCorner;  
            float4 _CameraViewXExtent;  
            float4 _CameraViewYExtent;  
            float4 _SourceSize;

            void swap(inout float v0, inout float v1) {  
                float temp = v0;  
                v0 = v1;    
                v1 = temp;
            } 

            // jitter dither map
            static half dither[16] = {
                0.0, 0.5, 0.125, 0.625,
                0.75, 0.25, 0.875, 0.375,
                0.187, 0.687, 0.0625, 0.562,
                0.937, 0.437, 0.812, 0.312
            };

            // 通过屏幕uv 和zView值重建世界坐标
            half3 ReconstructWorldPos(float2 uv, float linearEyeDepth) {  
                uv.y = 1.0 - uv.y;  

                float zScale = linearEyeDepth * _ProjectionParams2.x; // divide by near plane  
                float3 worldPos = _CameraViewTopLeftCorner.xyz + _CameraViewXExtent.xyz * uv.x + _CameraViewYExtent.xyz * uv.y;  
                float3 dir = worldPos - _WorldSpaceCameraPos.xyz;
                dir *= zScale;
                worldPos = _WorldSpaceCameraPos.xyz + dir;  
                return worldPos;  
            }
            float4 TransformViewToHScreen(float3 vpos, float2 screenSize) {  
                float4 cpos = mul(UNITY_MATRIX_P, vpos);  
                cpos.xy = float2(cpos.x, cpos.y * _ProjectionParams.x) * 0.5 + 0.5 * cpos.w;  
                cpos.xy *= screenSize;  
                return cpos;  
            } 

            // 通过世界坐标计算 屏幕uv 和 zview
            void ReconstructUVAndDepth(float3 wpos, out float2 uv, out float depth) {  
                float4 cpos = mul(UNITY_MATRIX_VP, float4(wpos,1));  
                uv = float2(cpos.x, cpos.y * _ProjectionParams.x) / cpos.w * 0.5 + 0.5;  
                depth = cpos.w;
            }

            float4 GetSource(half2 uv) {  
                return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearRepeat, uv, _BlitMipLevel);  
            }     

            float4 SSRPassFragment(Varyings input):SV_Target{
                float rawDepth = SampleSceneDepth(input.texcoord);
                float linearDepth = LinearEyeDepth(rawDepth,_ZBufferParams);

                float3 pos = ReconstructWorldPos(input.texcoord, linearDepth);
                float3 normal = SampleSceneNormals(input.texcoord); 
                float3 vDir = normalize(pos-_ProjectionParams2.yzw);  
                float3 rDir = TransformWorldToViewDir(normalize(reflect(vDir, normal)));

                // 获得View空间位置
                float magnitude = MAXDISTANCE; 
                float3 startView = TransformWorldToView(pos);  
                float end = startView.z + rDir.z * magnitude;  
                // 将最大位移后超出近平面的向量强制转移到近平面上
                if (end > -_ProjectionParams.y)  
                    magnitude = (-_ProjectionParams.y - startView.z) / rDir.z;  
                float3 endView = startView + rDir * magnitude; 

                // 齐次屏幕空间坐标  
                float4 startHScreen = TransformViewToHScreen(startView, _SourceSize.xy);  
                float4 endHScreen = TransformViewToHScreen(endView, _SourceSize.xy); 

                // inverse w(K在屏幕空间坐标下是线性变换的)
                float startK = 1.0 / startHScreen.w;  
                float endK = 1.0 / endHScreen.w;  

                //  结束屏幕空间坐标  
                float2 startScreen = startHScreen.xy * startK;  
                float2 endScreen = endHScreen.xy * endK;  


                // 根据斜率将dx=1 dy = delta  
                float2 diff = endScreen - startScreen;  
                bool permute = false;  
                if (abs(diff.x) < abs(diff.y)) {  
                    permute = true;  

                    diff = diff.yx;  
                    startScreen = startScreen.yx;  
                    endScreen = endScreen.yx;  
                }  

                // 计算屏幕坐标、齐次视坐标、inverse-w的线性增量  
                float dir = sign(diff.x);  
                float invdx = dir / diff.x;  
                float2 dp = float2(dir, invdx * diff.y);  
                float dk = (endK - startK) * invdx;  

                dp *= STRIDE;  
                dk *= STRIDE;

                // 缓存当前深度和位置 
                float rayZMin = startView.z;  
                float rayZMax = startView.z;  
                float preZ = startView.z;  

                float2 P = startScreen;  
                float K = startK;  

                float mipLevel = 0.0;

                float2 hitUV = 0.0;

                end = endScreen.x * dir;  

                // 进行屏幕空间射线步近  
                UNITY_LOOP  
                for (int i = 0; i < STEP_COUNT && P.x * dir <= end; i++) {  
                    // 步近  
                    P += dp;  
                    K += dk;  

                    // 得到步近前后两点的深度  
                    rayZMin = preZ;  
                    rayZMax = -1/K; 

                    preZ = rayZMax;        
                    if (rayZMin > rayZMax)  
                        swap(rayZMin, rayZMax);  

                    // 得到交点uv  
                    float2 hitUV = permute ? P.yx : P;  
                    hitUV *= _SourceSize.zw;  
                    if (any(hitUV < 0.0) || any(hitUV > 1.0))  
                        //return GetSource(input.texcoord);  
                        return float4(0,0,0,1); 
                    float surfaceDepth = -LinearEyeDepth(SampleSceneDepth(hitUV), _ZBufferParams);  
                    bool isBehind = (rayZMin + 0.01 <= surfaceDepth); // 加一个bias 防止stride过小，自反射  
                    bool intersecting = isBehind && (rayZMax >= surfaceDepth - THICKNESS);  

                    if (intersecting)  
                        return GetSource(hitUV);  
                }  
                //return GetSource(input.texcoord);  
                return float4(0,0,0,1);  
            }


            ENDHLSL
        }

        // HiZ pass 1
        Pass{
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment SSAOPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"  
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl" 

            float _HierarchicalZBufferTextureFromMipLevel;
            float _HierarchicalZBufferTextureToMipLevel;
            float4 _SourceSize;

            half4 GetSource(half2 uv, float2 offset = 0.0, float mipLevel = 0.0) {
                offset *= _SourceSize.zw;
                return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearRepeat, uv + offset, mipLevel);
            }

            half4 SSAOPassFragment(Varyings input) : SV_Target {
                float2 uv = input.texcoord;

                half4 minDepth = half4(
                    GetSource(uv, float2(-1, -1), _HierarchicalZBufferTextureFromMipLevel).r,
                    GetSource(uv, float2(-1, 1), _HierarchicalZBufferTextureFromMipLevel).r,
                    GetSource(uv, float2(1, -1), _HierarchicalZBufferTextureFromMipLevel).r,
                    GetSource(uv, float2(1, 1), _HierarchicalZBufferTextureFromMipLevel).r
                );

                return min(min(minDepth.r, minDepth.g), min(minDepth.b, minDepth.a));
            }
            ENDHLSL
        }

        // solve multi-sampling pro pass 2
        Pass{
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment SSAOPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"  
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl" 

            float _HierarchicalZBufferTextureFromMipLevel;
            float _HierarchicalZBufferTextureToMipLevel;
            float4 _SourceSize;

            half4 GetSource(half2 uv, float2 offset = 0.0, float mipLevel = 0.0) {
                //offset *= _SourceSize.zw;
                return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearRepeat, uv, mipLevel);
            }

            half4 SSAOPassFragment(Varyings input) : SV_Target {
                float2 uv = input.texcoord;

                // half4 minDepth = half4(
                //     GetSource(uv, float2(-1, -1), _HierarchicalZBufferTextureFromMipLevel).r,
                //     GetSource(uv, float2(-1, 1), _HierarchicalZBufferTextureFromMipLevel).r,
                //     GetSource(uv, float2(1, -1), _HierarchicalZBufferTextureFromMipLevel).r,
                //     GetSource(uv, float2(1, 1), _HierarchicalZBufferTextureFromMipLevel).r
                // );
                
                half depth = SampleSceneDepth(uv);
                half res = depth;
                return res;
            }
            ENDHLSL
        }

        // pass3 BlurHorizontal
        Pass{
            HLSLPROGRAM
            #pragma vertex VertBlurHorizontal
            #pragma fragment fragBlur

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl" 

            float _SSRBlurRadius;
            float4 _SourceSize;

            struct Varyings2
            {
                float2 uv[5] : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            float4 GetSource(half2 uv) {  
                return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearRepeat, uv, _BlitMipLevel);  
            }


            
            Varyings2 VertBlurHorizontal(Attributes v)
            {
                Varyings2 o = (Varyings2)0;
                UNITY_SETUP_INSTANCE_ID(v);
                o.positionCS = GetFullScreenTriangleVertexPosition(v.vertexID);
                //float2 uv = v.uv;
                float2 uv  = GetFullScreenTriangleTexCoord(v.vertexID);
                o.uv[0] = uv;
                o.uv[1] = uv + float2(_SourceSize.z * 1.0, 0.0) * _SSRBlurRadius;
                o.uv[2] = uv - float2(_SourceSize.z * 1.0, 0.0) * _SSRBlurRadius;
                o.uv[3] = uv + float2(_SourceSize.z * 2.0, 0.0) * _SSRBlurRadius;
                o.uv[4] = uv - float2(_SourceSize.z * 2.0, 0.0) * _SSRBlurRadius;
                return o;
            }
            float4 fragBlur(Varyings2 i) : SV_Target
            {
                float weight[3] = {0.4026, 0.2442, 0.0545};
                //中心像素值
                // float3 sum = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[0]).rgb * weight[0];
                float3 sum = GetSource(i.uv[0]) * weight[0];

                for (int it = 1; it < 3; it++)
                {
                    // sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[it * 2 - 1]).rgb * weight[it];
                    // sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[it * 2]).rgb * weight[it];
                    sum += GetSource(i.uv[it * 2 - 1]).rgb * weight[it];
                    sum += GetSource(i.uv[it * 2]).rgb * weight[it];
                }
                return float4(sum, 1.0);
            }

            ENDHLSL
        }

        // pass4 BlurVertical
        Pass{
            HLSLPROGRAM
            #pragma vertex VertBlurVertical
            #pragma fragment fragBlur

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl" 

            float _SSRBlurRadius;
            float4 _SourceSize;

            struct Varyings2
            {
                float2 uv[5] : TEXCOORD0;
                float4 positionCS : SV_POSITION;
            };

            float4 GetSource(half2 uv) {  
                return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearRepeat, uv, _BlitMipLevel);  
            }


            Varyings2 VertBlurVertical(Attributes v)
            {
                Varyings2 o;
                UNITY_SETUP_INSTANCE_ID(v);
                o.positionCS = GetFullScreenTriangleVertexPosition(v.vertexID);
                //float2 uv = v.uv;
                float2 uv  = GetFullScreenTriangleTexCoord(v.vertexID);
                o.uv[0] = uv;
                o.uv[1] = uv + float2(0.0, _SourceSize.w * 1.0) * _SSRBlurRadius;
                o.uv[2] = uv - float2(0.0, _SourceSize.w * 1.0) * _SSRBlurRadius;
                o.uv[3] = uv + float2(0.0, _SourceSize.w * 2.0) * _SSRBlurRadius;
                o.uv[4] = uv - float2(0.0, _SourceSize.w * 2.0) * _SSRBlurRadius;
                return o;
            }
            float4 fragBlur(Varyings2 i) : SV_Target
            {
                float weight[3] = {0.4026, 0.2442, 0.0545};
                //中心像素值
                // float3 sum = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[0]).rgb * weight[0];
                float3 sum = GetSource(i.uv[0]) * weight[0];

                for (int it = 1; it < 3; it++)
                {
                    // sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[it * 2 - 1]).rgb * weight[it];
                    // sum += SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv[it * 2]).rgb * weight[it];
                    sum += GetSource(i.uv[it * 2 - 1]).rgb * weight[it];
                    sum += GetSource(i.uv[it * 2]).rgb * weight[it];
                }
                return float4(sum, 1.0);
            }

            ENDHLSL
        }

        // pass5 Addition
        Pass{
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment fragAddition

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl" 

            sampler2D _CameraColorTexture;
            float _SSRIntensity;

            float4 GetSource(half2 uv) {  
                return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearRepeat, uv, _BlitMipLevel);  
            }

            float4 fragAddition(Varyings input) : SV_Target
            {
                float4 SSRColor = GetSource(input.texcoord);
                float4 screenColor = tex2D(_CameraColorTexture,input.texcoord);
                return lerp(screenColor,SSRColor,_SSRIntensity);
            }

            ENDHLSL

        }

        // SSR Ray Marching pass5 (Use HiZ)
        // Pass
        // {
        //     HLSLPROGRAM
        //     #pragma vertex Vert
        //     #pragma fragment SSRPassFragment

        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"  
        //     #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"  
        //     #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl" 

        //     #define MAXDISTANCE 10
        //     #define STEP_COUNT 1200
        //     #define THICKNESS 0.15
        //     #define STRIDE 2

        //     TEXTURE2D_X(_HiZBufferTexture);
        //     SamplerState sampler_HiZBufferTexture;
        //     float _MaxHiZBufferTextureipLevel;

        //     float4 _ProjectionParams2;  
        //     float4 _CameraViewTopLeftCorner;  
        //     float4 _CameraViewXExtent;  
        //     float4 _CameraViewYExtent;  
        //     float4 _SourceSize;

        //     void swap(inout float v0, inout float v1) {  
        //         float temp = v0;  
        //         v0 = v1;    
        //         v1 = temp;
        //     } 

        //     // jitter dither map
        //     static half dither[16] = {
        //         0.0, 0.5, 0.125, 0.625,
        //         0.75, 0.25, 0.875, 0.375,
        //         0.187, 0.687, 0.0625, 0.562,
        //         0.937, 0.437, 0.812, 0.312
        //     };

        //     // 通过屏幕uv 和zView值重建世界坐标
        //     half3 ReconstructWorldPos(float2 uv, float linearEyeDepth) {  
        //         uv.y = 1.0 - uv.y;  

        //         float zScale = linearEyeDepth * _ProjectionParams2.x; // divide by near plane  
        //         float3 worldPos = _CameraViewTopLeftCorner.xyz + _CameraViewXExtent.xyz * uv.x + _CameraViewYExtent.xyz * uv.y;  
        //         float3 dir = worldPos - _WorldSpaceCameraPos.xyz;
        //         dir *= zScale;
        //         worldPos = _WorldSpaceCameraPos.xyz + dir;  
        //         return worldPos;  
        //     }
        //     float4 TransformViewToHScreen(float3 vpos, float2 screenSize) {  
        //         float4 cpos = mul(UNITY_MATRIX_P, vpos);  
        //         cpos.xy = float2(cpos.x, cpos.y * _ProjectionParams.x) * 0.5 + 0.5 * cpos.w;  
        //         cpos.xy *= screenSize;  
        //         return cpos;  
        //     } 

        //     // 通过世界坐标计算 屏幕uv 和 zview
        //     void ReconstructUVAndDepth(float3 wpos, out float2 uv, out float depth) {  
        //         float4 cpos = mul(UNITY_MATRIX_VP, float4(wpos,1));  
        //         uv = float2(cpos.x, cpos.y * _ProjectionParams.x) / cpos.w * 0.5 + 0.5;  
        //         depth = cpos.w;
        //     }

        //     float4 GetSource(half2 uv) {  
        //         return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearRepeat, uv, _BlitMipLevel);  
        //     }

             

        //     float4 SSRPassFragment(Varyings input):SV_Target{
        //         float rawDepth = SampleSceneDepth(input.texcoord);
        //         float linearDepth = LinearEyeDepth(rawDepth,_ZBufferParams);

        //         float3 pos = ReconstructWorldPos(input.texcoord, linearDepth);
        //         float3 normal = SampleSceneNormals(input.texcoord); 
        //         float3 vDir = normalize(pos-_ProjectionParams2.yzw);  
        //         float3 rDir = TransformWorldToViewDir(normalize(reflect(vDir, normal)));

        //         // 获得View空间位置
        //         float magnitude = MAXDISTANCE; 
        //         float3 startView = TransformWorldToView(pos);  
        //         float end = startView.z + rDir.z * magnitude;  
        //         // 将最大位移后超出近平面的向量强制转移到近平面上
        //         if (end > -_ProjectionParams.y)  
        //             magnitude = (-_ProjectionParams.y - startView.z) / rDir.z;  
        //         float3 endView = startView + rDir * magnitude; 

        //         // 齐次屏幕空间坐标  
        //         float4 startHScreen = TransformViewToHScreen(startView, _SourceSize.xy);  
        //         float4 endHScreen = TransformViewToHScreen(endView, _SourceSize.xy); 

        //         // inverse w  
        //         float startK = 1.0 / startHScreen.w;  
        //         float endK = 1.0 / endHScreen.w;  

        //         //  结束屏幕空间坐标  
        //         float2 startScreen = startHScreen.xy * startK;  
        //         float2 endScreen = endHScreen.xy * endK;  

        //         // 经过齐次除法的视角坐标  
        //         float3 startQ = startView * startK;  
        //         float3 endQ = endView * endK;  

        //         // 根据斜率将dx=1 dy = delta  
        //         float2 diff = endScreen - startScreen;  
        //         bool permute = false;  
        //         if (abs(diff.x) < abs(diff.y)) {  
        //             permute = true;  

        //             diff = diff.yx;  
        //             startScreen = startScreen.yx;  
        //             endScreen = endScreen.yx;  
        //         }  

        //         // 计算屏幕坐标、齐次视坐标、inverse-w的线性增量  
        //         float dir = sign(diff.x);  
        //         float invdx = dir / diff.x;  
        //         float2 dp = float2(dir, invdx * diff.y);  
        //         float3 dq = (endQ - startQ) * invdx;  
        //         float dk = (endK - startK) * invdx;  

        //         dp *= STRIDE;  
        //         dq *= STRIDE;  
        //         dk *= STRIDE;

        //         // 缓存当前深度和位置  
        //         float rayZMin = startView.z;  
        //         float rayZMax = startView.z;  
        //         float preZ = startView.z;  

        //         float2 P = startScreen;  
        //         float3 Q = startQ;  
        //         float K = startK;  

        //         float mipLevel = 0.0;

        //         float2 hitUV = 0.0;

        //         end = endScreen.x * dir;  

        //         // float2 ditherUV = fmod(P, 4);  
        //         // float jitter = dither[ditherUV.x * 4 + ditherUV.y];  

        //         // P += dp * jitter;  
        //         // Q.z += dq.z * jitter;  
        //         // K += dk * jitter;

        //         // 进行屏幕空间射线步近  
        //         UNITY_LOOP  
        //         for (int i = 0; i < STEP_COUNT && P.x * dir <= end; i++) {  
        //             // 步近  
        //             P += dp * exp2(mipLevel);
        //             Q += dq * exp2(mipLevel);
        //             K += dk * exp2(mipLevel);

        //             // 得到步近前后两点的深度  
        //             rayZMin = preZ;  
        //             rayZMax = (dq.z * exp2(mipLevel) * 0.5 + Q.z) / (dk * exp2(mipLevel) * 0.5 + K);
        //             preZ = rayZMax;        
        //             if (rayZMin > rayZMax)  
        //                 swap(rayZMin, rayZMax);  

        //             // 得到交点uv  
        //             float2 hitUV = permute ? P.yx : P;  
        //             hitUV *= _SourceSize.zw;  
        //             if (any(hitUV < 0.0) || any(hitUV > 1.0))  
        //                 //return GetSource(input.texcoord);  
        //                 return float4(0,0,0,1); 

        //             if (intersecting)  
        //                 return GetSource(hitUV);  
        //             float rawDepth = SAMPLE_TEXTURE2D_X_LOD(_HiZBufferTexture, sampler_HiZBufferTexture, hitUV, mipLevel);
        //             float surfaceDepth = -LinearEyeDepth(rawDepth, _ZBufferParams);

        //             bool behind = rayZMin + 0.1 <= surfaceDepth;

        //             if (!behind) {
        //                 mipLevel = min(mipLevel + 1, _MaxHiZBufferTextureipLevel);
        //             }
        //             else {
        //                 if (mipLevel == 0) {
        //                     if (abs(surfaceDepth - rayZMax) < THICKNESS)
        //                         return GetSource(hitUV);
        //                 }
        //                 else {
        //                     P -= dp * exp2(mipLevel);
        //                     Q -= dq * exp2(mipLevel);
        //                     K -= dk * exp2(mipLevel);
        //                     preZ = Q.z / K;

        //                     mipLevel--;
        //                 }
        //             }
        //         }  
        //         //return GetSource(input.texcoord);  
        //         return float4(0,0,0,1);  
        //     }


        //     ENDHLSL
        // }

    }
}


