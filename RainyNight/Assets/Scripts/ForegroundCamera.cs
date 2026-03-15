using UnityEngine;

[ExecuteAlways]
public class CameraRTProcessor : MonoBehaviour
{
    [Header("输入 RT")]
    public RenderTexture inputRT;

    [Header("输出 RT")]
    public RenderTexture outputRT;

    [Header("用于处理的相机")]
    public Camera renderCamera;

    [Header("是否每帧执行")]
    public bool processEveryFrame = true;

    [Header("供 Shader 使用的全局纹理名")]
    public string globalTextureName = "_ForegroundTex";

    

    private void Reset()
    {
        renderCamera = GetComponent<Camera>();
    }

    private void OnEnable()
    {
        SetupRT(inputRT);
        SetupRT(outputRT);
    }

    private void Update()
    {
        if (!processEveryFrame)
            return;

        Process();
    }

    [ContextMenu("Process Once")]
    public void Process()
    {
        if (renderCamera == null)
        {
            Debug.LogError("renderCamera 为空。");
            return;
        }

        if (inputRT == null || outputRT == null)
        {
            Debug.LogError("inputRT 或 outputRT 为空。");
            return;
        }

        // 这里应该传输入 RT，不是输出 RT
        Shader.SetGlobalTexture(globalTextureName, inputRT);

        var previousTarget = renderCamera.targetTexture;
        var previousActive = RenderTexture.active;

        renderCamera.targetTexture = outputRT;

        RenderTexture.active = outputRT;
        GL.Clear(true, true, Color.clear);
        RenderTexture.active = previousActive;

        renderCamera.Render();

        renderCamera.targetTexture = previousTarget;
    }

    private void SetupRT(RenderTexture rt)
    {
        if (rt == null) return;

        rt.filterMode = FilterMode.Bilinear; // 如果你想绝对锐利可改 Point
        rt.wrapMode = TextureWrapMode.Clamp;
    }
}