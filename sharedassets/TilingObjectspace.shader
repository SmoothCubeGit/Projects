Shader "Space/ObjectSpaceTiling"
{
    Properties
    {
        _Color("Main Color", Color) = (1, 1, 1, 1)
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _Tiling("Tiling Factor", Float) = 1.0
        _Smoothness("Smoothness", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags { 
            "RenderPipeline" = "UniversalPipeline" 
            "RenderType" = "Opaque" 
            "Queue" = "Geometry" 
        }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS   : SV_POSITION;
                float3 scaledLocalPos : TEXCOORD0;
                float3 normalWS       : TEXCOORD1;
                float3 localNormal    : TEXCOORD3;
                float3 positionWS     : TEXCOORD4;
            };

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _Color;
                float _Tiling;
                float _Smoothness;
            CBUFFER_END

            Varyings vert(Attributes input)
            {
                Varyings output;
                
                float3 worldPos = TransformObjectToWorld(input.positionOS.xyz);
                output.positionWS = worldPos;
                
                output.positionCS = TransformWorldToHClip(worldPos);
                
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.localNormal = input.normalOS;

                float4x4 m = GetObjectToWorldMatrix();
                float3 scale = float3(
                    length(float3(m[0][0], m[1][0], m[2][0])),
                    length(float3(m[0][1], m[1][1], m[2][1])),
                    length(float3(m[0][2], m[1][2], m[2][2]))
                );

                output.scaledLocalPos = input.positionOS.xyz * scale;
                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 uv = input.scaledLocalPos * _Tiling;
                float3 nAbs = abs(input.localNormal);
                float3 signN = sign(input.localNormal);
                
                float3 weights = 0;
                if (nAbs.x >= nAbs.y && nAbs.x >= nAbs.z) weights.x = 1;
                else if (nAbs.y >= nAbs.z) weights.y = 1;
                else weights.z = 1;

                float2 uvX = float2(uv.z * signN.x, uv.y);
                float2 uvY = float2(uv.x * signN.y, uv.z);
                float2 uvZ = float2(uv.x * -signN.z, uv.y);

                half4 tex = (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvX) * weights.x +
                             SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvY) * weights.y +
                             SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uvZ) * weights.z);

                half3 albedo = tex.rgb * _Color.rgb;

                float4 shadowCoord = TransformWorldToShadowCoord(input.positionWS);
                
                Light mainLight = GetMainLight(shadowCoord);
                float3 normalWS = normalize(input.normalWS);
                
                half diffuse = saturate(dot(normalWS, mainLight.direction));
                half3 ambient = SampleSH(normalWS) * albedo;
                
                half3 lighting = mainLight.color * (diffuse * mainLight.shadowAttenuation);
                
                return half4(albedo * lighting + ambient, 1.0);
            }
            ENDHLSL
        }

        UsePass "Universal Render Pipeline/Lit/ShadowCaster"
    }
}
