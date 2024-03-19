Shader "RenderFeature/VolumetricCloud"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NoiseTex ("Texture", 3D) = "white" {}
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
                float3 vertex : POSITION;
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
            TEXTURE3D(_NoiseTex);
            SAMPLER(sampler_NoiseTex);
            
            float4 _MainTex_ST;

            float3 _RayBoxMin;
            float3 _RayBoxMax;

            float4x4 _InverseProjectionMatrix;
            float4x4 _InverseViewMatrix;

            float4 GetWorldSpacePosition(float depth, float2 uv)
            {
                 // 屏幕空间 --> 视锥空间
                 float4 view_vector = mul(_InverseProjectionMatrix, float4(2.0 * uv - 1.0, depth, 1.0));
                 view_vector.xyz /= view_vector.w;
                 //视锥空间 --> 世界空间
                 float4 world_vector = mul(_InverseViewMatrix, float4(view_vector.xyz, 1));
                 return world_vector;
             }

            float2 rayBoxDst(float3 boundsMin, float3 boundsMax,
                            float3 rayOrigin, float3 invRaydir) 
            {
                float3 t0 = (boundsMin - rayOrigin) * invRaydir;
                float3 t1 = (boundsMax - rayOrigin) * invRaydir;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);

                float dstA = max(max(tmin.x, tmin.y), tmin.z); //进入点
                float dstB = min(tmax.x, min(tmax.y, tmax.z)); //出去点

                float dstToBox = max(0, dstA);
                float dstInsideBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }


            /*float3 lightmarch(float3 position ,float dstTravelled)
            {
               float3 dirToLight = _WorldSpaceLightPos0.xyz;
               //灯光方向与边界框求交，超出部分不计算
               float dstInsideBox = rayBoxDst(_boundsMin, _boundsMax, position, 1 / dirToLight).y;
               float stepSize = dstInsideBox / 10;
               float totalDensity = 0;

              for (int step = 0; step < 8; step++) //灯光步进次数
              { 
                 position += dirToLight * stepSize; //向灯光步进
                 totalDensity += max(0, sampleDensity(position) * stepSize); //步进的时候采样噪音累计受灯光影响密度
              }
              float transmittance = exp(-totalDensity * _lightAbsorptionTowardSun);
              //将重亮到暗映射为 3段颜色 ,亮->灯光颜色 中->ColorA 暗->ColorB
              float3 cloudColor = lerp(_colA, _LightColor0, saturate(transmittance * _colorOffset1));
              cloudColor = lerp(_colB, cloudColor, saturate(pow(transmittance * _colorOffset2, 3)));
              return _darknessThreshold + transmittance * (1 - _darknessThreshold) * cloudColor;
            }*/
                        
            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;
                output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
                output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
                output.positionWS = TransformObjectToWorld(input.vertex);
                return output;
            }

            float4 frag (Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                float2 uv = input.texcoord;
                
                float3 screenColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                float3 rayPos = _WorldSpaceCameraPos;
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, uv);
                float depthLinear = LinearEyeDepth(depth,_ZBufferParams);
                
                float4 worldPos = GetWorldSpacePosition(depth, uv);
                float3 worldViewDir = normalize(worldPos.xyz - rayPos.xyz);
                
                float2 rayToContainerInfo = rayBoxDst(_RayBoxMin, _RayBoxMax, rayPos, (1 / worldViewDir));
                float dstToBox = rayToContainerInfo.x; //相机到容器的距离
                float dstInsideBox = rayToContainerInfo.y; //返回光线是否在容器中
                
                float dstLimit = min(depthLinear - dstToBox, dstInsideBox);

                float _rayStep = 0.01f;
                float sumDensity = 0;
                float dstTravelled = 0;
                float3 entryPoint = rayPos + worldViewDir * dstToBox;
                
                for (int j = 0; j < 128; j++)
                {
                    if (dstTravelled < dstLimit) //被遮住时步进跳过
                    {
                        rayPos = entryPoint + (worldViewDir * dstTravelled );
                        sumDensity += SAMPLE_TEXTURE3D(_NoiseTex, sampler_NoiseTex, rayPos) * _rayStep;
                        //sumDensity2 *=  exp(-density * _rayStep);
                    }
                    else
                        break;
                    dstTravelled += _rayStep; //每次步进长度
                 }
                float transmittance = exp(-sumDensity);
                
                float4 col = float4(screenColor * pow(transmittance,5),1);
                return col;
            }
            ENDHLSL
        }
    }
}