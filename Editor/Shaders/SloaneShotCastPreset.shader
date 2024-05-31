Shader "Sloane/Shot/CastPreset"
{
    Properties
    {
        _BaseMap("Main Texture", 2D) = "white" {}
        _MaskMap("Mask Texture", 2D) = "white" {}
        _MaskColor("Mask Color ", Color) = (1.0, 1.0, 1.0, 1.0)
        _MetallicGlossMap("Metallic Map", 2D) = "white" {}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion Map", 2D) = "white" {}
        _EmissionMap("Emission Map", 2D) = "white" {}
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
        };

        struct Varyings {
            float4 positionCS : SV_POSITION;
            float2 uv : TEXCOORD0;
            float3 normal : TEXCOORD1;
            float4 tangent : TEXCOORD2;
            float3 positionWS : TEXCOORD5;
        };

        CBUFFER_START(UnityPerMaterial)

        sampler2D _BaseMap;
        float4 _BaseMap_ST;

        float4 _MaskColor;

        sampler2D _MaskMap;
        float4 _MaskMap_ST;

        sampler2D _MetallicGlossMap;
        float4 _MetallicGlossMap_ST;

        sampler2D _BumpMap;
        float4 _BumpMap_ST;
        float _BumpScale;

        sampler2D _OcclusionMap;
        float4 _OcclusionMap_ST;

        CBUFFER_END


        Varyings BaseVert(Attributes input)
        {
            Varyings output = (Varyings)0;
            output.positionWS = TransformObjectToWorld(input.positionOS);
            output.positionCS = TransformWorldToHClip(output.positionWS);

            output.normal = TransformObjectToWorldNormal(input.normal);
            output.tangent.xyz = TransformObjectToWorldDir(input.tangent);
            output.tangent.w = input.tangent.w;

            output.uv = input.texcoord.xy;

            return output;
        }

        ENDHLSL

        Pass
        {
            Name "Forward"
			Tags { "LightMode" = "UniversalForward" }

            Blend One Zero
			ZWrite On
			ZTest Less
			ColorMask RGBA
            Cull Off
            
            HLSLPROGRAM

            half4 frag(Varyings input) : SV_Target 
            {
                float2 albedoUV = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                float4 albedo = tex2D(_BaseMap, albedoUV);
                clip(albedo.a - 0.5);

                return albedo;
            }

            #pragma vertex BaseVert
            #pragma fragment frag

            ENDHLSL
        }

        Pass
        {
            Name "Forward"
			Tags { "LightMode" = "DepthOnly" }

            Blend One Zero
			ZWrite On
			ZTest Less
			ColorMask 0
            Cull Off
            
            HLSLPROGRAM

            half4 frag(Varyings input) : SV_Target 
            {
                float2 albedoUV = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                float4 albedo = tex2D(_BaseMap, albedoUV);
                clip(albedo.a - 0.5);

                return albedo;
            }

            #pragma vertex BaseVert
            #pragma fragment frag

            ENDHLSL
        }
    }
}
