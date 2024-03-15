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
                float4 vertex : POSITION;
                uint vertexID : SV_VertexID;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            
            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float2 texcoord   : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);
            float4 _MainTex_ST;

            float3 _RayBoxMin;
            float3 _RayBoxMax;

            float4x4 _InverseProjectionMatrix;
            float4x4 _InverseViewMatrix;

            //射线与包围盒相交, x 到包围盒最近的距离， y 穿过包围盒的距离
            float2 RayBoxDst(float3 boxMin, float3 boxMax, float3 pos, float3 rayDir)
            {
                float3 t0 = (boxMin - pos) / max(rayDir,  float3(0.00001f, 0.00001f, 0.00001f));
                float3 t1 = (boxMax - pos) / max(rayDir,  float3(0.00001f, 0.00001f, 0.00001f));
                
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);
                
                //射线到box两个相交点的距离, dstA最近距离， dstB最远距离
                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(min(tmax.x, tmax.y), tmax.z);
                
                float dstToBox = max(0, dstA);
                float dstInBox = max(0, dstB - dstToBox);
                
                return float2(dstToBox, dstInBox);
            }

            float3 GetRayByScreenSpace(float2 ScreenUV)
            {
                // 创建NDC空间中的射线，z值从-1（near plane）变到1（far plane）。
                float3 startRayNDC = float3(ScreenUV.x * 2.0f - 1.0f, ScreenUV.y * 2.0f - 1.0f, -1.0f);
                float3 endRayNDC = float3(ScreenUV.x * 2.0f - 1.0f, ScreenUV.y * 2.0f - 1.0f, 1.0f);
                //unity_CameraInvProjection
                
                // 屏幕空间 --> 视锥空间
                float4 startRayView = mul(_InverseProjectionMatrix, startRayNDC);
                 startRayView.xyz /= startRayView.w;
                float4 endRayView = mul(_InverseProjectionMatrix, endRayNDC);
                endRayView.xyz /= endRayView.w;
                //视锥空间 --> 世界空间
                float4 startRayWS = mul(_InverseViewMatrix, float4(startRayView.xyz, 1));
                float4 endRayWS = mul(_InverseViewMatrix, float4(endRayView.xyz, 1));
                
                float3 rayDir = normalize(startRayWS.xyz - endRayWS.xyz);
                return rayDir;
            }

            float4 GetWorldSpacePosition(float depth, float2 uv)
            {
                 // 屏幕空间 --> 视锥空间
                 float4 view_vector = mul(_InverseProjectionMatrix, float4(2.0 * uv - 1.0, depth, 1.0));
                 view_vector.xyz /= view_vector.w;
                 //视锥空间 --> 世界空间
                 float4 world_vector = mul(_InverseViewMatrix, float4(view_vector.xyz, 1));
                 return world_vector;
             }

            float cloudRayMarching(float3 startPoint, float3 direction) 
            {
                float3 testPoint = startPoint;
                float sum = 0.0;
                direction *= 0.05;//每次步进间隔
                for (int i = 0; i < 256; i++)//步进总长度
                {
                    testPoint += direction;
                    if (testPoint.x < 1 && testPoint.x > -1 &&
                    testPoint.z < 1 && testPoint.z > -1 &&
                    testPoint.y < 1 && testPoint.y > -1)
                    {
                        sum += 0.01;
                    }
                }
                return sum;
            }
            
            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
                output.positionWS = TransformObjectToWorld(input.vertex.xyz);
                return output;
            }

            float4 frag (Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = input.texcoord;
                half3 viewDirWS = GetWorldSpaceNormalizeViewDir(input.positionWS);

                float3 ray = GetRayByScreenSpace(uv);
                
                float p = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
                float4 worldPos = GetWorldSpacePosition(depth, uv);
                float3 worldViewDir = normalize(worldPos.xyz - _WorldSpaceCameraPos.xyz) ;
                float2 ppp = RayBoxDst(_RayBoxMin, _RayBoxMax, _WorldSpaceCameraPos,worldViewDir);
                bool rayHitBox = ppp.y > 0;
                float cloud = cloudRayMarching(_WorldSpaceCameraPos.xyz, worldViewDir);
                //float3 worldViewDir = normalize(xxx - _WorldSpaceCameraPos) ;
                float4 col = float4(_RayBoxMax,1);
                /*if (ppp.y == 0)
                {
                    col = float4(_RayBoxMin,1);
                }*/
                //rayBoxDst()
                return col;
            }
           ENDHLSL
        }
    }
}
