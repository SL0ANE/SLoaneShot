using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEditor;
using UnityEditor.VersionControl;
using UnityEngine;

namespace Sloane
{
    public static class SloaneShotConst
    {
        public static readonly string AuthorName = "Sloane";
        public static readonly string PackageName = "SloaneShot";
        public static readonly string PackagePath = GetPackagePath();
        static string GetPackagePath()
        {
            var scriptName = "SloaneShotConst";
            var path = AssetDatabase.FindAssets(scriptName);
            if(path.Length > 1)
            {
                Debug.LogWarning($"[{SloaneShotConst.AuthorName}] Duplicated file name {scriptName}!");
                return string.Empty;
            }
            else if(path.Length == 0)
            {
                Debug.LogWarning($"[{SloaneShotConst.AuthorName}] File {scriptName} is missing!");
                return string.Empty;
            }

            var pathStr = AssetDatabase.GUIDToAssetPath(path[0]);

            if(!pathStr.EndsWith(".cs"))
            {
                Debug.LogWarning($"[{SloaneShotConst.AuthorName}] File {scriptName} is missing!");
                return string.Empty;
            }
            
            return Path.GetDirectoryName(Path.GetDirectoryName(pathStr));
        }
    }
}
