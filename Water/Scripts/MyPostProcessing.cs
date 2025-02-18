using System.Collections;
using System.Collections.Generic;
using Unity.Mathematics;
using UnityEngine;

//[ExecuteInEditMode]
public class MyPostProcessing : MonoBehaviour
{
    public Shader postProcessingShader;
    public Material postProcessingMaterial;

    public Material material
    {
        get
        {
            postProcessingMaterial = CheckShaderAndCreateMaterial(postProcessingShader, postProcessingMaterial);
            return postProcessingMaterial;
        }
    }
    protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
    {
        if (shader == null)
        {
            return null;
        }

        if (shader.isSupported && material && material.shader == shader)
            return material;

        if (!shader.isSupported)
        {
            return null;
        }
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            if (material)
                return material;
            else
                return null;
        }
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Color wow = new Color(0,0,0,0);
        material.SetColor("_Color", wow);
        material.SetTexture("_MainTex", src);
        if (material != null)
        {
            // 将材质的_MainTex属性设置为摄像机的渲染结果
            material.SetTexture("_MainTex", src);
            // 渲染后处理效果
            Graphics.Blit(src, dest, material);
        }
        else
        {
            material.SetTexture("_MainTex", src);
            // 如果材质未创建成功，则直接复制源到目标
            Graphics.Blit(src, dest);
        }
    }

    //void OnDestroy()
    //{
    //    // 销毁材质实例
    //    if (postProcessMaterial != null)
    //    {
    //        Destroy(postProcessMaterial);
    //    }
    //}
}
