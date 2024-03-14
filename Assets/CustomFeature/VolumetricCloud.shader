Shader "RenderFeature/VolumetricCloud"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"
            struct Attributes
            {
                uint vertexID : SV_VertexID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 texcoord   : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            float3 _RayBoxMin;
            float3 _RayBoxMax;

            //射线与包围盒相交, x 到包围盒最近的距离， y 穿过包围盒的距离
            float2 RayBoxDst(float3 boxMin, float3 boxMax, float3 pos, float3 rayDir)
            {
                float3 t0 = (boxMin - pos) / rayDir;
                float3 t1 = (boxMax - pos) / rayDir;
                
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);
                
                //射线到box两个相交点的距离, dstA最近距离， dstB最远距离
                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(min(tmax.x, tmax.y), tmax.z);
                
                float dstToBox = max(0, dstA);
                float dstInBox = max(0, dstB - dstToBox);
                
                return float2(dstToBox, dstInBox);
            }
            
            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
                return output;
            }

            float4 frag (Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = input.texcoord;
                //half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);
                
                float p = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                //RayBoxDst(_RayBoxMin, _RayBoxMax, _WorldSpaceCameraPos, float3 rayDir);
                //rayBoxDst()
                return float4(_WorldSpaceCameraPos,1);
            }
           ENDHLSL
        }
    }
}
