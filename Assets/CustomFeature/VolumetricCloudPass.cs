using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace UnityEngine.Rendering.Universal
{
    internal class VolumetricCloudPass : ScriptableRenderPass
    {
        Material m_PassMaterial;
        private RTHandle m_RTHVolumetricCloud;
        internal void SetUp(RenderPassEvent curRenderPassEvent,Material curMat,in RenderingData renderingData)
        {
            Debug.Log("SetUp VolumetricCloudPass");
            m_PassMaterial = curMat;
            renderPassEvent = curRenderPassEvent;
            
            var curRTDescriptor = renderingData.cameraData.cameraTargetDescriptor;
            curRTDescriptor.depthBufferBits = (int) DepthBits.None;
            RenderingUtils.ReAllocateIfNeeded(ref m_RTHVolumetricCloud, curRTDescriptor, name: "_VolumetricCloudRT");
        }
        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
           ref CommandBuffer cmd = ref renderingData.commandBuffer;
           var cameraData = renderingData.cameraData;
           
           Blitter.BlitCameraTexture(cmd, cameraData.renderer.cameraColorTargetHandle,
               m_RTHVolumetricCloud);
           
           CoreUtils.DrawFullScreen(cmd, m_PassMaterial);
           context.ExecuteCommandBuffer(cmd);
           cmd.Clear();
        }

        public void Dispose()
        {
            m_RTHVolumetricCloud?.Release();
            Debug.Log("Dispose VolumetricCloudPass");
        }
    }
}
