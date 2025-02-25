float N21(float2 p)
{
    p = frac(p * half2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return frac(p.x + p.y);
}

float3 N13(float p)
{
    //  from DAVE HOSKINS
    float3 p3 = frac(float3(p, p, p) * float3(.1031, .11369, .13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return frac(float3((p3.x + p3.y) * p3.z, (p3.x + p3.z) * p3.y, (p3.y + p3.z) * p3.x));
}

float3 N14(float t)
{
    return frac(sin(t * float4(123., 1024., 1456., 264.)) * float4(6547., 345., 8799., 1564.));
}
float N(float t)
{
    return frac(sin(t * 12345.564) * 7658.76);
}

float Saw(float b, float t)
{
    return smoothstep(0., b, t) * smoothstep(1., b, t);
}

float2 DynamicDroplet(float aspect, float size, float density, float time, float speed, float normaly, float2 uv)
{
    // Ӧ���ٶ� ��Сʱһ��ѭ��
    float t = fmod(time * speed, 7200);
    
    float2 inituv = uv;
    // ��uv���ֳɶ��С��
    uv *= aspect * size;
    uv.y += t * 0.25;
    // ��������ı任Ϊ��0��0��
    float2 cuv = frac(uv) - 0.5;
    // idӦ����ÿһ���Լ�����������仯
    half2 id = floor(uv);
    float offset = N21(id);
    t += 3.1415 * 2 * offset;
    offset -= 0.5;
    offset *= 0.8;
    
    // ��ȡ���ӵı任�õ�drop���pos
    float w = inituv.y * 10;
    float2 dynamicDrop = float2(offset + (0.4 - abs(offset)) * sin(3 * w) * pow(sin(w), 6) * 0.45, -sin(t + sin(t + sin(t) * 0.5)) * 0.4);
    dynamicDrop.y -= (cuv.x - dynamicDrop.x) * (cuv.x - dynamicDrop.x);
    float2 dropPos = (cuv - dynamicDrop) / aspect;
    
    // ��ȡ�켣���Pos 
    float2 trailPos = (cuv - half2(dynamicDrop.x, t * 0.25)) / aspect;
    trailPos.y = (frac(trailPos.y * 8) - 0.5) / 8;
    
    float trail = smoothstep(0.03 * size / density, 0.01, length(trailPos));
    float drop = smoothstep(0.05 * size / density, 0.03, length(dropPos));
    float fogTrail = smoothstep(-0.05, 0.05, dropPos.y);
    
    fogTrail *= smoothstep(0.5, dynamicDrop.y, cuv.y);
    fogTrail *= smoothstep(0.05, 0.04, abs(dropPos.x));
    trail *= fogTrail;
    // �õ�ƫ�ƺ��uv
    uv = drop * dropPos + trail * trailPos;
    return uv;
}

float2 StaticDroplet(float aspect, float size, float density, float2 uv)
{

    float2 inituv = uv;
    // ��uv���ֳɶ��С��
    uv *= aspect * density;
    // ��������ı任Ϊ��0��0��
    float2 cuv = frac(uv) - 0.5;
    // idӦ����ÿһ���Լ�����������仯
    half2 id = floor(uv);
    float offset = N21(id);
    offset -= 0.5;
    offset *= 0.8; //(-0.4-0.4)
    
    // ��ȡ���ӵı任�õ�drop���pos
    float w = inituv.y * 10;
    float2 dynamicDrop = float2(offset + (0.4 - abs(offset)) * sin(3 * w) * pow(sin(w), 6) * 0.125, offset);
    float2 dropPos = (cuv - dynamicDrop) / aspect;
    
    float drop = smoothstep(0.05 * size / density, 0.03, length(dropPos));
    // �õ�ƫ�ƺ��uv
    uv = drop * dropPos;
    return uv;
}
