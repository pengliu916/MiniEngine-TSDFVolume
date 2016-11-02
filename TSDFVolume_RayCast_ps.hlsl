#include "TSDFVolume.inl"
#include "TSDFVolume.hlsli"

#if TYPED_UAV
Buffer<float> tex_srvTSDFVol : register(t0);
#else // TEX3D_UAV
Texture3D<float> tex_srvTSDFVol : register(t0);
#endif
#if ENABLE_BRICKS
Texture2D<float2> tex_srvNearFar : register(t1);
Texture3D<int> tex_srvFlagVol : register(t2);
#endif // ENABLE_BRICKS
SamplerState samp_Linear : register(s0);

//------------------------------------------------------------------------------
// Structures
//------------------------------------------------------------------------------
struct Ray
{
    float4 f4o;
    float4 f4d;
};

//------------------------------------------------------------------------------
// Utility Funcs
//------------------------------------------------------------------------------
bool IntersectBox(Ray r, float3 boxmin, float3 boxmax,
    out float tnear, out float tfar)
{
    // compute intersection of ray with all six bbox planes
    float3 invR = 1.0 / r.f4d.xyz;
    float3 tbot = invR * (boxmin.xyz - r.f4o.xyz);
    float3 ttop = invR * (boxmax.xyz - r.f4o.xyz);

    // re-order intersections to find smallest and largest on each axis
    float3 tmin = min(ttop, tbot);
    float3 tmax = max(ttop, tbot);

    // find the largest tmin and the smallest tmax
    float2 t0 = max(tmin.xx, tmin.yz);
    tnear = max(t0.x, t0.y);
    t0 = min(tmax.xx, tmax.yz);
    tfar = min(t0.x, t0.y);

    return tnear <= tfar;
}

float readVolume(float3 f3Idx)
{
#if FILTER_READ == 1
    int3 i3Idx000;
    float3 f3d = modf(f3Idx - 0.5f, i3Idx000);
    float res1, res2, v1, v2;
    v1 = tex_srvTSDFVol[BUFFER_INDEX(i3Idx000 + uint3(0, 0, 0))];
    v2 = tex_srvTSDFVol[BUFFER_INDEX(i3Idx000 + uint3(1, 0, 0))];
    res1 = (1.f - f3d.x) * v1 + f3d.x * v2;
    v1 = tex_srvTSDFVol[BUFFER_INDEX(i3Idx000 + uint3(0, 1, 0))];
    v2 = tex_srvTSDFVol[BUFFER_INDEX(i3Idx000 + uint3(1, 1, 0))];
    res1 = (1.f - f3d.y) * res1 + f3d.y * ((1.f - f3d.x) * v1 + f3d.x * v2);
    v1 = tex_srvTSDFVol[BUFFER_INDEX(i3Idx000 + uint3(0, 0, 1))];
    v2 = tex_srvTSDFVol[BUFFER_INDEX(i3Idx000 + uint3(1, 0, 1))];
    res2 = (1.f - f3d.x) * v1 + f3d.x * v2;
    v1 = tex_srvTSDFVol[BUFFER_INDEX(i3Idx000 + uint3(0, 1, 1))];
    v2 = tex_srvTSDFVol[BUFFER_INDEX(i3Idx000 + uint3(1, 1, 1))];
    res2 = (1.f - f3d.y) * res2 + f3d.y * ((1.f - f3d.x) * v1 + f3d.x * v2);
    return (1.f - f3d.z) * res1 + f3d.z * res2;
#elif TEX3D_UAV && FILTER_READ > 1
    return tex_srvTSDFVol.SampleLevel(
        samp_Linear, f3Idx / vParam.u3VoxelReso, 0);
#else
    int3 i3Idx000;
    modf(f3Idx, i3Idx000);
    return tex_srvTSDFVol[BUFFER_INDEX(i3Idx000)];
#endif // !FILTER_READ
}

float3 getNormal(float3 f3Idx)
{
    float f000 = readVolume(f3Idx);
    float f100 = readVolume(f3Idx + float3(1.f, 0.f, 0.f));
    float f010 = readVolume(f3Idx + float3(0.f, 1.f, 0.f));
    float f001 = readVolume(f3Idx + float3(0.f, 0.f, 1.f));
    return normalize(float3(f100 - f000, f010 - f000, f001 - f000));
}

