#include "TSDFVolume.inl"

ByteAddressBuffer buf_srvWorkCounter : register(t0);
RWByteAddressBuffer buf_uavIndirectParams : register(u0);

//------------------------------------------------------------------------------
// Compute Shader
//------------------------------------------------------------------------------
[numthreads(1, 1, 1)]
void main(uint3 u3DTid: SV_DispatchThreadID)
{
    uint uNumThreadGroupX =
        buf_srvWorkCounter.Load(0) * vParam.uThreadGroupPerBlock;
    buf_uavIndirectParams.Store(0, uNumThreadGroupX);
}