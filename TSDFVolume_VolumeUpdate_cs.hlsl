#include "TSDFVolume.inl"
#include "TSDFVolume.hlsli"

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
void main(uint3 u3DTid: SV_DispatchThreadID)
{
    // Current voxel pos in local space
    float3 f3Pos = (u3DTid - vParam.f3HalfVoxelReso + 0.5f) * vParam.fVoxelSize;
    float fSDF = GetSDF(f3Pos);
    if (fSDF < -vParam.fTruncDist) {
        return;
    }
    // Write back to voxel 
    tex_uavTSDFVol[BUFFER_INDEX(u3DTid)] = min(fSDF / vParam.fTruncDist, 1.f);
#if ENABLE_BRICKS
    // Update brick structure
    if (fSDF < vParam.fTruncDist) {
        tex_uavFlagVol[u3DTid / vParam.uVoxelBlockRatio] = 1;
    }
#endif // ENABLE_BRICKS
}