using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;

namespace Sloane
{
    public class SloaneShotCasterEditor : EditorWindow
    {
        public struct CastChannelSettings
        {
            public bool castAbeldo;
            public bool castNormal;
            public bool castMask;
        }
        private static GameObject target;
        private static string targetPath;
        private static int segmentSize = 64;
        private static int segmentCountScale = 2;
        private static int mapSize = 16;
        private static Bounds bounds;

        private static CastChannelSettings castChannelSettings = new CastChannelSettings()
        {
            castAbeldo = true,
            castNormal = true,
            castMask = false
        };

        [MenuItem("Tools/Sloane/ShotCaster")]
        static void ShowWindow()
        {
            var window = GetWindow<SloaneShotCasterEditor>(true, "场景导出工具");
            window.Show();
        }

        private void OnGUI()
        {
            DrawParams();
            if (GUILayout.Button("Cast Model"))
            {
                if (target != null)
                {
                    targetPath = EditorUtility.SaveFilePanel("Select Output Path", "", "", "");
                    Debug.Log(targetPath);

                    ExecuteCast(target, bounds, targetPath, 2 * segmentCountScale, 4 * segmentCountScale, segmentSize, castChannelSettings);

                    Close();
                }
                else Debug.Log($"[{SloaneShotConst.AuthorName}] Please select the target object first!");
            }
        }

        private void DrawParams()
        {
            var nextTarget = EditorGUILayout.ObjectField("Target", target, typeof(GameObject), true) as GameObject;
            if (nextTarget != target)
            {
                target = nextTarget;
                bounds = GetBoundsFromRenderers(target);
            }
            segmentSize = EditorGUILayout.IntField("Segment Size", segmentSize);
            segmentCountScale = EditorGUILayout.IntField("Segment Count Scale", segmentCountScale);
            mapSize = EditorGUILayout.IntField("UV Map Size", mapSize);

            bounds = EditorGUILayout.BoundsField("Bounds", bounds);

            castChannelSettings.castAbeldo = EditorGUILayout.Toggle("Cast Abeldo", castChannelSettings.castAbeldo);
            castChannelSettings.castNormal = EditorGUILayout.Toggle("Cast Normal", castChannelSettings.castNormal);
            castChannelSettings.castMask = EditorGUILayout.Toggle("Cast Mask", castChannelSettings.castMask);

            if (segmentSize < 16) segmentSize = 16;
            if (segmentCountScale < 0) segmentCountScale = 0;
            if (mapSize < 64) mapSize = 64;
        }

        public static Bounds GetBoundsFromRenderers(GameObject targetObject)
        {
            var targetRenderers = targetObject.GetComponentsInChildren<Renderer>();
            Bounds outputBounds = new Bounds(Vector3.zero, Vector3.zero);
            if (targetRenderers.Length == 0) return outputBounds;
            foreach (var renderer in targetRenderers)
            {
                var currentBounds = renderer.bounds;
                currentBounds.center = targetObject.transform.InverseTransformPoint(currentBounds.center);
                outputBounds = CombineBounds(Vector3.zero, outputBounds, currentBounds); // bounds是世界空间的 现在虽然没问题但是不知道之后会如何
            }

            return outputBounds;
        }

