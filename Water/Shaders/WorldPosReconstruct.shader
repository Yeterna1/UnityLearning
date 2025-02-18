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
		// ���ݶ�������ģ������ϵ�µ�ֵ������õ��ڲü��ռ��е��������
        VertexPositionInputs vertexPositionInputs = 
		                     GetVertexPositionInputs(input.positionOS.xyz);
							 
		// vertexPositionInputs.positionCS������βü��ռ����꣬��һ�� float4 ֵ��
		// ��ʽΪ (x, y, z, w)������ w ������͸�ӳ����ķ�����͸�ӳ������ں����Ĵ���
		// �����н��У��õ���׼���豸���꣨NDC�������վ�����������Ļ�ϵ�λ�á�
		// ��͸�ӳ���֮ǰ����βü��ռ�� x �� y ֵ���Գ����κ��ض���Χ����Ϊ������
		// w �ǹ����ġ����գ����ǻ�ͨ��͸�ӳ����õ����±�׼���ķ�Χ
		// ͸�ӳ����󣨱�׼���豸���꣩��ȡֵ��Χ��
		// x / w �� y / w ��ȡֵ��ΧΪ [-1, 1]��
		// -1 ��ʾ��Ļ������ߣ�x ���򣩻����·���y ���򣩡�
		// 1 ��ʾ��Ļ�����ұߣ�x ���򣩻����Ϸ���y ���򣩡�
        output.positionCS = vertexPositionInputs.positionCS;
        output.texcoord = input.texcoord;
        return output;
    }

    float4 Frag(Varyings input) : SV_TARGET
    {
	    // ����ƬԪ���ڲü��ռ��е�����ֵ�����ƬԪ��Ӧ������Ļ�ռ������ֵ
		// _ScreenParams��xy��������ȾĿ������Ŀ�Ⱥ͸߶ȣ�������Ϊ��λ����
		// z������1.0 + 1.0/��ȣ�wΪ1.0 + 1.0/�߶ȡ�������Ļ�ռ������ֵΪ
		//����βü��ռ����꡿������ֵ��xy���ֱ������ȾĿ������ĸ߿�
		
		// ��Ϊinput.positionCS.xy��ȡֵ��Χ��[0,��ȾĿ������Ŀ�]��
		// [0,��ȾĿ������ĸ�]���ʶ�positionSS��xy������������һ���������
		// �ֱ�õ���ȡֵ��Χ��[0,1]������һ����Ч����������uvֵ
        float2 positionSS = input.positionCS.xy / _ScreenParams.xy;
		
		// ������������uvֵ�������ͼ������в������õ���ֵ�����ǵ�ǰ��Ļ�ռ���
		// ƬԪ��Ӧ�����ֵ����NDC�ռ��е�����ֵz����
		// _CameraDepthTexture��Unity3D��������ɫ������
        //float depth = tex2D(_CameraDepthTexture, positionSS).r;
        float mydepth = SampleSceneDepth(positionSS);
		
		// ��ΪNDC�ռ��ȡֵ��Χ�ǣ�
		// X��Y���ȡֵ��Χ��[-1, 1]��
		// -1��ʾ��Ļ����������ײ���1��ʾ��Ļ�����Ҳ�������
		// Z���ȡֵ��Χ��[0, 1]��0��1�ֱ��ʾ����Ľ���ƽ���Զ��ƽ��
		// ��positionSS��ȡֵ��Χ��[0,1]��������Ҫ������2��1���Ĳ���������ӳ�䵽
		// [-1,1]��ȡֵ��Χ�ڡ�
        float3 positionNDC = float3(positionSS * 2 - 1, mydepth);

#if UNITY_UV_STARTS_AT_TOP
        positionNDC.y = -positionNDC.y;
#endif

		// �õ��ü��ռ��NDC����֮�󣬾Ϳ��Է�����Ƴ�ƬԪ��Ӧ����Ļ�ռ���
#if REQUIRE_POSITION_VS
		// UNITY_MATRIX_I_P��ͶӰ����������(inverse projection matrix)
        float4 positionVS = mul(UNITY_MATRIX_I_P, float4(positionNDC, 1));
		
		// ����ͨ����ͶӰ���󽫵�� clip space �任�� view space ʱ�����ɵĵ���
		// Ȼ��������� (x, y, z, w)�������Ҫ���� w ������ת���ر�׼����άŷ����
		// �����ꡣ������Ϊ�����������ϵ�£�w ����Ӱ���� x��y �� z �����ı�����
		// ��������� w����Щ������ֵ���޷���ȷ��ӳ��������ͼ�ռ��е�λ�ã����²���
		// ȷ�ļ��α�ʾ��view space�е�����Ӧ������άŷ��������꣬������������ꡣ
		// ͸�ӳ���ȷ���õ��� x'��y'��z' ����ȷ����άλ�á�
        positionVS /= positionVS.w;
		
		// ��ͨ���۲���������󣬽�����任����������
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