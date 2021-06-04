//Inspirert av https://samdriver.xyz/article/decal-render-intro

Shader "Unlit/DecalUnlit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" "DisableBatching" = "True"}
        LOD 100
        ZWrite Off
        ZTest LEqual
        Cull Back
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 viewDir : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);

                o.viewDir = -WorldSpaceViewDir(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                i.viewDir = normalize(i.viewDir);
                float3 cameraPos = _WorldSpaceCameraPos;
                float3 cameraFwd = normalize(mul((float3x3)unity_CameraToWorld, float3(0, 0, 1)));
                float viewDotFwd = dot(i.viewDir, cameraFwd);

                float depth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.screenPos.xy/i.screenPos.w));

                float4 pos = float4(cameraPos + depth * (i.viewDir/viewDotFwd), 1);

                float2 uv =  mul(unity_WorldToObject, pos).xz + float2(0.5, 0.5);
                fixed4 col = tex2D(_MainTex, uv);
                //col = fixed4(uv, 0, 1)
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
