
float3 customLerp(float3 a, float3 b, float t)
{
    return a + t * (b - a);
}

// 通过对CameraDepthTexture得到的worldSpace下的Depth
float TransformDepthTextureToWorld(float depth)
{
    
}

// 错误计算 如要使用获取深度缓冲中的 深度值 可以使用 SampleSceneDepth函数
float TransformViewToClipDepth(float depth)
{
    float t = (_ProjectionParams.y + _ProjectionParams.z) / (_ProjectionParams.y - _ProjectionParams.z) * depth
    + (_ProjectionParams.y * _ProjectionParams.z) / (_ProjectionParams.y - _ProjectionParams.z) * -1.0f;
    return t;
}


// SSR光线步进
float3 SSRRayMarching(float3 startPosWS, float3 direction,float normalWS, float rayLength,float maxSteps, float minLostDist)
{
    float3 color = 0;
    float3 p = startPosWS;
    float4 pCS = 0;
    
    //[unroll(20)]
    //for(int i = 0; i < maxSteps; i++)
    //{
    //    p += direction * rayLength;
    //    pCS = TransformWorldToHClip(p);
    //    float2 uv = pCS.xy / _ScreenParams.xy;
    //    float tdepth = SampleSceneDepth(uv);

    //    if (tdepth < pCS.z && pCS.z < tdepth + minLostDist)
    //    {
    //        color = i;
    //        color = float3(1, 1, 1);
    //        //return float3(0,0,0);
    //        //color = direction;
    //        break;
    //    }
    //}
    //p += direction * rayLength;
    pCS = TransformWorldToHClip(p);
    float2 uv = pCS.xy / _ScreenParams.xy;
    float tdepth = SampleSceneDepth(uv);

    //if (tdepth < pCS.z && pCS.z < tdepth + minLostDist)
    if (tdepth == pCS.z)
    {
        color = float3(1, 1, 1);

    }
    
    return color;
}

///
/// color effect
///

// cal desaturation
float3 desaturation(float3 color)
{
    float3 grayf = dot(color, float3(0.3, 0.59, 0.11));
    
    return grayf;
    //float3(grayf, grayf, grayf);

}
// cal desaturation
float3 desaturation(float3 color, float f)
{
    float3 grayf = dot(color, float3(0.3, 0.59, 0.11));
    return (1 - f)* grayf + f * color;
}

///
/// wet color calculate
///
float3 CalColorWetness(float3 baseColor,float desaturationf,float darkness,float isWet,float lerp)
{

    float3 desaColor = desaturation(baseColor, desaturationf) * darkness;
    
    float3 res = customLerp(baseColor, desaColor, isWet*lerp);

    return res;
}