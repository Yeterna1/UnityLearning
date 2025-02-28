Shader "Unlit/MetaBall"
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

            float _MetaBallCount;
            float4 _MetaBallParams1;
            float4 _MetaBallParams2;
            float _BlendWidth;

            float _MaxStep;
            float _ClipSDFValue;

            float4 _ProjectionParams2;  
            float4 _CameraViewTopLeftCorner;  
            float4 _CameraViewXExtent;  
            float4 _CameraViewYExtent;  
            float4 _SourceSize;

            float4 _MetaBalls[10];

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

            float sdSphere(float3 p, float s)
            {
               return length(p)-s;
            }

            // quadratic polynomial
            float smin( float a, float b, float k )
            {
                k *= 4.0;
                float h = max( k-abs(a-b), 0.0 )/k;
                return min(a,b) - h*h*k*(1.0/4.0);
            }

            float4 GetSource(half2 uv) {  
                return SAMPLE_TEXTURE2D_X_LOD(_BlitTexture, sampler_LinearRepeat, uv, _BlitMipLevel);  
            }

            // float CalSphere1SDF(float3 worldPos){
            //     return sdSphere(worldPos - _CustomDataBuffer[0].xyz,_CustomDataBuffer[0].w);
            // }

            float CalSphere1SDF(float3 worldPos){
                return sdSphere(worldPos - _MetaBallParams1.xyz,_MetaBallParams1.w);
            }

            float CalSphere2SDF(float3 worldPos){
                return sdSphere(worldPos - _MetaBallParams2.xyz,_MetaBallParams2.w);
            }

            // float CalSphereSDF(float3 worldPos,int index){
            //     return sdSphere(worldPos - _CustomDataBuffer[index].xyz,_CustomDataBuffer[index].w);
            // }

            float CalSphereSDF(float3 worldPos,int index){
                return sdSphere(worldPos - _MetaBalls[index].xyz,_MetaBalls[index].w);
            }

            // float sceneSDF(float3 pos){
            //     return smin(CalSphere1SDF(pos),CalSphere2SDF(pos),_BlendWidth);
            // }

            float sceneSDF(float3 pos,float3 reconstructPos){

                //float result = length(pos-reconstructPos);
                float result = 1;
                UNITY_LOOP
                for(int i = 0; i < _MetaBallCount; i++){
                    float currentSDF = CalSphereSDF(pos,i);
                    //result = (i!=0 ||(i==0 &&result<0.1))? smin(result, currentSDF, _BlendWidth):currentSDF;
                    result = smin(result, currentSDF, _BlendWidth);
                }
                result = (result<length(pos-reconstructPos)&& result<_BlendWidth)? smin(result,length(pos-reconstructPos),_BlendWidth):result;
                return result;

            }

            float3 estimateNormal(float3 p,float3 reconstructPos) {
                float3 temp = float3(
                    sceneSDF(float3(p.x + EPSILON, p.y, p.z),reconstructPos) - sceneSDF(float3(p.x - EPSILON, p.y, p.z),reconstructPos),
                    sceneSDF(float3(p.x, p.y + EPSILON, p.z),reconstructPos) - sceneSDF(float3(p.x, p.y - EPSILON, p.z),reconstructPos),
                    sceneSDF(float3(p.x, p.y, p.z  + EPSILON),reconstructPos) - sceneSDF(float3(p.x, p.y, p.z - EPSILON),reconstructPos)
                );
                temp = (length(temp)>0.01)? normalize(temp): float3(0,0,0);

                return temp;
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
                float rayStep = sceneSDF(curPos,reconstructPosWS);

                float3 col = 0;
                
                UNITY_LOOP
                for (int i = 0; i < _MaxStep && rayStep > 0.01; i++) {  
                    // 步近  
                    curPos += V * rayStep;
                    rayStep = sceneSDF(curPos,reconstructPosWS);
                }

                float3 estimateN = estimateNormal(curPos,reconstructPosWS); 

                
                float metaBallMask = step(0.1,abs(estimateN.x)+abs(estimateN.y)+abs(estimateN.z));
                metaBallMask *= step(0,dot(reconstructPosWS-curPos,V));

                col = estimateN;
                
                float NdotV = dot(estimateN,V) * 0.5+0.5;
                float random = N31(curPos);
                float random2 = N31(estimateN);

                float2 uv = frac(curPos.xz * 0.1 + estimateN.xy*sin(_Time.x));

                col = tex2D(_MainTex,uv);

                col = blendScene(col,input.texcoord,metaBallMask);

                float4 res = float4(col,1);

                return res;
            }

            ENDHLSL
        }
    }
}
