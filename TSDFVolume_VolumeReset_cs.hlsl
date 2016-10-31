#include "TSDFVolume.inl"
#include "TSDFVolume.hlsli"
#if TYPED_UAV
RWBuffer<float> tex_uavTSDFVol : register(u0);
RWBuffer<float> tex_uavWeightVol : register(u1);
#endif // TYPED_UAV
#if TEX3D_UAV
RWTexture3D<float> tex_uavTSDFVol : register(u0);
RWTexture3D<uint> tex_uavWeightVol : register(u1);
#endif // TEX3D_UAV

[numthreads(THREAD_X, THREAD_Y, THREAD_Z)]
void main(uint3 u3DTid : SV_DispatchThreadID)
{
    BufIdx bufIdx = BUFFER_INDEX(u3DTid);
    tex_uavTSDFVol[bufIdx] = 1.f;
    tex_uavWeightVol[bufIdx] = 0;
}