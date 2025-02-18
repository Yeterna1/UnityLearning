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
    return positionWS.xyz;
}