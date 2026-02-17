Shader "Custom/SimpleSixBandSkybox"
{
    Properties
    {
        _Color1 ("Band 1 (Top)", Color) = (0.4, 0.7, 1.0, 1)
        _Color2 ("Band 2", Color) = (0.5, 0.8, 1.0, 1)
        _Color3 ("Band 3", Color) = (0.7, 0.9, 1.0, 1)
        _Color4 ("Band 4", Color) = (0.3, 0.8, 0.4, 1)
        _Color5 ("Band 5", Color) = (0.2, 0.6, 0.3, 1)
        _Color6 ("Band 6 (Bottom)", Color) = (0.1, 0.4, 0.2, 1)
        _Blend ("Blend", Range(0.01, 0.5)) = 0.02
        
        [Header(Horizon Line)]
        _HorizonColor ("Horizon Color", Color) = (0.8, 0.8, 0.8, 1)
        _HorizonWidth ("Horizon Width", Range(0.001, 0.1)) = 0.003
        _HorizonIntensity ("Horizon Intensity", Range(0, 2)) = 0.8
    }
    
    SubShader
    {
        Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
        Cull Off ZWrite Off
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            
            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 dir : TEXCOORD0;
            };
            
            fixed4 _Color1, _Color2, _Color3, _Color4, _Color5, _Color6;
            float _Blend;
            fixed4 _HorizonColor;
            float _HorizonWidth, _HorizonIntensity;
            
            v2f vert (appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.dir = v.vertex.xyz;
                return o;
            }
            
            fixed4 frag (v2f i) : SV_Target
            {
                float y = normalize(i.dir).y; // -1 to 1
                y = y * 0.5 + 0.5; // 0 to 1
                
                fixed4 color = _Color6;
                
                color = lerp(color, _Color5, smoothstep(0.0, _Blend, y - 0.0));
                color = lerp(color, _Color4, smoothstep(0.2 - _Blend, 0.2 + _Blend, y));
                color = lerp(color, _Color3, smoothstep(0.4 - _Blend, 0.4 + _Blend, y));
                color = lerp(color, _Color2, smoothstep(0.6 - _Blend, 0.6 + _Blend, y));
                color = lerp(color, _Color1, smoothstep(0.8 - _Blend, 0.8 + _Blend, y));
                
                // Add horizon line
                float horizon = abs(y - 0.5);
                float horizonLine = 1.0 - smoothstep(0, _HorizonWidth, horizon);
                color = lerp(color, _HorizonColor, horizonLine * _HorizonIntensity);
                
                return color;
            }
            ENDCG
        }
    }
}