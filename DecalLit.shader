//Inspirert av https://samdriver.xyz/article/decal-render-intro 
//+ https://catlikecoding.com/unity/tutorials/rendering/part-4/ + https://www.ronja-tutorials.com/post/018-postprocessing-normal/

Shader "Unlit/DecalLit"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
        _Tint("Tint", Color) = (1,1,1,1)
    }
        SubShader
    {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" "DisableBatching" = "True"}
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
            #include "UnityLightingCommon.cginc"

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
            sampler2D _CameraDepthNormalsTexture;
            float4 _MainTex_ST;
            fixed4 _Tint;

            v2f vert(appdata v)
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


                //Jeg kan ikke tro at dette fungerer, forventer at Jan Fredrik Karlsen skal dukke opp hvert øyeblikk...
                //Lavere presisjon enn _CameraDepthTexture, bytter kanskje hvis vi har overskudd
                float4 enc = tex2D(_CameraDepthNormalsTexture, i.screenPos.xy / i.screenPos.w);
                float3 normals = DecodeViewNormalStereo(enc);
                float depth = _ProjectionParams.y +DecodeFloatRG(enc.zw) * (_ProjectionParams.z - _ProjectionParams.y);

                
                float3 lightDir = mul(UNITY_MATRIX_V, _WorldSpaceLightPos0);
                float NdotL = saturate(dot(normals, lightDir));

                fixed4 lightColor = _LightColor0;

                float4 pos = float4(cameraPos + depth * (i.viewDir / viewDotFwd), 1);
                float2 uv = mul(unity_WorldToObject, pos).xz + float2(0.5, 0.5);


                fixed4 col = tex2D(_MainTex, uv) * NdotL * lightColor * _Tint;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}