        public static void ExecuteCast(GameObject targetObject, Bounds targetBounds, string outputPath, int zenithCount, int azimuthCount, int singleSegmentSize, CastChannelSettings settings)
        {
            azimuthCount = Mathf.Max(azimuthCount, 1);
            int segmentCount = (zenithCount + 1) * azimuthCount;
            int gridWidth = Mathf.CeilToInt(Mathf.Sqrt(segmentCount));

            // 切换pipeline
            RenderPipelineAsset pipelineCache = QualitySettings.renderPipeline;

            targetObject = InitializeTargetGameObject(targetObject);

            string cameraPath = SloaneShotConst.PackagePath + "\\Assets\\Prefabs\\SloaneShotCamera.prefab";
            Camera camera = AssetDatabase.LoadAssetAtPath<GameObject>(cameraPath).GetComponent<Camera>();
            camera = GameObject.Instantiate(camera, Vector3.zero, Quaternion.identity, targetObject.transform);
            camera.hideFlags = HideFlags.HideAndDontSave;
            InitializeTargetRenderers(targetObject);


            var castRenderTexture = new RenderTexture(singleSegmentSize, singleSegmentSize, 16, RenderTextureFormat.BGRA32, RenderTextureReadWrite.sRGB)
            {
                enableRandomWrite = true,
                name = "SloaneShotCastSegment",
                hideFlags = HideFlags.HideAndDontSave
            };
            var outputSetRenderTexture = new RenderTexture(singleSegmentSize * gridWidth, singleSegmentSize * gridWidth, 0, RenderTextureFormat.BGRA32, RenderTextureReadWrite.sRGB)
            {
                enableRandomWrite = true,
                name = "SloaneShotCastSet",
                hideFlags = HideFlags.HideAndDontSave
            };

            camera.targetTexture = castRenderTexture;
            float boundsDistance = targetBounds.size.magnitude / 2.0f;
            camera.orthographicSize = boundsDistance;

            // 初始化compute shader
            CommandBuffer cmd = new CommandBuffer();

            string computeShaderPath = SloaneShotConst.PackagePath + "\\Shaders\\PasteSegementToSet.compute";
            var computeShader = Instantiate(AssetDatabase.LoadAssetAtPath<ComputeShader>(computeShaderPath));
            int shaderKernel = computeShader.FindKernel("CSMain");

            computeShader.SetTexture(shaderKernel, "outputRT", outputSetRenderTexture);
            computeShader.SetInt("width", singleSegmentSize);
            computeShader.SetInt("height", singleSegmentSize);

            string pipelinePath;
            UniversalRenderPipelineAsset pipelineAsset;
            string outPath;

            if (settings.castAbeldo)
            {
                pipelinePath = SloaneShotConst.PackagePath + "\\Assets\\Rendering\\SloaneShotAbeldoPipeline.asset";
                pipelineAsset = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(pipelinePath);
                outPath = outputPath + "_abeldo.png";
                TakeShot(cmd, pipelineAsset, castRenderTexture, outputSetRenderTexture, computeShader, shaderKernel, zenithCount, azimuthCount, singleSegmentSize, gridWidth, camera, boundsDistance, outPath);
            }

            if (settings.castNormal)
            {
                pipelinePath = SloaneShotConst.PackagePath + "\\Assets\\Rendering\\SloaneShotNormalPipeline.asset";
                pipelineAsset = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(pipelinePath);
                outPath = outputPath + "_normal.png";
                TakeShot(cmd, pipelineAsset, castRenderTexture, outputSetRenderTexture, computeShader, shaderKernel, zenithCount, azimuthCount, singleSegmentSize, gridWidth, camera, boundsDistance, outPath);
            }

            if (settings.castMask)
            {
                pipelinePath = SloaneShotConst.PackagePath + "\\Assets\\Rendering\\SloaneShotMaskPipeline.asset";
                pipelineAsset = AssetDatabase.LoadAssetAtPath<UniversalRenderPipelineAsset>(pipelinePath);
                outPath = outputPath + "_mask.png";
                TakeShot(cmd, pipelineAsset, castRenderTexture, outputSetRenderTexture, computeShader, shaderKernel, zenithCount, azimuthCount, singleSegmentSize, gridWidth, camera, boundsDistance, outPath);
            }

            // 清理
            cmd.Release();
            DestroyImmediate(camera.gameObject);
            DestroyImmediate(targetObject);
            QualitySettings.renderPipeline = pipelineCache;
        }

        private static void TakeShot(CommandBuffer cmd, RenderPipelineAsset pipelineAsset, RenderTexture castRenderTexture, RenderTexture outputSetRenderTexture, ComputeShader computeShader, int shaderKernel, int zenithCount, int azimuthCount, int singleSegmentSize, int gridWidth, Camera camera, float boundsDistance, string outputPath)
        {
            QualitySettings.renderPipeline = pipelineAsset;

            // 拍照片
            cmd.SetRenderTarget(outputSetRenderTexture);
            cmd.ClearRenderTarget(true, true, Color.clear);
            Graphics.ExecuteCommandBuffer(cmd);

            int index = 0;

            for (int i = 0; i <= zenithCount; i++)
            {
                for (int j = 0; j < azimuthCount; j++)
                {
                    float theta = zenithCount == 0 ? Mathf.PI / 2.0f : Mathf.PI * i;
                    float phi = 2.0f * j * Mathf.PI / azimuthCount;

                    Vector3 viewDirection = new Vector3(-Mathf.Sin(theta) * Mathf.Sin(phi), Mathf.Cos(theta), -Mathf.Sin(theta) * Mathf.Cos(phi));
                    viewDirection *= -1;
                    Vector3 upDirection = new Vector3(Mathf.Cos(theta) * Mathf.Sin(phi), Mathf.Sin(theta), Mathf.Cos(theta) * Mathf.Cos(phi));

                    camera.transform.rotation = Quaternion.LookRotation(viewDirection, upDirection);
                    camera.transform.localPosition = -viewDirection * boundsDistance;

                    camera.Render();

                    computeShader.SetInt("offsetX", index % gridWidth * singleSegmentSize);
                    computeShader.SetInt("offsetY", index / gridWidth * singleSegmentSize);

                    computeShader.SetTexture(shaderKernel, "inputRT", castRenderTexture);
                    computeShader.Dispatch(shaderKernel, singleSegmentSize / 8, singleSegmentSize / 8, 1);

                    index++;
                }
            }

            Texture2D outputAbeldoTexture = new Texture2D(outputSetRenderTexture.width, outputSetRenderTexture.height, TextureFormat.RGBA32, false);

            RenderTexture.active = outputSetRenderTexture;
            outputAbeldoTexture.ReadPixels(new Rect(0, 0, outputSetRenderTexture.width, outputSetRenderTexture.height), 0, 0);
            RenderTexture.active = null;

            byte[] bytes;
            bytes = outputAbeldoTexture.EncodeToPNG();

            System.IO.File.WriteAllBytes(outputPath, bytes);
            AssetDatabase.ImportAsset(outputPath);
            AssetDatabase.LoadAssetAtPath<Texture2D>(outputPath);
        }

