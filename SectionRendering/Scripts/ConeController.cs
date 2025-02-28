using UnityEngine;

[ExecuteInEditMode]
public class ConeController : MonoBehaviour
{
    [Header("׶�����")]
    [Range(1, 179)]
    public float angle = 60f;          // Բ׶���ǣ��Ƕ��ƣ�
    [Min(0)]
    public float height = 5f;          // ׶��߶�
    public Color gizmoColor = new Color(0, 1, 0, 0.5f); // Gizmo��ɫ

    [Header("��ʾ����")]
    [Range(3, 64)]
    public int edgeSegments = 36;      // ��Եϸ�־���
    public bool showWireframe = true;  // ��ʾ�߿�
    public bool showRadiusGuide;      // ��ʾ�뾶������

    // �ڲ��������
    private Vector4 sdfParams; // x:sin��, y:cos��, z:height
    //private Matrix4x4 worldToLocalMatrix;

    private void OnDrawGizmos()
    {
        // �����������
        Vector3 tipPosition = transform.position;
        Vector3 baseCenter = tipPosition - transform.up * height;
        float radius = CalculateBaseRadius();

        Gizmos.color = gizmoColor;

        // ���Ƶ���Բ
        if (showWireframe) DrawBaseCircle(baseCenter, radius);

        // ����׶�����
        if (showWireframe) DrawConicalSurface(tipPosition, baseCenter, radius);

        // ���Ƹ�����
        if (showRadiusGuide) DrawRadiusGuides(tipPosition, baseCenter, radius);
    }

    void Update()
    {
        CalculateSDFParameters();
        UpdateMaterialProperties();
    }

    // �������뾶�����Ǻ������㣩
    private float CalculateBaseRadius()
    {
        float halfAngle = angle * 0.5f * Mathf.Deg2Rad;
        return height * Mathf.Tan(halfAngle);
    }

    // ���Ƶ���Բ
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

    // ����׶�����
    private void DrawConicalSurface(Vector3 tip, Vector3 baseCenter, float radius)
    {
        for (int i = 0; i < edgeSegments; i++)
        {
            float theta = i * Mathf.PI * 2 / edgeSegments;
            Vector3 edgePoint = baseCenter +
                transform.right * (Mathf.Cos(theta) * radius) +
                transform.forward * (Mathf.Sin(theta) * radius);

            // ���Ʊ�Ե��
            Gizmos.DrawLine(tip, edgePoint);

            // ���Ƶ���뾶��
            if (showWireframe) Gizmos.DrawLine(baseCenter, edgePoint);
        }

        // ������������
        Gizmos.DrawLine(tip, baseCenter);
    }

    // ���ư뾶�����ߣ������ã�
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
        // ���������Ǻ���
        float halfAngle = angle * 0.5f * Mathf.Deg2Rad;
        sdfParams.x =  Mathf.Sin(halfAngle);
        sdfParams.y = Mathf.Cos(halfAngle);
        sdfParams.z = height;
        sdfParams.w = 0.5f / Mathf.PI;

        // �������絽���ؿռ�ľ��󣨿�����ת��λ�ƣ�
        //worldToLocalMatrix = transform.localToWorldMatrix.inverse;
    }

    void UpdateMaterialProperties()
    {
        Shader.SetGlobalVector("_ConeParams", sdfParams);
        Shader.SetGlobalMatrix("_WorldToConeSpace", transform.worldToLocalMatrix);
    }

    // ʵʱ��֤������Ч��
    private void OnValidate()
    {
        angle = Mathf.Clamp(angle, 1, 179);
        height = Mathf.Max(0, height);
        edgeSegments = Mathf.Clamp(edgeSegments, 3, 64);
    }
}