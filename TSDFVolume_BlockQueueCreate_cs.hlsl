#include "TSDFVolume.inl"
#include "TSDFVolume.hlsli"

RWStructuredBuffer<uint> buf_uavWork : register(u0);

//------------------------------------------------------------------------------
// Compute Shader
//------------------------------------------------------------------------------
[numthreads(THREAD_X, THREAD_Y, THREAD_Z)]
void main(uint3 u3DTid: SV_DispatchThreadID)
{
    if (any(u3DTid >= vParam.u3VoxelReso / vParam.uVoxelBlockRatio)) {
        return;
    }
    // Current block pos in local space
    float3 f3Pos = (u3DTid * vParam.uVoxelBlockRatio -
        vParam.f3HalfVoxelReso) * vParam.fVoxelSize + 0.5f * vParam.fBlockSize;
    float fSDF = GetSDF(f3Pos);
    if (fSDF < vParam.fBlockSize * 0.866f + vParam.fTruncDist) {
        uint uWorkIdx = buf_uavWork.IncrementCounter();
        buf_uavWork[uWorkIdx] = PackedToUint(u3DTid);
    }
}