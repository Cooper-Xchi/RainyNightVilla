using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightController : MonoBehaviour
{
    private Light _light;
    public float intensity;
    // Start is called before the first frame update
    void Start()
    {
        _light = GetComponent<Light>();
    }

    // Update is called once per frame
    void Update()
    {
        intensity = 20*Mathf.Sin(2f*Time.fixedTime+5f)+30f;
        _light.intensity = intensity;
    }
}
