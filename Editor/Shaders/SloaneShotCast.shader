Shader "Sloane/Shot/Cast"
{
    Properties
    {
        _BaseMap("Main Texture", 2D) = "white" {}
        _MaskMap("Mask Texture", 2D) = "white" {}
        _AlphaClip("Alpha Clip", Range(0.0, 1.0)) = 0.5
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
        float _AlphaClip;

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
            Name "Forward"
			Tags { "LightMode" = "SloaneCastAbeldo" }

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
            Name "Forward"
			Tags { "LightMode" = "SloaneCastNormal" }

            Blend One Zero
			ZWrite On
			ZTest Less
			ColorMask RGBA
            
            HLSLPROGRAM
            float3 PackNormal(real3 unpackedNormal)
            {
                return (unpackedNormal / 2.0 + 0.5);
            }

            half4 frag(Varyings input) : SV_Target 
            {
                float2 albedoUV = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                float4 albedo = tex2D(_BaseMap, albedoUV);
                clip(albedo.a - _AlphaClip);

                float2 normalUV = input.uv * _BumpMap_ST.xy + _BumpMap_ST.zw;
                float3 normalTS = UnpackNormalScale(tex2D(_BumpMap, normalUV), _BumpScale);

                float sgn = input.tangent.w;
                float3 bitangent = sgn * cross(input.normal.xyz, input.tangent.xyz);
                half3x3 tangentToWorld = half3x3(input.tangent.xyz, bitangent.xyz, input.normal.xyz);

                float3 normalWS = TransformTangentToWorld(normalTS, tangentToWorld);
                float3 normalVS = TransformWorldToViewDir(normalWS, true);

                return float4(PackNormal(normalVS), 1.0);
            }

            #pragma vertex BaseVert
            #pragma fragment frag

            ENDHLSL
        }

        Pass
        {
            Name "Forward"
			Tags { "LightMode" = "SloaneCastMask" }

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

                float2 maskUV = input.uv * _MaskMap_ST.xy + _MaskMap_ST.zw;
                float4 mask = tex2D(_MaskMap, maskUV);

                return mask;
            }

            #pragma vertex BaseVert
            #pragma fragment frag

            ENDHLSL
        }
    }
}
