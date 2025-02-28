Shader "Hidden/MagicLight"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Pass
        {
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag

            #define MAX_STEP_COUNT 20
            #define EPSILON 0.1

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"  
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareNormalsTexture.hlsl"  
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl" 

            sampler2D _MainTex;
            float4 _MainTex_ST; // 添加纹理缩放偏移变量


            float _MaxStep;

            float4 _ProjectionParams2;  
            float4 _CameraViewTopLeftCorner;  
            float4 _CameraViewXExtent;  
            float4 _CameraViewYExtent;  
            float4 _SourceSize;

            ////////
            // 
            ///////
            float4 _MagicLightParams1;
            float4 _MagicLightParams2;
            float4 _ConeParams;
            float4x4 _WorldToConeSpace;

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


            //StructuredBuffer<float4> _CustomDataBuffer;

            float N21(float2 p)
            {
                p = frac(p * half2(123.34, 345.45));
                p += dot(p, p + 34.345);
                return frac(p.x + p.y);
            }

            float N(float t)
            {
                return frac(sin(t * 12345.564) * 7658.76);
            }

            float N31(float3 p)
            {
                p = frac(p * float3(123.34, 345.45,45.56));
                p += dot(p, p + 34.345);
                
                return frac(p.x + p.y);
            }

            float3 ReconstructWorldPos(float2 uv, float linearEyeDepth) {  
                uv.y = 1.0 - uv.y;  

                float zScale = linearEyeDepth * _ProjectionParams2.x; // divide by near plane  
                float3 worldPos = _CameraViewTopLeftCorner.xyz + _CameraViewXExtent.xyz * uv.x + _CameraViewYExtent.xyz * uv.y;  
                float3 dir = worldPos - _WorldSpaceCameraPos.xyz;
                dir *= zScale;
                worldPos = _WorldSpaceCameraPos.xyz + dir;  
                return worldPos;  
            }

            float3 ReconstructViewDirection(float2 uv){
                uv.y = 1.0 - uv.y;  
                float3 worldPos = _CameraViewTopLeftCorner.xyz + _CameraViewXExtent.xyz * uv.x + _CameraViewYExtent.xyz * uv.y;  
                float3 viewDir = normalize(worldPos - _WorldSpaceCameraPos.xyz);
                return viewDir;
            }

            float4 GetSource(half2 uv) {  
                return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearRepeat, uv, _BlitMipLevel);  
            }


            float CalConeSDF(float3 worldPos,float2 sdfc,float sdfh){
                 float3 localPos = mul(_WorldToConeSpace,float4(worldPos,1)).xyz;
                return sdCone(localPos,sdfc,sdfh);
            }

            float CalConeSDF(float3 worldPos){
                 float3 localPos = mul(_WorldToConeSpace,float4(worldPos,1)).xyz;
                return sdCone(localPos,_ConeParams.xy,_ConeParams.z);
            }

            float sceneSDF(float3 pos){
                return CalConeSDF(pos);
            }

            float3 blendScene(float3 col,float2 uv,float mask){
                return GetSource(uv)*(1-mask)+col*mask;
            }


            half4 frag(Varyings input) : SV_Target
            {

                float3 V = ReconstructViewDirection(input.texcoord);

                //基于屏幕坐标深度世界坐标重建
                float2 screenPos = input.texcoord;
                float rawDepth = SampleSceneDepth(screenPos);
                float linearDepth = LinearEyeDepth(rawDepth,_ZBufferParams);
                float3 reconstructPosWS = ReconstructWorldPos(screenPos, linearDepth);

                float3 cameraPosWS = _WorldSpaceCameraPos.xyz;

                // 光线步进预计算
                float3 curPos = _WorldSpaceCameraPos.xyz;
                float rayStep = _MagicLightParams2.y;

                float3 col = 0;
                
                UNITY_LOOP
                for (int i = 0; i < _MagicLightParams2.x; i++) {  
                    // 步近  
                    col += step(sceneSDF(curPos),0) * _MagicLightParams2.z;
                    curPos += V * rayStep;
                }

                //col = tex2D(_MainTex,uv);
                //col = blendScene(col,input.texcoord,metaBallMask);
                col *= _MagicLightParams1.xyz * _MagicLightParams1.w;
                col += GetSource(input.texcoord);

                float4 res = float4(col,1);
                //res = float4(1,1,1,1);

                return res;
            }

            ENDHLSL
        }
    }
}
