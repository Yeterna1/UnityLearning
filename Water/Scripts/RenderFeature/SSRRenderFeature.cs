using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using static Unity.Burst.Intrinsics.X86.Avx;


namespace SSRRenderFeature
{
    // 这个脚本的格式是跟着教程写的具有一定的参考性
    [DisallowMultipleRendererFeature("SSRRenderFeature")]
    public class SSRRenderFeature : ScriptableRendererFeature
    {
        internal enum BlendMode
        {
            Addtive,
            Balance,
            CBuffer
        }

        [Serializable]
        internal class SSRRenderFeatureSettings
        {
            // 填当前feature的参数
            [SerializeField][Range(0.0f, 1.0f)] internal float Intensity = 0.8f;
            [SerializeField] internal float MaxDistance = 10.0f;
            [SerializeField] internal int Stride = 30;
            [SerializeField] internal int StepCount = 12;
            [SerializeField] internal float Thickness = 0.5f;
            [SerializeField] internal int BinaryCount = 6;
            [SerializeField] internal bool jitterDither = true;
            [SerializeField] internal BlendMode blendMode = BlendMode.Addtive;
            [SerializeField] internal float BlurRadius = 1.0f;
            [SerializeField] public float SSRIntensity = 0.1f;
            [SerializeField] public RenderPassEvent evt;
        }

        [Serializable]
        internal class HiZSettings
        {
            [SerializeField] public int MipCount;
        }

        class CustomRenderPass : ScriptableRenderPass
        {
            // scriptable Pass Properties
            private SSRRenderFeatureSettings mSettings;

            private Material mMaterial;

            private ProfilingSampler mProfilingSampler = new ProfilingSampler("SSRRenderFeature");
            private RenderTextureDescriptor mSSRDescriptor;

            private RTHandle mSourceTexture;
            private RTHandle mDestinationTexture;

            // shader中需要用到的传入值
            private static readonly int mProjectionParams2ID = Shader.PropertyToID("_ProjectionParams2"),
                    mCameraViewTopLeftCornerID = Shader.PropertyToID("_CameraViewTopLeftCorner"),
                    mCameraViewXExtentID = Shader.PropertyToID("_CameraViewXExtent"),
                    mCameraViewYExtentID = Shader.PropertyToID("_CameraViewYExtent"),
                    mSourceSizeID = Shader.PropertyToID("_SourceSize"),
                    mSSRParams0ID = Shader.PropertyToID("_SSRParams0"),
                    mSSRParams1ID = Shader.PropertyToID("_SSRParams1"),
                    mBlurRadiusID = Shader.PropertyToID("_SSRBlurRadius"),
                    mSSRIntensity = Shader.PropertyToID("_SSRIntensity"),
                    mSSRTexture = Shader.PropertyToID("_SSRTexture");

            // 临时RT用于制作模糊处理
            private RTHandle mSSRTexture0, mSSRTexture1;
            // 给RT设置name使得在Debug时更好的查找
            private const string mSSRTexture0Name = "_SSRTexture0",
                    mSSRTexture1Name = "_SSRTexture1";

            internal CustomRenderPass()
            {
                //mSettings = new SSRRenderFeatureSettings();
            }


