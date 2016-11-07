#include "TSDFVolume.inl"
#include "TSDFVolume.hlsli"

#if QUAD_RAYCAST
void main(uint uVertexID : SV_VertexID, out float3 f3Pos : POSITION1,
    out float4 f4ProjPos : SV_Position)
{
    float2 f2Tex = float2(uint2(uVertexID, uVertexID << 1) & 2);
    f4ProjPos =
        float4(lerp(float2(-1.f, 1.f), float2(1.f, -1.f), f2Tex), 0, 1);
    f3Pos = float3(f4ProjPos.xy *
        float2(fWideHeightRatio * fTanHFov * fClipDist,
        fTanHFov * fClipDist), -fClipDist);
    f3Pos = mul(mInvView, float4(f3Pos, 1.f)).xyz;
}
#else
void main(in float4 f4Pos : POSITION, out float3 f3Pos : POSITION1,
    out float4 f4ProjPos : SV_POSITION)
{
    f4Pos.xyz *= (vParam.u3VoxelReso * vParam.fVoxelSize);
    f4ProjPos = mul(mWorldViewProj, f4Pos);
    f3Pos = f4Pos.xyz;
}
#endif