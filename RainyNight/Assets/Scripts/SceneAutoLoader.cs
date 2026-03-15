using UnityEngine;
using UnityEngine.SceneManagement;

public class SceneAutoLoader : MonoBehaviour
{
    [Header("要跳转到的场景名")]
    [SerializeField] private string nextSceneName = "Scene2";

    [Header("等待时间（通常填动画时长）")]
    [SerializeField] private float delay = 3f;

    [Header("是否在开始时自动执行")]
    [SerializeField] private bool playOnStart = true;

    private bool isLoading = false;

    private void Start()
    {
        if (playOnStart)
        {
            Invoke(nameof(LoadNextScene), delay);
        }
    }

    public void LoadNextScene()
    {
        if (isLoading) return;
        isLoading = true;

        SceneManager.LoadScene(nextSceneName);
    }
}