            internal bool Setup(ref SSRRenderFeatureSettings featureSettings, ref Material material)
            {
                mMaterial = material;
                mSettings = featureSettings;

                ConfigureInput(ScriptableRenderPassInput.Normal);
                ConfigureInput(ScriptableRenderPassInput.Color);

                return mMaterial != null;
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

                mMaterial.SetVector(mSourceSizeID, new Vector4(mSSRDescriptor.width, mSSRDescriptor.height, 1.0f / mSSRDescriptor.width, 1.0f / mSSRDescriptor.height));

                // 发送SSR参数
                mMaterial.SetVector(mSSRParams0ID, new Vector4(mSettings.MaxDistance, mSettings.Stride, mSettings.StepCount, mSettings.Thickness));
                mMaterial.SetVector(mSSRParams1ID, new Vector4(mSettings.BinaryCount, mSettings.Intensity, 0.0f, 0.0f));
                mMaterial.SetFloat(mSSRIntensity, mSettings.SSRIntensity);

                // 设置全局keyword
                //if (mSettings.jitterDither)
                //{
                //    mMaterial.EnableKeyword(mJitterKeyword);
                //}
                //else
                //{
                //    mMaterial.DisableKeyword(mJitterKeyword);
                //}

                // 分配RTHandle
                mSSRDescriptor = renderingData.cameraData.cameraTargetDescriptor;
                mSSRDescriptor.msaaSamples = 1;
                mSSRDescriptor.depthBufferBits = 0;
                RenderingUtils.ReAllocateIfNeeded(ref mSSRTexture0, mSSRDescriptor, name: mSSRTexture0Name);
                RenderingUtils.ReAllocateIfNeeded(ref mSSRTexture1, mSSRDescriptor, name: mSSRTexture1Name);

                // 配置目标和清除
                ConfigureTarget(renderer.cameraColorTargetHandle);
                //ConfigureClear(ClearFlag.All, Color.clear);
                ConfigureClear(ClearFlag.None, Color.white);
            }

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
                mDestinationTexture = renderingData.cameraData.renderer.cameraColorTargetHandle;

                using (new ProfilingScope(cmd, mProfilingSampler))
                {
                    // SSR
                    Blitter.BlitCameraTexture(cmd, mSourceTexture, mSSRTexture0, mMaterial, 0);
                    //Blitter.BlitCameraTexture(cmd, mSourceTexture, mDestinationTexture, mMaterial, 0);

                    // Horizontal Blur
                    //cmd.SetGlobalVector(mBlurRadiusID, new Vector4(mSettings.BlurRadius, 0.0f, 0.0f, 0.0f));
                    cmd.SetGlobalFloat(mBlurRadiusID, mSettings.BlurRadius);
                    Blitter.BlitCameraTexture(cmd, mSSRTexture0, mSSRTexture1, mMaterial, 3);

                    // Vertical Blur
                    //cmd.SetGlobalVector(mBlurRadiusID, new Vector4(0.0f, mSettings.BlurRadius, 0.0f, 0.0f));
                    Blitter.BlitCameraTexture(cmd, mSSRTexture1, mSSRTexture0, mMaterial, 4);

                    if(mSettings.blendMode == BlendMode.Addtive)
                    // Additive Pass
                    //Blitter.BlitCameraTexture(cmd, mSSRTexture0, mDestinationTexture, mMaterial, mSettings.blendMode == BlendMode.Addtive ? (int)ShaderPass.Addtive : (int)ShaderPass.Balance);
                        Blitter.BlitCameraTexture(cmd, mSSRTexture0, mDestinationTexture, mMaterial, 5);
                    else if(mSettings.blendMode == BlendMode.Balance)
                        Blitter.BlitCameraTexture(cmd, mSSRTexture0, mDestinationTexture, mMaterial, 5);
                    else if(mSettings.blendMode == BlendMode.CBuffer)
                        Shader.SetGlobalTexture(mSSRTexture, mSSRTexture0);

                }

                context.ExecuteCommandBuffer(cmd);
                CommandBufferPool.Release(cmd);
            }

            // Cleanup any allocated resources that were created during the execution of this render pass.
            public override void OnCameraCleanup(CommandBuffer cmd)
            {
                mSourceTexture = null;
                mDestinationTexture = null;
            }

            public void Dispose()
            {
                // 释放RTHandle
                mSSRTexture0?.Release();
                mSSRTexture1?.Release();
            }
        }

        class HierarchicalZBufferPass : ScriptableRenderPass,IDisposable
        {

            private HiZSettings mSettings;

            private ProfilingSampler mProfilingSampler = new ProfilingSampler("HiZBufferRenderFeature");
            private string mHiZBufferTextureName = "HiZBufferTexture";

            public Material mMaterial;


            RenderTextureDescriptor mHiZBufferDescriptor;
            RenderTextureDescriptor[] mHiZBufferDescriptors;
            RTHandle mHiZBufferTexture;
            RTHandle[] mHiZBufferTextures;

            //RTHandle mCameraColorTexture;
            RTHandle mCameraDepthTexture;
            RTHandle mDestinationTexture;

