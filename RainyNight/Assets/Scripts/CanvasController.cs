using System.Collections;
using UnityEngine;
using UnityEngine.UI;

public class LoginUITransition : MonoBehaviour
{
    [Header("先淡出的物体")]
    [SerializeField] private Material fadeOutMaterialA;
    public GameObject objA;

    [Header("后淡入的物体们")]
    [SerializeField] private Material fadeInMaterials;
    public GameObject[] objB;

    [Header("时间")]
    [SerializeField] private float fadeOutDuration = 2f;
    [SerializeField] private float fadeInDuration = 2f;

    public void Start(){
        objA.active = true;
        fadeOutMaterialA.SetVector("para",new Vector4(1,1,1,1));
        foreach(var obj in objB){
            obj.active = false;
            fadeInMaterials.SetVector("para",new Vector4(1,1,0,1));
        }
        
        
    }

    public void OnClickToStart()
    {
        StartCoroutine(CoLoginTransition());
        StartCoroutine(CoLoginBTransition());
    }

    private IEnumerator CoLoginTransition()
    {
        // 1. A物体 alpha 1 -> 0
        objA.active = true;
        foreach(var obj in objB){
            obj.active = false;
        }
        if (fadeOutMaterialA != null)
        {
            yield return StartCoroutine(FadeImageAlpha(fadeOutMaterialA, 1f, 0f, fadeOutDuration));
            objA.active = false;
            foreach(var obj in objB){
            obj.active = true;
        }
        }

    }

    private IEnumerator CoLoginBTransition()
    {
        
        
        // 2. 其余物体 alpha 0 -> 1
        if (fadeInMaterials != null)
        {

            yield return StartCoroutine(FadeImageAlpha(fadeInMaterials, 0f, 2f, fadeInDuration));

        }
    }

    private IEnumerator FadeImageAlpha(Material mat, float from, float to, float duration)
    {
        float timer = 0f;

        float val = 0;

        while (timer < duration)
        {
            timer += Time.deltaTime;
            float t = Mathf.Clamp01(timer / duration);

            val = Mathf.Lerp(from, to, t);
            mat.SetVector("para",new Vector4(1,1,val,1));

            yield return null;
        }

    }
}