        public static GameObject InitializeTargetGameObject(GameObject targetObject)
        {
            var copyObject = GameObject.Instantiate(targetObject, Vector3.zero, Quaternion.identity);
            copyObject.hideFlags = HideFlags.HideAndDontSave;

            return copyObject;
        }

        public static Bounds InitializeTargetRenderers(GameObject targetObject)
        {
            string shaderPath = SloaneShotConst.PackagePath + "\\Shaders\\SloaneShotCast.shader";
            var shader = AssetDatabase.LoadAssetAtPath<Shader>(shaderPath);

            var targetRenderers = targetObject.GetComponentsInChildren<Renderer>();
            Bounds outputBounds = new Bounds(Vector3.zero, Vector3.zero);
            if (targetRenderers.Length == 0) return outputBounds;
            foreach (var renderer in targetRenderers)
            {
                outputBounds = CombineBounds(Vector3.zero, outputBounds, renderer.bounds); // bounds是世界空间的 现在虽然没问题但是不知道之后会如何
                Material[] materials = new Material[renderer.sharedMaterials.Length];
                for (int i = 0; i < renderer.sharedMaterials.Length; i++)
                {
                    Material materialCache = renderer.sharedMaterials[i];
                    materials[i] = new Material(shader)
                    {
                        hideFlags = HideFlags.HideAndDontSave
                    };

                    materials[i].CopyPropertiesFromMaterial(materialCache);
                }

                renderer.sharedMaterials = materials;
            }

            return outputBounds;
        }

        static Bounds CombineBounds(Vector3 center, Bounds bounds0, Bounds bounds1)
        {
            Vector3 size0 = new Vector3(
                Mathf.Max(Mathf.Abs(bounds0.center.x - center.x - bounds0.size.x / 2.0f), Mathf.Abs(bounds0.center.x - center.x + bounds0.size.x / 2.0f)),
                Mathf.Max(Mathf.Abs(bounds0.center.y - center.y - bounds0.size.y / 2.0f), Mathf.Abs(bounds0.center.y - center.y + bounds0.size.y / 2.0f)),
                Mathf.Max(Mathf.Abs(bounds0.center.z - center.z - bounds0.size.z / 2.0f), Mathf.Abs(bounds0.center.z - center.z + bounds0.size.z / 2.0f))
            );

            Vector3 size1 = new Vector3(
                Mathf.Max(Mathf.Abs(bounds1.center.x - center.x - bounds1.size.x / 2.0f), Mathf.Abs(bounds1.center.x - center.x + bounds1.size.x / 2.0f)),
                Mathf.Max(Mathf.Abs(bounds1.center.y - center.y - bounds1.size.y / 2.0f), Mathf.Abs(bounds1.center.y - center.y + bounds1.size.y / 2.0f)),
                Mathf.Max(Mathf.Abs(bounds1.center.z - center.z - bounds1.size.z / 2.0f), Mathf.Abs(bounds1.center.z - center.z + bounds1.size.z / 2.0f))
            );

            Vector3 size = new Vector3(
                Mathf.Max(size0.x, size1.x) * 2.0f,
                Mathf.Max(size0.y, size1.y) * 2.0f,
                Mathf.Max(size0.z, size1.z) * 2.0f
            );

            return new Bounds(center, size);
        }
    }
}