            // shader中需要用到的传入值
            private static readonly int mHiZBufferFromMiplevelID = Shader.PropertyToID("_HiZBufferFromMiplevel"),
                    mHiZBufferToMiplevelID = Shader.PropertyToID("_HiZBufferToMiplevel"),
                    mMaxHiZBufferTextureipLevelID = Shader.PropertyToID("_MaxHiZBufferTextureipLevel"),
                    mHiZBufferTextureID = Shader.PropertyToID("_HiZBufferTexture"),
                    mSourceSizeID = Shader.PropertyToID("_SourceSize");

            internal HierarchicalZBufferPass()
            {
                mSettings = new HiZSettings();
            }


            internal bool Setup(ref HiZSettings featureSettings, ref Material material)
            {
                mMaterial = material;
                mSettings = featureSettings;

                mSettings.MipCount = 4;

                mHiZBufferDescriptors = new RenderTextureDescriptor[mSettings.MipCount];
                mHiZBufferTextures = new RTHandle[mSettings.MipCount];

                ConfigureInput(ScriptableRenderPassInput.Normal);
                ConfigureInput(ScriptableRenderPassInput.Color);

                return mMaterial != null;
            }

            public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
            {
                var renderer = renderingData.cameraData.renderer;

                // 分配RTHandle
                var desc = renderingData.cameraData.cameraTargetDescriptor;
                // 把高和宽变换为2的整次幂 然后除以2
                var width = Math.Max((int)Math.Ceiling(Mathf.Log(desc.width, 2) - 1.0f), 1);
                var height = Math.Max((int)Math.Ceiling(Mathf.Log(desc.height, 2) - 1.0f), 1);
                width = 1 << width;
                height = 1 << height;

                mHiZBufferDescriptor = new RenderTextureDescriptor(width, height, RenderTextureFormat.RFloat, 0, mSettings.MipCount);
                mHiZBufferDescriptor.msaaSamples = 1;
                mHiZBufferDescriptor.useMipMap = true;
                mHiZBufferDescriptor.sRGB = false;// linear
                RenderingUtils.ReAllocateIfNeeded(ref mHiZBufferTexture, mHiZBufferDescriptor, FilterMode.Bilinear, TextureWrapMode.Clamp, name: mHiZBufferTextureName);

                for (int i = 0; i < mSettings.MipCount; i++)
                {
                    mHiZBufferDescriptors[i] = new RenderTextureDescriptor(width, height, RenderTextureFormat.RFloat, 0, 1);
                    mHiZBufferDescriptors[i].msaaSamples = 1;
                    mHiZBufferDescriptors[i].useMipMap = false;
                    mHiZBufferDescriptors[i].sRGB = false;// linear
                    RenderingUtils.ReAllocateIfNeeded(ref mHiZBufferTextures[i], mHiZBufferDescriptors[i], FilterMode.Bilinear, TextureWrapMode.Clamp, name: mHiZBufferTextureName + i);
                    // generate mipmap
                    width = Math.Max(width / 2, 1);
                    height = Math.Max(height / 2, 1);
                }

                // 设置Material属性

                // 配置目标和清除
                ConfigureTarget(renderer.cameraColorTargetHandle);
                ConfigureClear(ClearFlag.None, Color.white);
            }

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

                //mCameraColorTexture = renderingData.cameraData.renderer.cameraColorTargetHandle;
                mCameraDepthTexture = renderingData.cameraData.renderer.cameraDepthTargetHandle;
                mDestinationTexture = renderingData.cameraData.renderer.cameraColorTargetHandle;

