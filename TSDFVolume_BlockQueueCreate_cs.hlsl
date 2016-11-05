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
    float fSDF = 1e15;
    // Update block based on its position
    for (uint i = 0; i < uNumOfBalls; i++) {
        fSDF = min(fSDF, abs(length(f4Balls[i].xyz - f3Pos) - f4Balls[i].w));
    }
    if (fSDF < vParam.fBlockSize * 0.866f + vParam.fTruncDist) {
        uint uWorkIdx = buf_uavWork.IncrementCounter();
        buf_uavWork[uWorkIdx] = PackedToUint(u3DTid);
    }
}