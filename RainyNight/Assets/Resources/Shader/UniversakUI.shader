Shader "Custom/UniversalUI"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white" {}
        [HDR]_BaseColor("Base Color", Color) = (1,1,1,1)

        // ���Լ��Ĳ���
        _Intensity("Intensity", Range(0, 2)) = 1
        _HueOffset("Hue Offset", Range(-1, 1)) = 0
        para("para",Vector) = (1,1,1,1)
    }

    SubShader
    {
        Tags
        {
            "RenderType"="Transparent"
            "Queue"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }

        Pass
        {
            Name "ForwardUnlit"
            Blend SrcAlpha OneMinusSrcAlpha

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float4 col : COLOR;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float4 col : COLOR;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float  _Intensity;
                float  _HueOffset;
                float4 para;
            CBUFFER_END

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            Varyings Vert(Attributes input)
            {
                Varyings output;
                output.positionHCS = TransformObjectToHClip(input.positionOS.xyz);
                output.uv = input.uv;
                output.col = input.col;
                return output;
            }

            

            half4 Frag(Varyings input) : SV_Target
            {
                float2 uv = input.uv;
                uv.x = saturate(para.x*(uv.x-0.5)+0.5);
                uv.y = saturate(para.y*(uv.y-0.5)+0.5);
                float4 col = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                float lumince = dot(col.rgb,float3(0.2154,0.5945,0.1954));
                return float4(col.rgb*input.col.rgb*(0.2*sin(_Time.y*para.w)+1.2),col.a*input.col.a*para.z*lumince);
            }

            ENDHLSL
        }
    }
}