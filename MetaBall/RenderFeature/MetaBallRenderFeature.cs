using System;
using Unity.Mathematics;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;


[System.Serializable]
internal class RayMarchingSetting
{
    public int maxStepCount = 100;
    public float epsilon = 0.01f;
    //internal float 
}

[System.Serializable]
internal class MetaBallSettings
{
    public Vector4[] metaBalls = new Vector4[0];
    public float blendWidth = 0.5f;
    public float sdfClipValue = 0.01f;

    public Texture2D metaBallTex;

    public RayMarchingSetting m_RaySettings;

    public RenderPassEvent m_RenderPassEvent;
}




[DisallowMultipleRendererFeature("MetaBallRenderFeature")]
public class MetaBallRenderFeature : ScriptableRendererFeature
{

    [SerializeField]
    private MetaBallSettings m_Settings = new MetaBallSettings();


    //internal ref MetaBallSettings settings => ref m_Settings;

    class CustomRenderPass : ScriptableRenderPass
    {

        private MetaBallSettings mSettings;
        private Material mMaterial;

        private ProfilingSampler mProfilingSampler = new ProfilingSampler("MetaBallRenderFeature");

        private RTHandle mSourceTexture;
        private RTHandle mDestinationTexture;

        private ComputeBuffer buffer;
        private int lastMetaBallCount = -1;

        // shader中需要用到的传入值
        private static readonly int mProjectionParams2ID = Shader.PropertyToID("_ProjectionParams2"),
                mCameraViewTopLeftCornerID = Shader.PropertyToID("_CameraViewTopLeftCorner"),
                mCameraViewXExtentID = Shader.PropertyToID("_CameraViewXExtent"),
                mCameraViewYExtentID = Shader.PropertyToID("_CameraViewYExtent"),
                mMetaBallParams1ID = Shader.PropertyToID("_MetaBallParams1"),
                mMetaBallParams2ID = Shader.PropertyToID("_MetaBallParams2"),
                mBlendWidthID = Shader.PropertyToID("_BlendWidth"),
                mMaxStepID = Shader.PropertyToID("_MaxStep"),
                mClipSDFValueID = Shader.PropertyToID("_ClipSDFValue"),
                mMetaBallCountID = Shader.PropertyToID("_MetaBallCount"),
                mMainTexID = Shader.PropertyToID("_MainTex"),
                mMetaBallsID = Shader.PropertyToID("_MetaBalls");

        // This method is called before executing the render pass.
        // It can be used to configure render targets and their clear state. Also to create temporary render target textures.
        // When empty this render pass will render to the active camera render target.
        // You should never call CommandBuffer.SetRenderTarget. Instead call <c>ConfigureTarget</c> and <c>ConfigureClear</c>.
        // The render pipeline will ensure target setup and clearing happens in a performant manner.

        internal CustomRenderPass(ref MetaBallSettings featureSettings)
        {
            mSettings = featureSettings;

        }

        //private bool UpdateMetaBallBuffer(Vector4[] metaBalls)
        //{
        //    if (buffer != null &&
        //        lastMetaBallCount == metaBalls.Length) return false;

        //    // 释放旧Buffer
        //    buffer?.Dispose();

        //    // 创建新Buffer（长度+1防止空数组）
        //    int bufferSize = Mathf.Max(1, metaBalls.Length);
        //    buffer = new ComputeBuffer(bufferSize, sizeof(float) * 4);
        //    lastMetaBallCount = metaBalls.Length;
        //    return true;
        //}

        internal bool Setup(ref MetaBallSettings featureSettings, ref Material material)
        {
            mMaterial = material;
            //mSettings = featureSettings;

            // 创建 ComputeBuffer
            //ComputeBuffer buffer = new ComputeBuffer(featureSettings.metaBalls.Length, sizeof(Vector4), ComputeBufferType.Structured);
            //buffer.SetData(featureSettings.metaBalls);

            //ConfigureInput(ScriptableRenderPassInput.Normal);
            ConfigureInput(ScriptableRenderPassInput.Color);


            return mMaterial == null;
        }
        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            var renderer = renderingData.cameraData.renderer;
            // 发送参数
            Matrix4x4 view = renderingData.cameraData.GetViewMatrix();
            Matrix4x4 proj = renderingData.cameraData.GetProjectionMatrix();
            //view.SetColumn(3, new Vector4(0.0f, 0.0f, 0.0f, 1.0f));
            Matrix4x4 vp = proj * view;

