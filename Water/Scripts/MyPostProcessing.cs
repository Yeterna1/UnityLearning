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
            // �����ʵ�_MainTex��������Ϊ���������Ⱦ���
            material.SetTexture("_MainTex", src);
            // ��Ⱦ����Ч��
            Graphics.Blit(src, dest, material);
        }
        else
        {
            material.SetTexture("_MainTex", src);
            // �������δ�����ɹ�����ֱ�Ӹ���Դ��Ŀ��
            Graphics.Blit(src, dest);
        }
    }

    //void OnDestroy()
    //{
    //    // ���ٲ���ʵ��
    //    if (postProcessMaterial != null)
    //    {
    //        Destroy(postProcessMaterial);
    //    }
    //}
}
