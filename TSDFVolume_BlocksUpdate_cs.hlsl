#include "TSDFVolume.inl"
#include "TSDFVolume.hlsli"

StructuredBuffer<uint> buf_srvWork : register(t0);

#if TYPED_UAV
RWBuffer<float> tex_uavTSDFVol : register(u0);
#endif // TYPED_UAV
#if TEX3D_UAV
RWTexture3D<float> tex_uavTSDFVol : register(u0);
#endif // TEX3D_UAV
#if ENABLE_BRICKS
RWTexture3D<int> tex_uavFlagVol : register(u2);
#endif // ENABLE_BRICKS

//------------------------------------------------------------------------------
// Compute Shader
//------------------------------------------------------------------------------
[numthreads(THREAD_X, THREAD_Y, THREAD_Z)]
void main(uint3 GI : SV_GroupID, uint3 GTid : SV_GroupThreadID)
{
    uint uWorkQueueIdx = GI.x / vParam.uThreadGroupPerBlock;
    uint uThreadGroupIdxInBlock = GI.x % vParam.uThreadGroupPerBlock;
    uint3 u3ThreadGroupIdxInBlock;
    u3ThreadGroupIdxInBlock.z = uThreadGroupIdxInBlock /
        (vParam.uThreadGroupBlockRatio * vParam.uThreadGroupBlockRatio);
    uint uRemainder = uThreadGroupIdxInBlock %
        (vParam.uThreadGroupBlockRatio * vParam.uThreadGroupBlockRatio);
    u3ThreadGroupIdxInBlock.y = uRemainder / vParam.uThreadGroupBlockRatio;
    u3ThreadGroupIdxInBlock.x = uRemainder % vParam.uThreadGroupBlockRatio;
    uint3 u3BlockIdx = UnpackedToUint3(buf_srvWork[uWorkQueueIdx]);
    uint3 u3VolumeIdx = u3BlockIdx * vParam.uVoxelBlockRatio +
        u3ThreadGroupIdxInBlock * THREAD_X + GTid;
    // Current voxel pos in local space
    float3 f3Pos =
        (u3VolumeIdx - vParam.f3HalfVoxelReso + 0.5f) * vParam.fVoxelSize;
    float fSDF = GetSDF(f3Pos);
    if (fSDF < -vParam.fTruncDist) {
        return;
    }
    // Write back to voxel 
    tex_uavTSDFVol[BUFFER_INDEX(u3VolumeIdx)] =
        min(fSDF / vParam.fTruncDist, 1.f);
#if ENABLE_BRICKS
    // Update brick structure
    if (fSDF < vParam.fTruncDist) {
        tex_uavFlagVol[u3BlockIdx] = 1;
    }
#endif // ENABLE_BRICKS
}