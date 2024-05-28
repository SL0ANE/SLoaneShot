using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.UIElements;
using UnityEngine;
using UnityEngine.UIElements;

namespace Sloane
{

    [CustomEditor(typeof(SloaneShotCaster))]
    public class SloaneShotCasterInspector : Editor
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            if(GUILayout.Button("Cast Model to Target "))
            {
                var caster = target as SloaneShotCaster;
                caster.ExecuteCast();
            }
        }
    }
}
