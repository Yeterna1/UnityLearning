using UnityEngine;

[ExecuteInEditMode]
public class ConeController : MonoBehaviour
{
    [Header("锥体参数")]
    [Range(1, 179)]
    public float angle = 60f;          // 圆锥顶角（角度制）
    [Min(0)]
    public float height = 5f;          // 锥体高度
    public Color gizmoColor = new Color(0, 1, 0, 0.5f); // Gizmo颜色

    [Header("显示设置")]
    [Range(3, 64)]
    public int edgeSegments = 36;      // 边缘细分精度
    public bool showWireframe = true;  // 显示线框
    public bool showRadiusGuide;      // 显示半径辅助线

    // 内部计算参数
    private Vector4 sdfParams; // x:sinθ, y:cosθ, z:height
    //private Matrix4x4 worldToLocalMatrix;

    private void OnDrawGizmos()
    {
        // 计算基础参数
        Vector3 tipPosition = transform.position;
        Vector3 baseCenter = tipPosition - transform.up * height;
        float radius = CalculateBaseRadius();

        Gizmos.color = gizmoColor;

        // 绘制底面圆
        if (showWireframe) DrawBaseCircle(baseCenter, radius);

        // 绘制锥体侧面
        if (showWireframe) DrawConicalSurface(tipPosition, baseCenter, radius);

        // 绘制辅助线
        if (showRadiusGuide) DrawRadiusGuides(tipPosition, baseCenter, radius);
    }

    void Update()
    {
        CalculateSDFParameters();
        UpdateMaterialProperties();
    }

    // 计算底面半径（三角函数计算）
    private float CalculateBaseRadius()
    {
        float halfAngle = angle * 0.5f * Mathf.Deg2Rad;
        return height * Mathf.Tan(halfAngle);
    }

    // 绘制底面圆
    private void DrawBaseCircle(Vector3 center, float radius)
    {
        Vector3 prevPoint = center + transform.right * radius;
        for (int i = 1; i <= edgeSegments; i++)
        {
            float theta = i * Mathf.PI * 2 / edgeSegments;
            Vector3 nextPoint = center +
                transform.right * (Mathf.Cos(theta) * radius) +
                transform.forward * (Mathf.Sin(theta) * radius);

            Gizmos.DrawLine(prevPoint, nextPoint);
            prevPoint = nextPoint;
        }
    }

    // 绘制锥体侧面
    private void DrawConicalSurface(Vector3 tip, Vector3 baseCenter, float radius)
    {
        for (int i = 0; i < edgeSegments; i++)
        {
            float theta = i * Mathf.PI * 2 / edgeSegments;
            Vector3 edgePoint = baseCenter +
                transform.right * (Mathf.Cos(theta) * radius) +
                transform.forward * (Mathf.Sin(theta) * radius);

            // 绘制边缘线
            Gizmos.DrawLine(tip, edgePoint);

            // 绘制底面半径线
            if (showWireframe) Gizmos.DrawLine(baseCenter, edgePoint);
        }

        // 绘制中心轴线
        Gizmos.DrawLine(tip, baseCenter);
    }

    // 绘制半径辅助线（调试用）
    private void DrawRadiusGuides(Vector3 tip, Vector3 baseCenter, float radius)
    {
        Gizmos.color = Color.yellow;
        Vector3 rightPoint = baseCenter + transform.right * radius;
        Vector3 upPoint = baseCenter + transform.up * radius;

        Gizmos.DrawLine(tip, rightPoint);
        Gizmos.DrawLine(tip, upPoint);
        Gizmos.DrawWireSphere(rightPoint, 0.1f);
        Gizmos.DrawWireSphere(upPoint, 0.1f);
    }

    void CalculateSDFParameters()
    {
        // 计算半角三角函数
        float halfAngle = angle * 0.5f * Mathf.Deg2Rad;
        sdfParams.x =  Mathf.Sin(halfAngle);
        sdfParams.y = Mathf.Cos(halfAngle);
        sdfParams.z = height;
        sdfParams.w = 0.5f / Mathf.PI;

        // 构建世界到本地空间的矩阵（考虑旋转和位移）
        //worldToLocalMatrix = transform.localToWorldMatrix.inverse;
    }

    void UpdateMaterialProperties()
    {
        Shader.SetGlobalVector("_ConeParams", sdfParams);
        Shader.SetGlobalMatrix("_WorldToConeSpace", transform.worldToLocalMatrix);
    }

    // 实时验证参数有效性
    private void OnValidate()
    {
        angle = Mathf.Clamp(angle, 1, 179);
        height = Mathf.Max(0, height);
        edgeSegments = Mathf.Clamp(edgeSegments, 3, 64);
    }
}