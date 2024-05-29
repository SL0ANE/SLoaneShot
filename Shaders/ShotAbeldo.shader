Shader "Sloane/Shot/Unlit"
{
    Properties
    {
        _BaseMap("Main Texture", 2D) = "white" {}
        _AlphaClip("Alpha Clip", Range(0.0, 1.0)) = 0.5
        _ZenithCount("Zenith Count", Int) = 5
        _AzimuthCount("Azimuth Count", Int) = 8
        _GridCount("Grid Count", Int) = 8
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue" = "Geometry"}
        
        LOD 0

        HLSLINCLUDE
        
        #pragma enable_d3d11_debug_symbols
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

        struct Attributes {
            float3 positionOS : POSITION;
            float3 normal : NORMAL;
            float4 tangent : TANGENT;
            float4 texcoord : TEXCOORD0;

            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct Varyings {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 normal : TEXCOORD1;
            float4 tangent : TEXCOORD2;
            float3 positionWS : TEXCOORD5;

            UNITY_VERTEX_INPUT_INSTANCE_ID
	        UNITY_VERTEX_OUTPUT_STEREO
        };

        CBUFFER_START(UnityPerMaterial)

        sampler2D _BaseMap;
        float4 _BaseMap_ST;
        float _AlphaClip;

        int _ZenithCount;
        int _AzimuthCount;
        int _GridCount;

        CBUFFER_END

        #include "SloaneShotUtility.hlsl"
        ENDHLSL

        Pass
        {
            Name "Forward"
			Tags { "LightMode" = "UniversalForward" }

            Blend One Zero
			ZWrite On
			ZTest Less
			ColorMask RGBA
            
            HLSLPROGRAM

            half4 frag(Varyings input) : SV_Target 
            {
                float2 albedoUV = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                float4 albedo = tex2D(_BaseMap, albedoUV);
                clip(albedo.a - _AlphaClip);

                return albedo;
            }

            #pragma vertex BaseVert
            #pragma fragment frag

            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{"LightMode" = "DepthOnly"}

            Blend One Zero
			ZWrite On
			ZTest Less
			ColorMask 0
            
            HLSLPROGRAM

            half4 frag(Varyings input) : SV_Target 
            {
                float2 albedoUV = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                float4 albedo = tex2D(_BaseMap, albedoUV);
                clip(albedo.a - _AlphaClip);

                return albedo;
            }

            #pragma vertex BaseVert
            #pragma fragment frag

            ENDHLSL
        }
    }
}