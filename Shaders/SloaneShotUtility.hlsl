
#define EPSILON 0.05

#ifdef _SLOANESHOT_WITHLUT

float LutSin(float angle)
{
    float target = fmod(angle / (2.0 * PI), 1.0);
    // if(target < 0) target += 1.0;
    float2 lutUV = float2(target, 0.5);

    return tex2Dlod(_SinLut, float4(lutUV, 0.0, 0.0)).r * 2.0 - 1.0;
}

float LutCos(float angle)
{
    return LutSin(0.5 * PI - angle);
}

#endif

// 获得正确模型空间下的相机方向
// 广告牌在模型空间下操作
void GetCorrectedCameraVector(out float3 camRightDir, out float3 camUpDir, out float3 camFrontDir, out int zenithIndex, out int azimuthIndex)
{
    camFrontDir = mul(UNITY_MATRIX_I_M, mul(UNITY_MATRIX_M, float4(0.0, 0.0, 0.0, 1.0)).xyz - _WorldSpaceCameraPos);
    camFrontDir = normalize(camFrontDir);
    camUpDir = mul(UNITY_MATRIX_I_M, float3(unity_CameraToWorld[0][1], unity_CameraToWorld[1][1], unity_CameraToWorld[2][1]));
    camUpDir = normalize(camUpDir);

#ifdef _SLOANESHOT_WITHLUT

    float2 zenithUV = float2(camFrontDir.y / 2.0 + 0.5, 0.5);
    float theta = tex2Dlod(_ZenithMap, float4(zenithUV, 0.0, 0.0)).r;
    zenithIndex = round(theta * _ZenithCount);
    theta *= PI;

    float2 azimuthUV;
    if(abs(theta) < EPSILON) azimuthUV = float2(camUpDir.x, camUpDir.z) * 0.5 + 0.5;
    else if(abs(PI - theta) < EPSILON) azimuthUV = float2(-camUpDir.x, -camUpDir.z) * 0.5 + 0.5;
    else azimuthUV = float2(-camFrontDir.x, -camFrontDir.z) * 0.5 + 0.5;

    float phi = tex2Dlod(_AzimuthMap, float4(azimuthUV, 0.0, 0.0)).r * 2.0 * PI;

    azimuthIndex = round(phi * _AzimuthCount / (2 * PI)) % _AzimuthCount;

    float cosPhi = LutCos(phi);
    float sinPhi = LutSin(phi);
    float cosTheta = LutCos(theta);
    camUpDir = float3(-cosTheta * sinPhi, LutSin(theta), -cosTheta * cosPhi);
    camRightDir = float3(-cosPhi, 0.0, sinPhi);

#else

    float theta = acos(-camFrontDir.y);
    float phi;

    if(abs(theta) < EPSILON) phi = atan2(camUpDir.x, camUpDir.z);
    else if(abs(PI - theta) < EPSILON) phi = atan2(-camUpDir.x, -camUpDir.z);
    else phi = atan2(-camFrontDir.x, -camFrontDir.z);
    if(phi < 0) phi += 2.0 * PI;

    zenithIndex = round(theta * _ZenithCount / PI);
    azimuthIndex = round(phi * _AzimuthCount / (2 * PI)) % _AzimuthCount;

    float cosPhi = cos(phi);
    float sinPhi = sin(phi);
    float cosTheta = cos(theta);
    camUpDir = float3(-cosTheta * sinPhi, sin(theta), -cosTheta * cosPhi);
    camRightDir = float3(-cosPhi, 0.0, sinPhi);
    
#endif
}


Varyings SloaneShotBaseVert(Attributes input)
{
    Varyings output = (Varyings)0;
    
    UNITY_SETUP_INSTANCE_ID(input);
	UNITY_TRANSFER_INSTANCE_ID(input, output);
	UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

    float3 camRightDir;
    float3 camUpDir;
    float3 camFrontDir;
    int zenithIndex;
    int azimuthIndex;
    GetCorrectedCameraVector(camRightDir, camUpDir, camFrontDir, zenithIndex, azimuthIndex);

    float3 positionOS = float3(0.0, 0.0, 0.0);

    positionOS += input.positionOS.x * camRightDir;
    positionOS += input.positionOS.y * camUpDir;
    int currentIndex = zenithIndex * _AzimuthCount + azimuthIndex;

#ifdef _OBJECT_COORD
    output.positionOS = positionOS;
#endif

    float girdSize = 1.0 / _GridCount;
    output.uv.x = input.texcoord.x * girdSize + float(currentIndex % _GridCount) * girdSize;
    output.uv.y = input.texcoord.y * girdSize + float(currentIndex / _GridCount) * girdSize;

    output.positionWS = TransformObjectToWorld(positionOS);
    output.positionCS = TransformWorldToHClip(output.positionWS);

    output.normal = TransformObjectToWorldNormal(-camFrontDir);
    output.tangent.xyz = TransformObjectToWorldDir(camRightDir);
    output.tangent.w = input.tangent.w;

    /* output.fogFactor = ComputeFogFactor(output.positionCS.z);

    OUTPUT_LIGHTMAP_UV(input.texcoord1, unity_LightmapST, output.lightmapUV.xy);
	OUTPUT_SH(output.normal.xyz, output.lightmapUV.xyz); */

    return output;
}

half4 SloaneShotDepthOnlyFrag(Varyings input) : SV_Target
{
    float2 albedoUV = input.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
    float4 albedo = tex2D(_BaseMap, albedoUV);
    clip(albedo.a - _AlphaClip);

    return albedo;
}

half4 SloaneShotDepthNormalFrag(Varyings input) : SV_Target
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

    return albedo;
}