            // 计算viewProj逆矩阵，即从裁剪空间变换到世界空间
            Matrix4x4 vpInv = vp.inverse;

            // 计算世界空间下，近平面四个角的坐标
            var near = renderingData.cameraData.camera.nearClipPlane;
            Vector4 topLeftCorner = vpInv.MultiplyPoint(new Vector4(-1.0f, 1.0f, -1.0f, 1.0f));
            Vector4 topRightCorner = vpInv.MultiplyPoint(new Vector4(1.0f, 1.0f, -1.0f, 1.0f));
            Vector4 bottomLeftCorner = vpInv.MultiplyPoint(new Vector4(-1.0f, -1.0f, -1.0f, 1.0f));

            // 计算相机近平面上方向向量
            Vector4 cameraXExtent = topRightCorner - topLeftCorner;
            Vector4 cameraYExtent = bottomLeftCorner - topLeftCorner;

            near = renderingData.cameraData.camera.nearClipPlane;

            // 发送ReconstructViewPos参数
            mMaterial.SetVector(mCameraViewTopLeftCornerID, topLeftCorner);
            mMaterial.SetVector(mCameraViewXExtentID, cameraXExtent);
            mMaterial.SetVector(mCameraViewYExtentID, cameraYExtent);
            mMaterial.SetVector(mProjectionParams2ID, new Vector4(1.0f / near, renderingData.cameraData.worldSpaceCameraPos.x, renderingData.cameraData.worldSpaceCameraPos.y, renderingData.cameraData.worldSpaceCameraPos.z));

            mMaterial.SetVector(mMetaBallParams1ID, new Vector4(0, 1, 0, 1));
            mMaterial.SetVector(mMetaBallParams2ID, new Vector4(0, 3, 0, 1));
            //mMaterial.SetFloat(mBlendWidthID, 0.5f);
            mMaterial.SetFloat(mBlendWidthID, mSettings.blendWidth);
            //mMaterial.SetFloat(mMaxStepID, 100);
            mMaterial.SetFloat(mMaxStepID, mSettings.m_RaySettings.maxStepCount);
            //mMaterial.SetFloat(mClipSDFValueID, 0.01f);
            mMaterial.SetFloat(mClipSDFValueID, mSettings.sdfClipValue);
            mMaterial.SetFloat(mMetaBallCountID, mSettings.metaBalls.Length);

            if(mSettings.metaBallTex != null)
                mMaterial.SetTexture(mMainTexID, mSettings.metaBallTex);

            if(mSettings.metaBalls.Length > 0 && mSettings.metaBalls.Length<11)
                mMaterial.SetVectorArray(mMetaBallsID,mSettings.metaBalls);


            // 传输数组数据
            //使用ComputeBuffer传递
            //ComputeBuffer buffer = new ComputeBuffer(32, sizeof(float) * 4);
            // 修改点3：按需更新Buffer
            //bool needUpdate = UpdateMetaBallBuffer(mSettings.metaBalls);
            //if (mSettings.metaBalls.Length > 0 && needUpdate)
            //{
            //    Debug.Log("wdf");
            //    //buffer.SetData(mSettings.metaBalls);
            //}
            //cmd.SetGlobalBuffer("_CustomDataBuffer", buffer);
            //mMaterial.SetVectorArray(, mSettings.metaBalls);
            //if (buffer != null)
            //{
            //    buffer.Release(); // 释放ComputeBuffer
            //    buffer.Dispose();
            //    buffer = null;    // 避免悬挂引用
            //}

            // 获取相机颜色目标
            var descriptor = renderingData.cameraData.cameraTargetDescriptor;
            descriptor.depthBufferBits = 0; // 不需要深度
            descriptor.msaaSamples = 1;
            RenderingUtils.ReAllocateIfNeeded(ref mDestinationTexture, descriptor, name: "_DestinationTexture");

