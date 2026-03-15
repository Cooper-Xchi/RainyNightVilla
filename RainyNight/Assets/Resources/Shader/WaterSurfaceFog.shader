Shader "Custom/URP/WaterSurfaceMist"
{
    Properties
    {
        [Header(Base)]
        _BaseColor("Base Color", Color) = (0.24, 0.28, 0.32, 1)
        _Opacity("Opacity", Range(0, 1)) = 0.2

        [Header(Noise)]
        _NoiseTex("Noise Tex", 2D) = "white" {}
        _NoiseTiling1("Noise Tiling 1", Float) = 1.2
        _NoiseTiling2("Noise Tiling 2", Float) = 2.4
        _Scroll1("Scroll 1", Vector) = (0.02, 0.00, 0, 0)
        _Scroll2("Scroll 2", Vector) = (-0.01, 0.015, 0, 0)
        _NoiseContrast("Noise Contrast", Range(0.1, 8)) = 2.0
        _NoiseStrength("Noise Strength", Range(0, 2)) = 1.0

        [Header(Fade)]
        _Softness("Softness", Range(0.01, 1)) = 0.35
        _EdgeFade("Edge Fade", Range(0, 1)) = 0.15
        _ViewFadePower("View Fade Power", Range(0.1, 8)) = 2.5

        [Header(Optional Fresnel Boost)]
        _FresnelStrength("Fresnel Strength", Range(0, 2)) = 0.7

        [Header(World Mask)]
        _WorldNoiseScale("World Noise Scale", Float) = 0.15

        para("para",Vector) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "Queue"="Transparent"
            "RenderType"="Transparent"
        }

        Pass
        {
            Name "WaterSurfaceMist"

            Blend SrcAlpha OneMinusSrcAlpha
            ZWrite Off
            Cull Off
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float3 positionWS  : TEXCOORD1;
                float3 normalWS    : TEXCOORD2;
                float4 screenPos   : TEXCOORD3;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _Opacity;

                float _NoiseTiling1;
                float _NoiseTiling2;
                float4 _Scroll1;
                float4 _Scroll2;
                float _NoiseContrast;
                float _NoiseStrength;

                float _Softness;
                float _EdgeFade;
                float _ViewFadePower;

                float _FresnelStrength;
                float _WorldNoiseScale;
                float4 para;
            CBUFFER_END

            TEXTURE2D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);

            Varyings Vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS.xyz);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS);
                posInputs.positionWS.y += para.w*(sin(para.x*_Time.y+para.y*posInputs.positionWS.z)+1.0);
                output.positionHCS = TransformWorldToHClip(posInputs.positionWS);
                output.positionWS = posInputs.positionWS;
                output.normalWS = normalize(normalInputs.normalWS);
                output.uv = input.uv;
                output.screenPos = ComputeScreenPos(output.positionHCS);

                return output;
            }

            float SampleMistNoise(float2 uv, float3 positionWS)
            {
                float2 uv1 = uv *_NoiseTiling1  + _Time.y * _Scroll1.xy;
                float2 uv2 = uv * _NoiseTiling2 + _Time.y * _Scroll2.xy;

                float2 worldUV = positionWS.xz * _WorldNoiseScale;

                float n1 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uv1 +worldUV).r;
                float n2 = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, uv2  -worldUV*0.5 ).r;

                float n = lerp(n1, n2, 0.5);
                n = saturate(pow(n, _NoiseContrast));

                return n;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float3 normalWS = normalize(input.normalWS);
                float3 viewDirWS = normalize(_WorldSpaceCameraPos - input.positionWS);

                // 双层噪声
                float noise = SampleMistNoise(input.uv, input.positionWS);

                // 让雾有断裂和软边
                float alphaNoise = smoothstep(_EdgeFade, _EdgeFade + _Softness, noise);
                alphaNoise *= _NoiseStrength;

                // 视角越平，雾越明显（看水面时常见）
                float ndv = saturate(dot(normalWS, viewDirWS));
                float viewFade = pow(1.0 - ndv, _ViewFadePower);

                // Fresnel增强一点边缘氛围
                float fresnel = pow(1.0 - ndv, 3.0) * _FresnelStrength;

                float alpha = _Opacity * alphaNoise * saturate(viewFade + fresnel);

                float3 color = _BaseColor.rgb;

                return half4(color, alpha);
            }
            ENDHLSL
        }
    }
}