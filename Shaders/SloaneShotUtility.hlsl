
#define EPSILON 0.05
#define PI 3.1415926535897932384626433832795

// 获得正确模型空间下的相机方向
// 广告牌在模型空间下操作
void GetCorrectedCameraVector(out float3 camRightDir, out float3 camUpDir, out float3 camFrontDir, out int zenithIndex, out int azimuthIndex)
{
    camFrontDir = mul(UNITY_MATRIX_I_M, float3(unity_CameraToWorld[0][2], unity_CameraToWorld[1][2], unity_CameraToWorld[2][2]));
    camFrontDir = normalize(camFrontDir);
    camUpDir = mul(UNITY_MATRIX_I_M, float3(unity_CameraToWorld[0][1], unity_CameraToWorld[1][1], unity_CameraToWorld[2][1]));
    camUpDir = normalize(camUpDir);

    float theta = acos(-camFrontDir.y);
    float phi;

    if(abs(theta) < EPSILON) phi = atan2(camUpDir.x, camUpDir.z);
    else if(abs(PI - theta) < EPSILON) phi = atan2(-camUpDir.x, -camUpDir.z);
    else phi = atan2(-camFrontDir.x, -camFrontDir.z);
    if(phi < 0) phi += 2.0 * PI;

    zenithIndex = round(theta * _ZenithCount / PI);
    azimuthIndex = round(phi * _AzimuthCount / (2 * PI)) % _AzimuthCount;

    camUpDir = float3(-cos(theta) * sin(phi), sin(theta), -cos(theta) * cos(phi));
    camRightDir = float3(-cos(phi), 0.0, sin(phi));
}

Varyings BaseVert(Attributes input)
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