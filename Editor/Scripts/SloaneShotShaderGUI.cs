using System;
using UnityEditor;
using UnityEngine;
using UnityEngine.Assertions;
using UnityEngine.Rendering;

namespace Sloane
{
    public class SloaneShotShaderGUI : BaseShaderGUI
    {
        protected MaterialProperty propertyZenithCount;
        protected MaterialProperty propertyUseLut;

        public static readonly GUIContent useLutText = EditorGUIUtility.TrTextContent("Look Up Table",
        "Use look up tables to replace trigonometric function options");

        public override void FindProperties(MaterialProperty[] properties)
        {
            base.FindProperties(properties);
            propertyZenithCount = FindProperty("_ZenithCount", properties, false);
            propertyUseLut = FindProperty("_UseLut", properties, false);
        }

        public override void DrawSurfaceOptions(Material material)
        {
            base.DrawSurfaceOptions(material);
            if (propertyUseLut != null)
            {
                DrawFloatToggleProperty(useLutText, propertyUseLut);
            }
        }

        public override void DrawBaseProperties(Material material)
        {
            if (baseMapProp != null)
            {
                materialEditor.TexturePropertySingleLine(Styles.baseMap, baseMapProp);
            }
        }

        protected static void DrawFloatToggleProperty(GUIContent styles, MaterialProperty prop)
        {
            if (prop == null)
                return;

            EditorGUI.BeginChangeCheck();
            EditorGUI.showMixedValue = prop.hasMixedValue;
            bool newValue = EditorGUILayout.Toggle(styles, prop.floatValue == 1);
            if (EditorGUI.EndChangeCheck())
                prop.floatValue = newValue ? 1.0f : 0.0f;
            EditorGUI.showMixedValue = false;
        }

        protected void SetKeywordWithFloat(Material material, string propertyName, string keyword, Action<Material> enableAction = null, Action<Material> disableAction = null)
        {
            if (!material.HasProperty(propertyName)) return;
            float val = material.GetFloat(propertyName);
            if (val == 1.0f)
            {
                material.EnableKeyword(keyword);
                enableAction?.Invoke(material);
            }
            else
            {
                material.DisableKeyword(keyword);
                disableAction?.Invoke(material);
            }
        }

        public override void ValidateMaterial(Material material)
        {
            base.ValidateMaterial(material);
            SetKeywordWithFloat(material, "_UseLut", "_SLOANESHOT_WITHLUT", SetLut);
        }

        protected void SetLut(Material material)
        {
            // Debug.Log(SloaneShotConst.PackagePath + "\\Textures\\Zenith.png");
            Texture2D zenithMap = AssetDatabase.LoadAssetAtPath<Texture2D>(SloaneShotConst.PackagePath + "\\Textures\\Zenith.png");
            Texture2D azimuthMap = AssetDatabase.LoadAssetAtPath<Texture2D>(SloaneShotConst.PackagePath + "\\Textures\\Azimuth.png");
            Texture2D sinLut = AssetDatabase.LoadAssetAtPath<Texture2D>(SloaneShotConst.PackagePath + "\\Textures\\SinLut.png");

            material.SetTexture("_ZenithMap", zenithMap);
            material.SetTexture("_Azimuth", azimuthMap);
            material.SetTexture("_SinLut", sinLut);
        }
    }
}
