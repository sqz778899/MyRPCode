using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Rendering.Universal
{
    internal class VolumetricCloud : ScriptableRendererFeature
    {
        VolumetricCloudPass m_volumetricCloudPass;
        //.................Setting.....................
        public Material VolumetricCloudMaterial;
        public RenderPassEvent VolumetricCloudRenderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        
        public override void Create()
        {
            if (m_volumetricCloudPass == null)
                m_volumetricCloudPass = new VolumetricCloudPass();
        }
        public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
        {
            m_volumetricCloudPass.SetUp(VolumetricCloudRenderPassEvent,VolumetricCloudMaterial,renderingData);
            renderer.EnqueuePass(m_volumetricCloudPass);
        }

        protected override void Dispose(bool disposing)
        {
            m_volumetricCloudPass?.Dispose();
        }

        #region Pass
        class VolumetricCloudPass : ScriptableRenderPass
        {
            Material m_PassMaterial;
            private static readonly int m_BlitTextureShaderID = Shader.PropertyToID("_MainTex");
            private RTHandle m_RTHVolumetricCloud;
            internal void SetUp(RenderPassEvent curRenderPassEvent,Material curMat,in RenderingData renderingData)
            {
                //Debug.Log("SetUp VolumetricCloudPass");
                m_PassMaterial = curMat;
                renderPassEvent = curRenderPassEvent;
            
                var curRTDescriptor = renderingData.cameraData.cameraTargetDescriptor;
                curRTDescriptor.depthBufferBits = (int) DepthBits.None;
                RenderingUtils.ReAllocateIfNeeded(ref m_RTHVolumetricCloud, curRTDescriptor, name: "_VolumetricCloudRT");
            }
            public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
            {
                if (renderingData.cameraData.isPreviewCamera)
                {
                    return;
                }
                Matrix4x4 projectionMatrix = GL.GetGPUProjectionMatrix(renderingData.cameraData.camera.projectionMatrix, false);
                Shader.SetGlobalMatrix("_InverseProjectionMatrix", projectionMatrix.inverse);
                Shader.SetGlobalMatrix("_InverseViewMatrix", renderingData.cameraData.camera.cameraToWorldMatrix);
                
                ref CommandBuffer cmd = ref renderingData.commandBuffer;
                var cameraData = renderingData.cameraData;
           
                Blitter.BlitCameraTexture(cmd, cameraData.renderer.cameraColorTargetHandle,
                    m_RTHVolumetricCloud);
                m_PassMaterial.SetTexture(m_BlitTextureShaderID, m_RTHVolumetricCloud);
           
                CoreUtils.SetRenderTarget(cmd, cameraData.renderer.GetCameraColorBackBuffer(cmd));
                CoreUtils.DrawFullScreen(cmd, m_PassMaterial);
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();
            }

            public void Dispose()
            {
                m_RTHVolumetricCloud?.Release();
            }
        }
        #endregion
    }
    
    
}
