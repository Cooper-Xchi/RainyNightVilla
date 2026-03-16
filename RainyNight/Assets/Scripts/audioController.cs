using System.Collections;
using UnityEngine;

[RequireComponent(typeof(AudioSource))]
public class audioController : MonoBehaviour
{
    [Header("渐入时长")]
    [SerializeField] private float fadeDuration = 2f;

    [Header("目标音量")]
    [Range(0f, 1f)]
    [SerializeField] private float targetVolume = 1f;

    [Header("开始时自动播放并渐入")]
    [SerializeField] private bool playOnStart = true;

    private AudioSource audioSource;
    private Coroutine fadeCoroutine;

    private void Awake()
    {
        audioSource = GetComponent<AudioSource>();
    }

    private void Start()
    {
        if (playOnStart)
        {
            PlayWithFadeIn();
        }
    }

    public void PlayWithFadeIn()
    {
        if (fadeCoroutine != null)
        {
            StopCoroutine(fadeCoroutine);
        }

        fadeCoroutine = StartCoroutine(FadeInCoroutine());
    }

    private IEnumerator FadeInCoroutine()
    {
        audioSource.volume = 0f;

        if (!audioSource.isPlaying)
        {
            audioSource.Play();
        }

        float timer = 0f;

        while (timer < fadeDuration)
        {
            timer += Time.deltaTime;
            audioSource.volume = Mathf.Lerp(0f, targetVolume, timer / fadeDuration);
            yield return null;
        }

        audioSource.volume = targetVolume;
        fadeCoroutine = null;
    }
}