Shader "Unlit/WorldPosReconstruct"
{
    Properties
    {
       [Toggle(REQUIRE_POSITION_VS)] 
	   _Require_Position_VS("Require Position VS", float) = 0
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl" 
    #pragma multi_compile _ REQUIRE_POSITION_VS

    //sampler2D _CameraDepthTexture;
    
    struct Attributes
    {
        float4 positionOS   : POSITION;
        float2 texcoord     : TEXCOORD0;
    };

    struct Varyings
    {
        float4 positionCS   : SV_POSITION;
        float2 texcoord     : TEXCOORD0;
    };

    Varyings Vert(Attributes input)
    {
        Varyings output = (Varyings)0;
		// 根据顶点在其模型坐标系下的值，计算得到在裁剪空间中的齐次坐标
        VertexPositionInputs vertexPositionInputs = 
		                     GetVertexPositionInputs(input.positionOS.xyz);
							 
		// vertexPositionInputs.positionCS的是齐次裁剪空间坐标，即一个 float4 值，
		// 形式为 (x, y, z, w)，其中 w 是用于透视除法的分量。透视除法会在后续的处理
		// 步骤中进行，得到标准化设备坐标（NDC），最终决定物体在屏幕上的位置。
		// 在透视除法之前，齐次裁剪空间的 x 和 y 值可以超出任何特定范围，因为它们与
		// w 是关联的。最终，它们会通过透视除法得到以下标准化的范围
		// 透视除法后（标准化设备坐标）的取值范围：
		// x / w 和 y / w 的取值范围为 [-1, 1]。
		// -1 表示屏幕的最左边（x 方向）或最下方（y 方向）。
		// 1 表示屏幕的最右边（x 方向）或最上方（y 方向）。
        output.positionCS = vertexPositionInputs.positionCS;
        output.texcoord = input.texcoord;
        return output;
    }

    float4 Frag(Varyings input) : SV_TARGET
    {
	    // 根据片元的在裁剪空间中的坐标值，算出片元对应的在屏幕空间的坐标值
		// _ScreenParams的xy分量是渲染目标纹理的宽度和高度（以像素为单位），
		// z分量是1.0 + 1.0/宽度，w为1.0 + 1.0/高度。所以屏幕空间的坐标值为
		//【齐次裁剪空间坐标】的坐标值的xy，分别除以渲染目标纹理的高宽
		
		// 因为input.positionCS.xy的取值范围是[0,渲染目标纹理的宽]和
		// [0,渲染目标纹理的高]，故而positionSS的xy分量，经过上一步的运算后，
		// 分别得到的取值范围是[0,1]。就是一个有效的纹理坐标uv值
        float2 positionSS = input.positionCS.xy / _ScreenParams.xy;
		
		// 利用纹理坐标uv值，对深度图纹理进行采样，得到的值，就是当前屏幕空间中
		// 片元对应的深度值，即NDC空间中的坐标值z分量
		// _CameraDepthTexture是Unity3D的内置着色器变量
        //float depth = tex2D(_CameraDepthTexture, positionSS).r;
        float mydepth = SampleSceneDepth(positionSS);
		
		// 因为NDC空间的取值范围是：
		// X和Y轴的取值范围：[-1, 1]。
		// -1表示屏幕的最左侧或最底部。1表示屏幕的最右侧或最顶部。
		// Z轴的取值范围是[0, 1]。0和1分别表示相机的近截平面和远截平面
		// 而positionSS的取值范围是[0,1]，所以需要做【乘2减1】的操作，将其映射到
		// [-1,1]的取值范围内。
        float3 positionNDC = float3(positionSS * 2 - 1, mydepth);

#if UNITY_UV_STARTS_AT_TOP
        positionNDC.y = -positionNDC.y;
#endif

		// 得到裁剪空间的NDC坐标之后，就可以反向地推出片元对应的屏幕空间了
#if REQUIRE_POSITION_VS
		// UNITY_MATRIX_I_P是投影矩阵的逆矩阵(inverse projection matrix)
        float4 positionVS = mul(UNITY_MATRIX_I_P, float4(positionNDC, 1));
		
		// 当你通过逆投影矩阵将点从 clip space 变换回 view space 时，生成的点仍
		// 然是齐次坐标 (x, y, z, w)，因此需要除以 w 来将其转换回标准的三维欧几里
		// 得坐标。这是因为：在齐次坐标系下，w 分量影响了 x、y 和 z 分量的比例。
		// 如果不除以 w，这些分量的值将无法正确反映物体在视图空间中的位置，导致不正
		// 确的几何表示。view space中的坐标应该是三维欧几里得坐标，而不是齐次坐标。
		// 透视除法确保得到的 x'、y'、z' 是正确的三维位置。
        positionVS /= positionVS.w;
		
		// 再通过观察矩阵的逆矩阵，将顶点变换回世界坐标
        float4 positionWS = mul(UNITY_MATRIX_I_V, positionVS);
#else
        float4 positionWS = mul(UNITY_MATRIX_I_VP, float4(positionNDC, 1));
        positionWS /= positionWS.w;
#endif

        return float4(positionWS.xz,0,1);
    }

    float4 DepthFrag(Varyings input) : SV_TARGET
    {
        return 0;
    }

    ENDHLSL

    SubShader
    {
        Tags{ "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            Tags{"LightMode"="UniversalForward"}
            ZWrite On
            ZTest LEqual
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag
            ENDHLSL
        }

        Pass
        {
            Tags{"LightMode" = "DepthOnly"}
            ZWrite On
            ZTest LEqual
            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment DepthFrag
            ENDHLSL
        }
    }
}