#if TEX3D_UAV
#define BUFFER_INDEX(idx) idx
#define BufIdx uint3
#else
#define BUFFER_INDEX(idx) flatIDX(idx)
#define BufIdx uint
#endif

uint flatIDX(uint3 idx)
{
    return idx.x + idx.y * vParam.u3VoxelReso.x +
        idx.z * vParam.u3VoxelReso.x * vParam.u3VoxelReso.y;
}

uint3 makeU3Idx(uint idx, uint3 res)
{
    uint stripCount = res.x * res.y;
    uint stripRemainder = idx % stripCount;
    uint z = idx / stripCount;
    uint y = stripRemainder / res.x;
    uint x = stripRemainder % res.x;
    return uint3(x, y, z);
}

uint PackedToUint(uint3 xyz)
{
    return(xyz.z | ((xyz.y) << 10) | ((xyz.x) << 20));
}

uint3 UnpackedToUint3(uint x)
{
    uint3 xyz;
    xyz.z = x & 0x000003ff;
    xyz.y = (x >> 10) & 0x000003ff;
    xyz.x = (x >> 20) & 0x000003ff;
    return xyz;
}

#if META_BALL
float GetSDF(float3 f3Pos)
{
    float fSDF = 0.f;
    // Update voxel based on its position
    for (uint i = 0; i < uNumOfBalls; i++) {
        fSDF += exp((length(f4Balls[i].xyz - f3Pos) - f4Balls[i].w) *
            -vParam.fSmoothParam);
    }
    return -log(fSDF) / vParam.fSmoothParam;
}
#else
float GetSDF(float3 f3Pos)
{
    float fSDF = 1e15;
    // Update voxel based on its position
    for (uint i = 0; i < uNumOfBalls; i++) {
        fSDF = min(fSDF, length(f4Balls[i].xyz - f3Pos) - f4Balls[i].w);
    }
    return fSDF;
}
#endif