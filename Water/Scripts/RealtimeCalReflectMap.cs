
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UIElements;

public class RealtimeCalReflectMap : MonoBehaviour
{
    public Transform MirrorSurfacePos;

    private RenderTexture ReflectRT;
    private RenderTexture ReflectRT2;

    public GameObject targetObj;
    private Material material;
    private GameObject cameraObj;
    public Material waterSurface;
    private Camera Cam;

    private Vector4 plane;

    private static readonly int WaterTex = Shader.PropertyToID("_ReflectMap");

    private const RenderTextureFormat RTFormat = RenderTextureFormat.ARGB32;
    private const int RTDepth = 24;


    void Start()
    {
        CreateRenderTextures();

        if (cameraObj == null)
        {
            cameraObj = new GameObject("ReflectCam");
        }
        if (Cam == null)
        {
            Cam = cameraObj.AddComponent<Camera>();
        }
        Cam.depth = Camera.main.depth - 1;
        Cam.targetTexture = ReflectRT;
    }

    void CreateRenderTextures()
    {
        ReflectRT = new RenderTexture(Screen.width, Screen.height, RTDepth, RTFormat);
        ReflectRT2 = new RenderTexture(Screen.width, Screen.height, RTDepth, RTFormat);

        ReflectRT.Create();
        ReflectRT2.Create();
    }

    void Update()
    {
        if (ScreenSizeChanged())
            CreateRenderTextures();

        CalRefCamPos();
        CalRTTransform();
        CalProjectionMatrix();
    }

    bool ScreenSizeChanged()
    {
        return ReflectRT.width != Screen.width || ReflectRT.height != Screen.height;
    }

    void CalRefCamPos()
    {
        if (cameraObj == null)
        {
            cameraObj = new GameObject("ReflectCam");
        }
        if (Cam == null)
        {
            Cam = cameraObj.AddComponent<Camera>();
        }
        //Debug.Log("CalPos");
        Vector3 vec0 = MirrorSurfacePos.up.normalized;
        //Debug.Log("vec0" + vec0);
        Vector3 vec1 = this.transform.position - MirrorSurfacePos.position;
        //Debug.Log("vec1" + vec1);
        float dis = vec0.x * vec1.x + vec0.y * vec1.y + vec0.z * vec1.z;
        Vector3 rotation = this.gameObject.transform.rotation.eulerAngles;
        //Debug.Log(this.transform.rotation);
        //Debug.Log("1" + rotation);
        rotation.x = -rotation.x;
        rotation.z = 180;
        //Debug.Log(dis);
        //Debug.Log("2" + rotation);
        cameraObj.transform.position = this.transform.position + 2 * dis * -vec0;
        cameraObj.transform.rotation = Quaternion.Euler(rotation);
        Renderer renderer = targetObj.GetComponent<Renderer>();
        material = renderer.sharedMaterial;
        material.SetTexture("_ReflectMap", ReflectRT2);
        waterSurface.SetTexture("_ReflectMap", ReflectRT2);
    }

    void CalRTTransform()
    {
        Graphics.Blit(ReflectRT, ReflectRT2, new Vector2(-1, 1), new Vector2(1, 0));
    }

    void CalProjectionMatrix()
    {
        //Debug.Log(MirrorSurfacePos.up.normalized);
        //Debug.Log(MirrorSurfacePos.position);
        plane.x = MirrorSurfacePos.up.normalized.x;
        plane.y = MirrorSurfacePos.up.normalized.y;
        plane.z = MirrorSurfacePos.up.normalized.z;
        plane.w = -MirrorSurfacePos.position.x * MirrorSurfacePos.up.normalized.x -
            MirrorSurfacePos.position.y * MirrorSurfacePos.up.normalized.y -
            MirrorSurfacePos.position.z * MirrorSurfacePos.up.normalized.z;
        //Debug.Log("plane" + plane);
        plane = Cam.worldToCameraMatrix.inverse.transpose * plane;//将世界空间中的平面表示转换成相机空间中的平面表示
        Matrix4x4 newProjectionMatrix = Cam.CalculateObliqueMatrix(plane);
        Cam.projectionMatrix = newProjectionMatrix;
    }
}


