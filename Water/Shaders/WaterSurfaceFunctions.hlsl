float CalculateFresnelTerm(float3 normalWS, float3 viewDirectionWS)
{
    return pow(1.0 - saturate(dot(normalWS, viewDirectionWS)), 5);
}

inline float sqr(float value)
{
    return value * value;
}
inline float SchlickFresnel(float value)
{
    float m = clamp(1 - value, 0, 1);
    return pow(m, 5);
}
inline float G1(float k, float x)
{
    return x / (x * (1 - k) + k);
}
float3 CookTorranceSpec(float NdotL, float LdotH, float NdotH, float NdotV, float roughness, float F0)
{
    float F, D, G;
                //cal D
    float alpha = sqr(roughness);
    float alphaSqr = sqr(alpha);
    float denominator = sqr(NdotH) * (alphaSqr - 1.0) + 1.0f;
    D = alphaSqr / (PI * sqr(denominator));
                //cal F
    float LdotH5 = SchlickFresnel(LdotH);
    F = F0 + (1.0 - F0) * LdotH5;
                //cal G
    float r = roughness + 1;
    float k = sqr(r) / 8;
    float g1L = G1(k, NdotL);
    float g1V = G1(k, NdotV);
    G = g1L * g1V;
    float specular = NdotL * D * F * G;
    return specular;
}

float3 ReconstructWorldPos(half2 screenPos, float depth)
{
    float3 positionNDC = float3(screenPos * 2 - 1, depth);
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
    return positionWS.xyz;
}