                using (new ProfilingScope(cmd, mProfilingSampler))
                {
                    // mip 0
                    Blitter.BlitCameraTexture(cmd, mCameraDepthTexture, mHiZBufferTextures[0], mMaterial, 2);
                    //cmd.CopyTexture(mHiZBufferTextures[0], 0, 0, mHiZBufferTexture, 0, 0);

                    //mip 1~max
                    for (int i = 1; i < 2; i++)
                    {
                        cmd.SetGlobalFloat(mHiZBufferFromMiplevelID, i - 1);
                        cmd.SetGlobalFloat(mHiZBufferToMiplevelID, i);
                        cmd.SetGlobalVector(mSourceSizeID, new Vector4(mHiZBufferDescriptors[i - 1].width, mHiZBufferDescriptors[i - 1].height, 1.0f / mHiZBufferDescriptors[i - 1].width, 1.0f / mHiZBufferDescriptors[i - 1].height));
                        Blitter.BlitCameraTexture(cmd, mHiZBufferTextures[i - 1], mHiZBufferTextures[i], mMaterial, 1);

                        //cmd.CopyTexture(mHiZBufferTextures[i], 0, 0, mHiZBufferTexture, 0, i);
                    }

                    // set global hiz texture
                    cmd.SetGlobalFloat(mMaxHiZBufferTextureipLevelID, mSettings.MipCount - 1);
                    cmd.SetGlobalTexture(mHiZBufferTextureID, mHiZBufferTexture);
                }
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
                CommandBufferPool.Release(cmd);
            }

            public override void OnCameraCleanup(CommandBuffer cmd)
            {
                mDestinationTexture = null;
                //mCameraColorTexture = null;
                mCameraDepthTexture = null;
            }

            public void Dispose()
            {
                mHiZBufferTexture?.Release();
                mHiZBufferTexture = null;
                for (int i = 0; i < mSettings.MipCount; i++)
                {
                    mHiZBufferTextures[i]?.Release();
                    mHiZBufferTextures[i] = null;
                }
            }

        }

        CustomRenderPass m_ScriptablePass;
        HierarchicalZBufferPass m_HiZBufferPass;

        // 属性的声明
        [SerializeField] private SSRRenderFeatureSettings mSettings = new SSRRenderFeatureSettings();
        [SerializeField] private HiZSettings mHiZSettings = new HiZSettings();


        private Shader mShader;
        private const string mShaderName = "M/SSRRenderFeature";

        private Shader mHiZBufferShader;
        private Shader mHiZBufferShaderName;

        private Material mMaterial;
        private Material mHiZBufferMaterial;

        /// <inheritdoc/>
        public override void Create()
        {
            if (m_ScriptablePass == null)
            {
                m_ScriptablePass = new CustomRenderPass();
                // Configures where the render pass should be injected.
                m_ScriptablePass.renderPassEvent = mSettings.evt;

            }
            //if (m_HiZBufferPass == null)
            //{
            //    m_HiZBufferPass = new HierarchicalZBufferPass();
            //    // Configures where the render pass should be injected.
            //    m_HiZBufferPass.renderPassEvent = RenderPassEvent.AfterRenderingTransparents;
            //}

        }

        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            if (!ShouldRender(in renderingData)) return;
            bool shouldAdd = false;
            if (renderingData.cameraData.postProcessEnabled)
            {
                if (!GetMaterials())
                {
                    Debug.LogErrorFormat("{0}.AddRenderPasses(): Missing material. {1} render pass will not be added.", GetType().Name, name);
                    return;
                }

                shouldAdd = m_ScriptablePass.Setup(ref mSettings, ref mMaterial);//&& m_HiZBufferPass.Setup(ref mHiZSettings, ref mMaterial);
                if (shouldAdd)
                {
                    
                    //renderer.EnqueuePass(m_HiZBufferPass);
                    renderer.EnqueuePass(m_ScriptablePass);
                }
            }
        }

        private bool GetMaterials()
        {
            if (mShader == null)
                mShader = Shader.Find(mShaderName);
            if (mMaterial == null && mShader != null)
                mMaterial = CoreUtils.CreateEngineMaterial(mShader);
            return mMaterial != null;
        }

        protected override void Dispose(bool disposing)
        {
            CoreUtils.Destroy(mMaterial);

            // 启用SSR RF
            m_ScriptablePass?.Dispose();
            m_ScriptablePass = null;


            // 启用HiZ RF
            //m_HiZBufferPass?.Dispose();
            //m_HiZBufferPass = null;
        }

        bool ShouldRender(in RenderingData data)
        {
            if (!data.cameraData.postProcessEnabled || data.cameraData.cameraType != CameraType.Game)
            {
                if (!data.cameraData.postProcessEnabled)
                    Debug.LogErrorFormat("{0}.AddRenderPasses(): postProcessEnable. {1} render pass will not be added.", GetType().Name, name);
                if (data.cameraData.cameraType != CameraType.Game)
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
}


