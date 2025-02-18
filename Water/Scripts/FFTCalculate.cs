using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FFTCalculate : MonoBehaviour
{
    [Range(3, 14)]
    public int FFTPow = 10;         //���ɺ��������С 2�Ĵ��ݣ��� Ϊ10ʱ�������СΪ1024*1024
    public int MeshSize = 250;		//���񳤿�����
    public float MeshLength = 10;	//���񳤶�
    public float A = 10;			//phillips�ײ�����Ӱ�첨�˸߶�
    public float Lambda = -1;       //��������ƫ�ƴ�С
    public float HeightScale = 1;   //�߶�Ӱ��
    public float BubblesScale = 1;  //��ĭǿ��
    public float BubblesThreshold = 1;//��ĭ��ֵ
    public float WindScale = 2;     //��ǿ
    public float TimeScale = 1;     //ʱ��Ӱ��
    public Vector4 WindAndSeed = new Vector4(0.1f, 0.2f, 0, 0);//������������ xyΪ��, zwΪ�����������
    public ComputeShader OceanCS;   //���㺣���cs
    public Material OceanMaterial;  //��Ⱦ����Ĳ���
    public Material DisplaceXMat;   //xƫ�Ʋ���
    public Material DisplaceYMat;   //yƫ�Ʋ���
    public Material DisplaceZMat;   //zƫ�Ʋ���
    public Material DisplaceMat;    //ƫ�Ʋ���
    public Material NormalMat;      //���߲���
    public Material BubblesMat;     //��ĭ����
    [Range(0, 12)]
    public int ControlM = 12;       //����m,����FFT�任�׶�
    public bool isControlH = true;  //�Ƿ���ƺ���FFT�������������FFT


    private int fftSize;			//fft�����С = pow(2,FFTPow)
    private float time = 0;             //ʱ��

    private int[] vertIndexs;		//��������������
    private Vector3[] positions;    //λ��
    private Vector2[] uvs; 			//uv����
    private Mesh mesh;
    private MeshFilter filetr;
    private MeshRenderer render;

    private int kernelComputeGaussianRandom;            //�����˹�����
    private int kernelCreateHeightSpectrum;             //�����߶�Ƶ��
    private int kernelCreateDisplaceSpectrum;           //����ƫ��Ƶ��
    private int kernelFFTHorizontal;                    //FFT����
    private int kernelFFTHorizontalEnd;                 //FFT�������׶�
    private int kernelFFTVertical;                      //FFT����
    private int kernelFFTVerticalEnd;                   //FFT����,���׶�
    private int kernelTextureGenerationDisplace;        //����ƫ������
    private int kernelTextureGenerationNormalBubbles;   //���ɷ��ߺ���ĭ����
    private RenderTexture GaussianRandomRT;             //��˹�����
    private RenderTexture HeightSpectrumRT;             //�߶�Ƶ��
    private RenderTexture DisplaceXSpectrumRT;          //Xƫ��Ƶ��
    private RenderTexture DisplaceZSpectrumRT;          //Zƫ��Ƶ��
    private RenderTexture DisplaceRT;                   //ƫ��Ƶ��
    private RenderTexture OutputRT;                     //��ʱ�����������
    private RenderTexture NormalRT;                     //��������
    private RenderTexture BubblesRT;                    //��ĭ����

    private void Awake()
    {
        //���������Ⱦ���
        filetr = gameObject.GetComponent<MeshFilter>();
        if (filetr == null)
        {
            filetr = gameObject.AddComponent<MeshFilter>();
        }
        render = gameObject.GetComponent<MeshRenderer>();
        if (render == null)
        {
            render = gameObject.AddComponent<MeshRenderer>();
        }
        mesh = new Mesh();
        filetr.mesh = mesh;
        render.material = OceanMaterial;
    }

    private void Start()
    {
        //��������
        CreateMesh();
        //��ʼ��ComputerShader�������
        InitializeCSvalue();
    }
    private void Update()
    {
        time += Time.deltaTime * TimeScale;
        //���㺣������
        ComputeOceanValue();
    }


    /// <summary>
    /// ��ʼ��Computer Shader�������
    /// </summary>
    private void InitializeCSvalue()
    {
        fftSize = (int)Mathf.Pow(2, FFTPow);

        //������Ⱦ����
        if (GaussianRandomRT != null && GaussianRandomRT.IsCreated())
        {
            GaussianRandomRT.Release();
            HeightSpectrumRT.Release();
            DisplaceXSpectrumRT.Release();
            DisplaceZSpectrumRT.Release();
            DisplaceRT.Release();
            OutputRT.Release();
            NormalRT.Release();
            BubblesRT.Release();
        }
        GaussianRandomRT = CreateRT(fftSize);
        HeightSpectrumRT = CreateRT(fftSize);
        DisplaceXSpectrumRT = CreateRT(fftSize);
        DisplaceZSpectrumRT = CreateRT(fftSize);
        DisplaceRT = CreateRT(fftSize);
        OutputRT = CreateRT(fftSize);
        NormalRT = CreateRT(fftSize);
        BubblesRT = CreateRT(fftSize);

        //��ȡ����kernelID
        kernelComputeGaussianRandom = OceanCS.FindKernel("ComputeGaussianRandom");
        kernelCreateHeightSpectrum = OceanCS.FindKernel("CreateHeightSpectrum");
        kernelCreateDisplaceSpectrum = OceanCS.FindKernel("CreateDisplaceSpectrum");
        kernelFFTHorizontal = OceanCS.FindKernel("FFTHorizontal");
        kernelFFTHorizontalEnd = OceanCS.FindKernel("FFTHorizontalEnd");
        kernelFFTVertical = OceanCS.FindKernel("FFTVertical");
        kernelFFTVerticalEnd = OceanCS.FindKernel("FFTVerticalEnd");
        kernelTextureGenerationDisplace = OceanCS.FindKernel("TextureGenerationDisplace");
        kernelTextureGenerationNormalBubbles = OceanCS.FindKernel("TextureGenerationNormalBubbles");

        //����ComputerShader����
        OceanCS.SetInt("N", fftSize);
        OceanCS.SetFloat("OceanLength", MeshLength);


        //���ɸ�˹�����
        OceanCS.SetTexture(kernelComputeGaussianRandom, "GaussianRandomRT", GaussianRandomRT);
        OceanCS.Dispatch(kernelComputeGaussianRandom, fftSize / 8, fftSize / 8, 1);

    }
    /// <summary>
    /// ���㺣������
    /// </summary>
    private void ComputeOceanValue()
    {
        OceanCS.SetFloat("A", A);
        WindAndSeed.z = Random.Range(1, 10f);
        WindAndSeed.w = Random.Range(1, 10f);

        Vector2 wind = new Vector2(WindAndSeed.x, WindAndSeed.y);
        wind.Normalize();
        wind *= WindScale;
        OceanCS.SetVector("WindAndSeed", new Vector4(wind.x, wind.y, WindAndSeed.z, WindAndSeed.w));
        OceanCS.SetFloat("Time", time);
        OceanCS.SetFloat("Lambda", Lambda);
        OceanCS.SetFloat("HeightScale", HeightScale);
        OceanCS.SetFloat("BubblesScale", BubblesScale);
        OceanCS.SetFloat("BubblesThreshold", BubblesThreshold);

        //���ɸ߶�Ƶ��
        OceanCS.SetTexture(kernelCreateHeightSpectrum, "GaussianRandomRT", GaussianRandomRT);
        OceanCS.SetTexture(kernelCreateHeightSpectrum, "HeightSpectrumRT", HeightSpectrumRT);
        OceanCS.Dispatch(kernelCreateHeightSpectrum, fftSize / 8, fftSize / 8, 1);

        //����ƫ��Ƶ��
        OceanCS.SetTexture(kernelCreateDisplaceSpectrum, "HeightSpectrumRT", HeightSpectrumRT);
        OceanCS.SetTexture(kernelCreateDisplaceSpectrum, "DisplaceXSpectrumRT", DisplaceXSpectrumRT);
        OceanCS.SetTexture(kernelCreateDisplaceSpectrum, "DisplaceZSpectrumRT", DisplaceZSpectrumRT);
        OceanCS.Dispatch(kernelCreateDisplaceSpectrum, fftSize / 8, fftSize / 8, 1);


        if (ControlM == 0)
        {
            SetMaterialTex();
            return;
        }

        //���к���FFT
        for (int m = 1; m <= FFTPow; m++)
        {
            int ns = (int)Mathf.Pow(2, m - 1);
            OceanCS.SetInt("Ns", ns);
            //���һ�ν������⴦��
            if (m != FFTPow)
            {
                ComputeFFT(kernelFFTHorizontal, ref HeightSpectrumRT);
                ComputeFFT(kernelFFTHorizontal, ref DisplaceXSpectrumRT);
                ComputeFFT(kernelFFTHorizontal, ref DisplaceZSpectrumRT);
            }
            else
            {
                ComputeFFT(kernelFFTHorizontalEnd, ref HeightSpectrumRT);
                ComputeFFT(kernelFFTHorizontalEnd, ref DisplaceXSpectrumRT);
                ComputeFFT(kernelFFTHorizontalEnd, ref DisplaceZSpectrumRT);
            }
            if (isControlH && ControlM == m)
            {
                SetMaterialTex();
                return;
            }
        }
        //��������FFT
        for (int m = 1; m <= FFTPow; m++)
        {
            int ns = (int)Mathf.Pow(2, m - 1);
            OceanCS.SetInt("Ns", ns);
            //���һ�ν������⴦��
            if (m != FFTPow)
            {
                ComputeFFT(kernelFFTVertical, ref HeightSpectrumRT);
                ComputeFFT(kernelFFTVertical, ref DisplaceXSpectrumRT);
                ComputeFFT(kernelFFTVertical, ref DisplaceZSpectrumRT);
            }
            else
            {
                ComputeFFT(kernelFFTVerticalEnd, ref HeightSpectrumRT);
                ComputeFFT(kernelFFTVerticalEnd, ref DisplaceXSpectrumRT);
                ComputeFFT(kernelFFTVerticalEnd, ref DisplaceZSpectrumRT);
            }
            if (!isControlH && ControlM == m)
            {
                SetMaterialTex();
                return;
            }
        }

        //��������ƫ��
        OceanCS.SetTexture(kernelTextureGenerationDisplace, "HeightSpectrumRT", HeightSpectrumRT);
        OceanCS.SetTexture(kernelTextureGenerationDisplace, "DisplaceXSpectrumRT", DisplaceXSpectrumRT);
        OceanCS.SetTexture(kernelTextureGenerationDisplace, "DisplaceZSpectrumRT", DisplaceZSpectrumRT);
        OceanCS.SetTexture(kernelTextureGenerationDisplace, "DisplaceRT", DisplaceRT);
        OceanCS.Dispatch(kernelTextureGenerationDisplace, fftSize / 8, fftSize / 8, 1);

        //���ɷ��ߺ���ĭ����
        OceanCS.SetTexture(kernelTextureGenerationNormalBubbles, "DisplaceRT", DisplaceRT);
        OceanCS.SetTexture(kernelTextureGenerationNormalBubbles, "NormalRT", NormalRT);
        OceanCS.SetTexture(kernelTextureGenerationNormalBubbles, "BubblesRT", BubblesRT);
        OceanCS.Dispatch(kernelTextureGenerationNormalBubbles, fftSize / 8, fftSize / 8, 1);

        SetMaterialTex();
    }

    /// <summary>
    /// ��������
    /// </summary>
    private void CreateMesh()
    {
        //fftSize = (int)Mathf.Pow(2, FFTPow);
        vertIndexs = new int[(MeshSize - 1) * (MeshSize - 1) * 6];
        positions = new Vector3[MeshSize * MeshSize];
        uvs = new Vector2[MeshSize * MeshSize];

        int inx = 0;
        for (int i = 0; i < MeshSize; i++)
        {
            for (int j = 0; j < MeshSize; j++)
            {
                int index = i * MeshSize + j;
                positions[index] = new Vector3((j - MeshSize / 2.0f) * MeshLength / MeshSize, 0, (i - MeshSize / 2.0f) * MeshLength / MeshSize);
                uvs[index] = new Vector2(j / (MeshSize - 1.0f), i / (MeshSize - 1.0f));

                if (i != MeshSize - 1 && j != MeshSize - 1)
                {
                    vertIndexs[inx++] = index;
                    vertIndexs[inx++] = index + MeshSize;
                    vertIndexs[inx++] = index + MeshSize + 1;

                    vertIndexs[inx++] = index;
                    vertIndexs[inx++] = index + MeshSize + 1;
                    vertIndexs[inx++] = index + 1;
                }
            }
        }
        mesh.vertices = positions;
        mesh.SetIndices(vertIndexs, MeshTopology.Triangles, 0);
        mesh.uv = uvs;
    }

    //������Ⱦ����
    private RenderTexture CreateRT(int size)
    {
        RenderTexture rt = new RenderTexture(size, size, 0, RenderTextureFormat.ARGBFloat);
        rt.enableRandomWrite = true;
        rt.Create();
        return rt;
    }
    //����fft
    private void ComputeFFT(int kernel, ref RenderTexture input)
    {
        OceanCS.SetTexture(kernel, "InputRT", input);
        OceanCS.SetTexture(kernel, "OutputRT", OutputRT);
        OceanCS.Dispatch(kernel, fftSize / 8, fftSize / 8, 1);

        //���������������
        RenderTexture rt = input;
        input = OutputRT;
        OutputRT = rt;
    }
    //���ò�������
    private void SetMaterialTex()
    {
        //���ú����������
        OceanMaterial.SetTexture("_Displace", DisplaceRT);
        OceanMaterial.SetTexture("_Normal", NormalRT);
        OceanMaterial.SetTexture("_Bubbles", BubblesRT);

        //������ʾ����
        DisplaceXMat.SetTexture("_MainTex", DisplaceXSpectrumRT);
        DisplaceYMat.SetTexture("_MainTex", HeightSpectrumRT);
        DisplaceZMat.SetTexture("_MainTex", DisplaceZSpectrumRT);
        DisplaceMat.SetTexture("_MainTex", DisplaceRT);
        NormalMat.SetTexture("_MainTex", NormalRT);
        BubblesMat.SetTexture("_MainTex", BubblesRT);
    }

}
