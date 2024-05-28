using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Sloane
{
    [InitializeOnLoad]
    public static class InitailizeSloaneShotProjectSettings
    {
        static InitailizeSloaneShotProjectSettings()
        {
            var pipeline = GraphicsSettings.currentRenderPipeline as UniversalRenderPipelineAsset;

            if(pipeline == null)
            {
                Debug.LogWarning($"[{SloaneShotConst.AuthorName}] {SloaneShotConst.PackageName} needs to work with URP!");
            }
        }
    }
}
