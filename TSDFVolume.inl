#if !__hlsl
#pragma once
#endif // !__hlsl


// Params
#define MAX_BALLS 128
// The following three need to be the same
#define THREAD_X 8
#define THREAD_Y 8
#define THREAD_Z 8
#define MAX_DEPTH 10000
// Do not modify below this line

// The length of cube triangles-strip vertices
#define CUBE_TRIANGLESTRIP_LENGTH 14
// The length of cube line-strip vertices
#define CUBE_LINESTRIP_LENGTH 19

#if __hlsl
#define CBUFFER_ALIGN
#define REGISTER(x) :register(x)
#define STRUCT(x) x
#else
#define CBUFFER_ALIGN __declspec( \
    align(D3D12_CONSTANT_BUFFER_DATA_PLACEMENT_ALIGNMENT))
#define REGISTER(x)
#define STRUCT(x) struct
typedef DirectX::XMMATRIX matrix;
typedef DirectX::XMFLOAT4 float4;
typedef DirectX::XMFLOAT3 float3;
typedef DirectX::XMFLOAT2 float2;
typedef DirectX::XMUINT3 uint3;
typedef DirectX::XMUINT2 uint2;
typedef DirectX::XMINT3 int3;
typedef uint32_t uint;
#endif

// will be put into constant buffer, pay attention to alignment
struct VolumeParam {
    uint3 u3VoxelReso;
    uint uVoxelBlockRatio;
    uint2 NIU;
    uint uThreadGroupBlockRatio;
    uint uThreadGroupPerBlock;
    float3 f3HalfVoxelReso;
    float fVoxelSize;
    int3 i3ResoVector;
    float fInvVoxelSize;
    float3 f3BoxMin;
    float fBlockSize;
    float3 f3BoxMax;
    float fSmoothParam;
    float3 f3HalfVolSize;
    float fTruncDist;
};

CBUFFER_ALIGN STRUCT(cbuffer) PerFrameDataCB REGISTER(b0)
{
    matrix mWorldViewProj;
    matrix mView;
    matrix mInvView;
    float fWideHeightRatio;
    float fTanHFov;
    float fClipDist;
    float NIU;
    float4 f4ViewPos;
    float4 f4Balls[MAX_BALLS];
    float4 f4BallsCol[MAX_BALLS];
#if !__hlsl
    void* operator new(size_t i) {
        return _aligned_malloc(i, 
            D3D12_CONSTANT_BUFFER_DATA_PLACEMENT_ALIGNMENT);
    };
    void operator delete(void* p) {
        _aligned_free(p);
    }
#endif
};

CBUFFER_ALIGN STRUCT(cbuffer) PerCallDataCB REGISTER(b1)
{
    VolumeParam vParam;
    uint uNumOfBalls;
    int bBlockRayCast;
    int bInterpolatedNearSurface;
    int bMetaBall;
#if !__hlsl
    void* operator new(size_t i) {
        return _aligned_malloc(i, 
            D3D12_CONSTANT_BUFFER_DATA_PLACEMENT_ALIGNMENT);
    };
    void operator delete(void* p) {
        _aligned_free(p);
    }
#endif
};
#undef CBUFFER_ALIGN