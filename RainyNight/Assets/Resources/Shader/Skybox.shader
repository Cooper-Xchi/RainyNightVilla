Shader "Custom/Skybox/RainyNightSky"
{
    Properties
    {
        [Header(Base Gradient)]
        _TopColor("Top Color", Color) = (0.03, 0.05, 0.10, 1)
        _MiddleColor("Middle Color", Color) = (0.08, 0.10, 0.16, 1)
        _BottomColor("Bottom Color", Color) = (0.16, 0.17, 0.20, 1)

        _HorizonHeight("Horizon Height", Range(-1, 1)) = -0.1
        _HorizonSoftness("Horizon Softness", Range(0.001, 1)) = 0.25

        [Header(Moon Light)]
        _MoonDirection("Moon Direction", Vector) = (0.3, 0.7, 0.6, 0)
        _MoonColor("Moon Color", Color) = (0.75, 0.8, 1.0, 1)
        _MoonIntensity("Moon Intensity", Range(0, 5)) = 1.2
        _MoonSize("Moon Size", Range(1, 256)) = 64

        [Header(Cloud)]
        _CloudTex("Cloud Noise", 2D) = "white" {}
        _CloudScale             ("_CloudScale",             Vector)             = (20000, 20000, 20000, 2000)
        _CloudColor             ("CloudColor",             Color)             = (0.03, 0.05, 0.10, 1)
        _CloudOpacity           ("_CloudOpacity",           Float)              = 0.01
        _CloudTiling("Cloud Tiling", Float) = 1.2
        _CloudSpeed("Cloud Speed", Vector) = (0.01, 0.0, 0.0, 0.0)
        _CloudIntensity("Cloud Intensity", Range(0, 2)) = 0.35
        _CloudSoftness("Cloud Softness", Range(0.01, 1)) = 0.25
        _CloudHeightFade("Cloud Height Fade", Range(0, 4)) = 1.5
        _CloudHeight("Cloud Height", Float) = 1.5
        _CloudThickness         ("_CloudThickness",         Float)              = 600
        _TopSurfaceScale        ("_TopSurfaceScale",        Float)              = 2.5
        _BottomSurfaceScale     ("_BottomSurfaceScale",     Float)              = 0.6
        _FarCloudColorAmount    ("_CloudColorAmount",       Range(0, 1))        = 0.1
        _NearCloudColorAmount   ("_NearCloudColorAmount",   Range(0, 1))        = 0.1


        _CloudEdgeScale         ("_CloudEdgeScale",         Range(0, 1))        = 0.1
        _CloudSoftness          ("_CloudSoftness",          Range(0, 1))        = 0.1
        _GradientTex            ("_GradientTex",            2D)                 = "white" {}
        // ��ƽ������ɫ
        [Header(Final)]
        _Exposure("Exposure", Range(0, 5)) = 1

        [Header(Moon)]
        _MoonDirection("Moon Direction", Vector) = (0.3, 0.7, 0.6, 0)
        _MoonColor("Moon Color", Color) = (0.85, 0.9, 1.0, 1)
        _MoonIntensity("Moon Intensity", Range(0, 10)) = 2
        _MoonSize("Moon Size", Range(16, 4096)) = 1200
        _MoonGlow("Moon Glow", Range(1, 256)) = 16
        _MoonGlowIntensity("Moon Glow Intensity", Range(0, 5)) = 0.35


        para("para",Vector) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "Queue"="Background"
            "RenderType"="Background"
            "RenderPipeline"="UniversalPipeline"
            "PreviewType"="Skybox"
        }

        Pass
        {
            Name "Skybox"

            Cull Off
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 ray   : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _TopColor;
                float4 _MiddleColor;
                float4 _BottomColor;

                float _HorizonHeight;
                float _HorizonSoftness;
                float _CloudHeight;
                float _CloudThickness;
                float _TopSurfaceScale;
                float _BottomSurfaceScale;
                float4 _CloudScale;
                float4 _CloudColor;
                float _CloudOpacity;
                float _CloudTiling;
                float4 _CloudSpeed;
                float _CloudIntensity;
                float _CloudSoftness;
                float _CloudHeightFade;
                float _NearCloudColorAmount;
                float _FarCloudColorAmount;
                float4 _MoonDirection;
                float4 _MoonColor;
                float _MoonIntensity;
                float _MoonSize;
                float _MoonGlow;
                float _MoonGlowIntensity;

                float _Exposure;
                float4 para;

                sampler2D _GradientTex;
                float _CloudEdgeScale;
            CBUFFER_END

            TEXTURE2D(_CloudTex);
            SAMPLER(sampler_CloudTex);

            float GetMoonDisk(float3 dir, float3 moonDir, float moonSize)
            {
                float d = saturate(dot(dir, moonDir));
                d = pow(saturate(para.y*(d-1.0)+1.0),moonSize/16);
                return d;//pow(d, moonSize);
            }

            float GetMoonGlow(float3 dir, float3 moonDir, float glowPower)
            {
                float d = saturate(dot(dir, moonDir));
                d = pow(saturate(para.y*(d-1.0)+1.0),glowPower/16);
                return d;
            }

            float4 raymarching(float3 ro, float3 rd,float4 color)
            {
                if (rd.y >=0 )
                {   
                    rd = rd / rd.y;

                    float4 c = 0;
                    const int maxStep = 64;
                    float3 position = ro + rd * (_CloudHeight - ro.y);
                    float3 t = rd * _CloudThickness / maxStep;
                    float stepOpacity = _CloudOpacity;
                    stepOpacity =  1 - (1 / (_CloudOpacity * length(t) + 1));

                    // �������ɫ���ں�
                    float farCloudColorAmount = 1 - (1 / (_FarCloudColorAmount * length(rd) + 1));
                    c = float4(_CloudColor.rgb * farCloudColorAmount, farCloudColorAmount);

                    for (int i = 0; i < maxStep; ++i)
                    {
                        position += t;

                        float2 uv0 = (position.xz + _CloudSpeed.xy * _Time.y) / _CloudScale.xy;
                        float cloud0 = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, uv0 ).r;

                        float2 uv1 = (position.xz + _CloudSpeed.zw * _Time.y) / _CloudScale.zw;
                        float2 uv2 = uv1;
                        uv2 += para.zw;

                        float cloud1 = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, uv1).r;
                        float cloud2 = SAMPLE_TEXTURE2D(_CloudTex, sampler_CloudTex, uv2).r;

                        // �����Ʋ�Ķ����͵ײ�
                        float cloudTopHeight = 1 - (cloud0 * _TopSurfaceScale + cloud1 * _CloudEdgeScale);
                        float cloudBottomHeight = (cloud0 * _BottomSurfaceScale + cloud2 * _CloudEdgeScale);

                        float f = (position.y - _CloudHeight) / _CloudThickness;

                        if (f > cloudBottomHeight && f < cloudTopHeight)
                        {
                            float distanceToSurface = min(cloudTopHeight - f, f - cloudBottomHeight);
                            float localOpacity = saturate(distanceToSurface / _CloudSoftness);

                            // ���ӽ���
                            float cloudTopHeightSmooth = 1 - cloud0 * _TopSurfaceScale;
                            float cloudDarkness = 1 - saturate(cloudTopHeightSmooth - f);
                            float4 gradientColor = tex2D(_GradientTex, float2(cloudDarkness, 0));

                            c += (1 - c.a) * stepOpacity * localOpacity * gradientColor;

                            if (c.a > 0.99)
                            {
                                //c.rgb *= 1 / c.a;
                                //c.a = 1;
                                break;
                            }
                        }
                    }

                    // �����Ʋ����յ��ں�
                    float nearCloudColorAmount = 1 - (1 / (_NearCloudColorAmount * length(rd) + 1));
                    float4 totalSkyColor = lerp(color, _CloudColor, nearCloudColorAmount);
                    c += (1 - c.a) * totalSkyColor;

                    return c;
                }
                else
                {
                    
                    return 0;
                }
            }

            Varyings Vert(Attributes input)
            {
                Varyings output;

                
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);

                output.ray = normalize(input.positionOS.xyz);

                return output;
            }

            

            half4 Frag(Varyings input) : SV_Target
            {
                float Height = input.ray.y;
                float3 SkyColor = Height <0.0?float3(0,0,0):lerp(_BottomColor,_TopColor,Height);

                float3 moonDir = normalize(_MoonDirection.xyz);

                float3 dir = normalize(input.ray);
                // 月亮圆盘
                float moonDisk = GetMoonDisk(dir, moonDir, _MoonSize);

                // // 月亮外围柔光
                float moonGlow = GetMoonGlow(dir, moonDir, _MoonGlow) * _MoonGlowIntensity;

                // 合成
                SkyColor += _MoonColor.rgb * moonDisk * _MoonIntensity;
                SkyColor += _MoonColor.rgb * moonGlow;
                
                float3 ro = _WorldSpaceCameraPos.xyz;
                float4 rayMarchingColor = raymarching(ro, dir,float4(SkyColor,1));
                return  lerp(rayMarchingColor,float4(SkyColor,1),0.5)*para.x;
            }
            ENDHLSL
        }
    }
}