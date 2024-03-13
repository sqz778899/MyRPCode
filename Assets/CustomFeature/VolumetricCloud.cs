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
    }
}