void isoSurfaceShading(Ray eyeray, float2 f2NearFar,
    inout float4 f4OutColor, inout float fDepth)
{
    float3 f3Idx = eyeray.f4o.xyz + eyeray.f4d.xyz * f2NearFar.x;
    f3Idx = f3Idx * vParam.fInvVoxelSize + vParam.f3HalfVoxelReso;
    float t = f2NearFar.x;
    float fDeltaT = vParam.fVoxelSize;
    // f3IdxStep = eyeray.f4d.xyz * fDeltaT / fVoxelSize
    float3 f3IdxStep = eyeray.f4d.xyz;
    bool bSurfaceFound = false;

    int3 i3NewBlockIdx, i3BlockIdx = int3(-1, -1, -1);
    bool bActiveBlock = true;

    float3 f3PreIdx = f3Idx;
    float fPreTSDF, fCurTSDF = 1e15;

    while (t <= f2NearFar.y) {
#if ENABLE_BRICKS
        if (bBlockRayCast) {
            modf(f3Idx / vParam.uVoxelBrickRatio, i3NewBlockIdx);
            if (any(i3BlockIdx != i3NewBlockIdx)) {
                i3BlockIdx = i3NewBlockIdx;
                bActiveBlock = tex_srvFlagVol[i3BlockIdx];
            }
            if (!bActiveBlock) {
                float3 f3Offset =
                    i3BlockIdx * vParam.fBlockSize - vParam.f3HalfVolSize;
                float2 f2BlockNearFar;
                IntersectBox(eyeray, f3Offset, f3Offset + vParam.fBlockSize,
                    f2BlockNearFar.x, f2BlockNearFar.y);
                t = max(t + fDeltaT, f2BlockNearFar.y + fDeltaT);
                f3Idx = eyeray.f4o.xyz + eyeray.f4d.xyz * t;
                f3Idx = f3Idx * vParam.fInvVoxelSize + vParam.f3HalfVoxelReso;
                continue;
            }
        }
#endif
        fPreTSDF = fCurTSDF;
        fCurTSDF = readVolume(f3Idx) * vParam.fTruncDist;
        if (fCurTSDF < 0) {
            bSurfaceFound = true;
            break;
        }
        f3PreIdx = f3Idx;
        f3Idx += f3IdxStep;
        t += fDeltaT;
    }

    if (!bSurfaceFound) {
        return;
    }

    float3 f3SurfPos = lerp(f3PreIdx, f3Idx, fPreTSDF / (fPreTSDF- fCurTSDF));
    f3SurfPos = (f3SurfPos - vParam.f3HalfVoxelReso) * vParam.fVoxelSize;
    float4 f4ProjPos = mul(mWorldViewProj, float4(f3SurfPos, 1.f));
    fDepth = f4ProjPos.z / f4ProjPos.w;
    float3 f3Normal = getNormal(
        f3SurfPos * vParam.fInvVoxelSize + vParam.f3HalfVoxelReso);
    f4OutColor = float4(f3Normal * 0.5f + 0.5f, 1);
    return;
}

//------------------------------------------------------------------------------
// Pixel Shader
//------------------------------------------------------------------------------
void main( float4 f4Pos : POSITION, float4 f4ProjPos : SV_POSITION,
    out float4 f4Col : SV_Target, out float fDepth : SV_Depth)
{
    Ray eyeray;
    //world space
    eyeray.f4o = f4ViewPos;
    eyeray.f4d = f4Pos - eyeray.f4o;
    eyeray.f4d = normalize( eyeray.f4d );

    // calculate ray intersection with bounding box
    float fTnear, fTfar; 
#if ENABLE_BRICKS
    int2 uv = f4ProjPos.xy;
    float2 f2NearFar =
        tex_srvNearFar.Load(int3(uv, 0)).xy / length(eyeray.f4d.xyz);
    fTnear = f2NearFar.x;
    fTfar = -f2NearFar.y;
    bool bHit = (fTfar - fTnear) > 0;
#else
    bool bHit =
        IntersectBox(eyeray, vParam.f3BoxMin, vParam.f3BoxMax , fTnear, fTfar);
#endif // ENABLE_BRICKS
    f4Col = float4(1.f, 1.f, 1.f, 0.f) * 0.2f;
    fDepth = 0.f;
    if (!bHit) {
        discard;
        return;
    }
    if (fTnear <= 0) {
        fTnear = 0;
    }
    isoSurfaceShading(eyeray, float2(fTnear, fTfar), f4Col, fDepth);
    return;
}