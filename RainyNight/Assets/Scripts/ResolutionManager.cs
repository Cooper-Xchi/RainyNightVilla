using UnityEngine;

public class ResolutionManager : MonoBehaviour
{
    [Header("目标分辨率")]
    [SerializeField] private int targetWidth = 1536;
    [SerializeField] private int targetHeight = 1024;

    [Header("是否全屏")]
    [SerializeField] private bool fullScreen = false;

    private void Awake()
    {
        Screen.SetResolution(targetWidth, targetHeight, fullScreen);
    }
}