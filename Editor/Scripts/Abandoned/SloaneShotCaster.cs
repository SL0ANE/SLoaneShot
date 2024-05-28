using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Sloane
{
    public class SloaneShotCaster : MonoBehaviour
    {
#if UNITY_EDITOR
        [SerializeField, Min(1)] protected int segmentSize = 64;
        [SerializeField, Min(1)] protected int segmentCountScale = 8;
        [SerializeField, Min(1)] protected int mappingSize = 512;
        

        public void ExecuteCast()
        {
            string outputPath = EditorUtility.SaveFilePanel("Select Output Path", "", "", "");
            string abeldoPath = outputPath + "_abledo.png";
            string normalPath = outputPath + "_normal.png";

            // Debug.Log(outputPath);

            int zenithCount = 2 * segmentCountScale;
            int azimuthCount = 4 * segmentCountScale;

            int segmentCount = (zenithCount + 1) * azimuthCount;
            int girdWidth = Mathf.FloorToInt(Mathf.Sqrt(segmentCount));

            for(int i = 0; i <= zenithCount; i++)
            {
                for(int j = 0; j < azimuthCount; j++)
                {
                    float theta = Mathf.PI * i / zenithCount;
                    float phi = 2.0f * i * Mathf.PI / azimuthCount;

                    Vector3 viewDirection = new Vector3(Mathf.Cos(theta) * Mathf.Cos(phi), Mathf.Cos(theta) * Mathf.Sin(phi), Mathf.Sin(theta));
                }
            }
        }
#endif
    }
}