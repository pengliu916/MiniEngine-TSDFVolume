#include "TSDFVolume.inl"
#include "TSDFVolume.hlsli"

#if TYPED_UAV
RWBuffer<float> tex_uavTSDFVol : register(u0);
RWBuffer<float> tex_uavWeightVol : register(u1);
#if NO_TYPED_LOAD
Buffer<float> tex_srvTSDFVol : register(t1);
Buffer<float> tex_srvWeightVol : register(t2);
#endif // NO_TYPED_LOAD
#endif // TYPED_UAV
#if TEX3D_UAV
RWTexture3D<float> tex_uavTSDFVol : register(u0);
RWTexture3D<uint> tex_uavWeightVol : register(u1);
#if NO_TYPED_LOAD
Texture3D<float> tex_srvTSDFVol : register(t1);
Texture3D<uint> tex_srvWeightVol : register(t2);
#endif // NO_TYPED_LOAD
#endif // TEX3D_UAV
#if ENABLE_BRICKS
RWTexture3D<int> tex_uavFlagVol : register(u2);
#endif // ENABLE_BRICKS

void fuseVoxel(BufIdx bufIdx, float fTSD, float fPreTSD)
{
#if NO_TYPED_LOAD
    float fPreWeight = (float)tex_srvWeightVol[bufIdx];
#else
    float fPreWeight = (float)tex_uavWeightVol[bufIdx];
#endif
    float fNewWeight = 1.f + fPreWeight;
    float fTSDF = fTSD + fPreTSD * fPreWeight;
    fTSDF = fTSDF / fNewWeight;
    tex_uavTSDFVol[bufIdx] = fTSDF;
    tex_uavWeightVol[bufIdx] = (uint)min(fNewWeight, vParam.fMaxWeight);
}

//------------------------------------------------------------------------------
// Utility Funcs
//------------------------------------------------------------------------------
float Ball(float3 f3Pos, float3 f3Center, float fRadiusSq)
{
    float3 f3d = f3Pos - f3Center;
    float fDistSq = dot(f3d, f3d);
    float fInvDistSq = 1.f / fDistSq;
    return fRadiusSq * fInvDistSq;
}


//------------------------------------------------------------------------------
// Compute Shader
//------------------------------------------------------------------------------
[numthreads(THREAD_X, THREAD_Y, THREAD_Z)]
void main(uint3 u3DTid: SV_DispatchThreadID)
{
    // Current voxel pos in local space
    float3 f3Pos = (u3DTid - vParam.f3HalfVoxelReso + 0.5f) * vParam.fVoxelSize;
    float fSDF = 1e15;
    // Update voxel based on its position
    for (uint i = 0; i < uNumOfBalls; i++) {
        fSDF = min(fSDF, length(f4Balls[i].xyz - f3Pos) - f4Balls[i].w);
    }
    if (fSDF < -vParam.fTruncDist) {
        return;
    }
    // Write back to voxel 
    tex_uavTSDFVol[BUFFER_INDEX(u3DTid)] = min(fSDF / vParam.fTruncDist, 1.f);
#if ENABLE_BRICKS
    // Update brick structure
    if (fSDF < vParam.fTruncDist) {
        tex_uavFlagVol[u3DTid / vParam.uVoxelBrickRatio] = 1;
    }
#endif // ENABLE_BRICKS
}