            // 配置临时纹理
            //RenderingUtils.ReAllocateIfNeeded(ref mDestinationTexture, descriptor);

            // 配置目标和清除
            ConfigureTarget(renderer.cameraColorTargetHandle);
            //ConfigureClear(ClearFlag.All, Color.clear);
            ConfigureClear(ClearFlag.None, Color.white);
        }

        // Here you can implement the rendering logic.
        // Use <c>ScriptableRenderContext</c> to issue drawing commands or execute command buffers
        // https://docs.unity3d.com/ScriptReference/Rendering.ScriptableRenderContext.html
        // You don't have to call ScriptableRenderContext.submit, the render pipeline will call it at specific points in the pipeline.
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            if (mMaterial == null)
            {
                Debug.LogErrorFormat("{0}.Execute(): Missing material. ScreenSpaceAmbientOcclusion pass will not execute. Check for missing reference in the renderer resources.", GetType().Name);
                return;
            }

            var cmd = CommandBufferPool.Get();
            context.ExecuteCommandBuffer(cmd);
            cmd.Clear();

            mSourceTexture = renderingData.cameraData.renderer.cameraColorTargetHandle;
            //mDestinationTexture = renderingData.cameraData.renderer.cameraColorTargetHandle;

            using (new ProfilingScope(cmd, mProfilingSampler))
            {

                // 执行Blit操作
                Blitter.BlitCameraTexture(cmd, mSourceTexture, mDestinationTexture, mMaterial,0);
                //Blitter.BlitCameraTexture(cmd, mSourceTexture, mSourceTexture, mMaterial, 0);
                //// 将结果复制回相机目标
                Blitter.BlitCameraTexture(cmd, mDestinationTexture, mSourceTexture);

            }

            context.ExecuteCommandBuffer(cmd);
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
            mSourceTexture = null;
            //buffer?.Dispose();
        }

        public void Dispose()
        {
            mDestinationTexture?.Release();
            mSourceTexture = null;
            //mDestinationTexture = null;
            if (buffer != null)
            {
                buffer.Release(); // 释放ComputeBuffer
                buffer?.Dispose();
                buffer = null;    // 避免悬挂引用
            }
            lastMetaBallCount = -1;
        }
    }

    CustomRenderPass m_ScriptablePass;

    private Shader mShader;
    private Material mMaterial;
    private const string mShaderName = "Unlit/MetaBall";

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new CustomRenderPass(ref m_Settings);

        // Configures where the render pass should be injected.
        m_ScriptablePass.renderPassEvent = m_Settings.m_RenderPassEvent;
    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if(!ShouldRender(renderingData)||m_ScriptablePass.Setup(ref m_Settings,ref mMaterial))
            return;
        //Debug.Log(m_Settings.sdfClipValue);
        renderer.EnqueuePass(m_ScriptablePass);
    }

    protected override void Dispose(bool disposing)
    {
        // 确保材质释放
        CoreUtils.Destroy(mMaterial);

        m_ScriptablePass?.Dispose();
        m_ScriptablePass = null;
    }

    private bool GetMaterials()
    {
        if (mShader == null)
            mShader = Shader.Find(mShaderName);
        if (mMaterial == null && mShader != null)
            mMaterial = CoreUtils.CreateEngineMaterial(mShader);
        return mMaterial != null;
    }

    bool ShouldRender(in RenderingData data)
    {
        if (!GetMaterials())
        {
            Debug.LogErrorFormat("{0}.AddRenderPasses(): Missing material. {1} render pass will not be added.", GetType().Name, name);
            return false;
        }
        if(data.cameraData.cameraType != CameraType.Game)
        {
            Debug.LogWarningFormat("{0}.AddRenderPasses(): cameraType isnt Game. {1} render pass will not be added.", GetType().Name, name);
            return false;
        }
        if (m_ScriptablePass == null)
        {
            Debug.LogError($"RenderPass = null!");
            return false;
        }
        return true;
    }

}


