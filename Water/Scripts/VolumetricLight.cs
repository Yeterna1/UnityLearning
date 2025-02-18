using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

public class VolumetricLight : ScriptableRendererFeature
{
    [System.Serializable]
    public class Settings
    {
        public string passTag = "FeatureTemplate";
        public RenderPassEvent passEvent = RenderPassEvent.AfterRenderingSkybox;
    }

    public Settings settings = new Settings();

    PassTemplate m_ScriptablePass;

    /// <inheritdoc/>
    public override void Create()
    {
        m_ScriptablePass = new PassTemplate(settings.passTag, settings.passEvent);

    }

    // Here you can inject one or multiple render passes in the renderer.
    // This method is called when setting up the renderer once per-camera.
    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        renderer.EnqueuePass(m_ScriptablePass);
    }

    public class PassTemplate : ScriptableRenderPass
    {
        private RenderTargetHandle m_RenderTargetHandle;
        private ProfilingSampler m_ProfilingSampler;

        private string m_ProfileTag;

        public PassTemplate(string profileTag, RenderPassEvent Event)
        {
            this.renderPassEvent = Event;
            m_ProfileTag = profileTag;
        }

        public void Setup()
        {

        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            // RenderTextureDescriptor cameraDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            // m_RenderTargetHandle.Init("_Handle");
            // cmd.GetTemporaryRT(m_RenderTargetHandle.id, cameraDescriptor);
            // ConfigureTarget(m_RenderTargetHandle.Identifier());
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            // RenderTargetIdentifier colorTarget = renderingData.cameraData.renderer.cameraColorTarget;
            m_ProfilingSampler = new ProfilingSampler(m_ProfileTag);
            CommandBuffer cmd = CommandBufferPool.Get();
            //it is very important that if something fails our code still calls CommandBufferPool.Release(cmd) or we will have a HUGE memory leak
            try
            {
                using (new ProfilingScope(cmd, m_ProfilingSampler))
                {
                    // ±ê¼Ç
                    //cmd.Blit(colorTarget, m_TempRT0.Identifier());
                    //cmd.Blit(m_TempRT0.Identifier(), colorTarget, material, 0);
                }
                context.ExecuteCommandBuffer(cmd);
            }
            catch
            {
                Debug.LogError("Error");
            }
            cmd.Clear();
            CommandBufferPool.Release(cmd);
        }

        // Cleanup any allocated resources that were created during the execution of this render pass.
        public override void OnCameraCleanup(CommandBuffer cmd)
        {
        }
    }
}
