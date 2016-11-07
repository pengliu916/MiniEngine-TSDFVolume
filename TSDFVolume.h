#pragma once
#include "ManagedBuf.h"
#include "TSDFVolume.inl"
class TSDFVolume : public Core::IDX12Framework
{
public:
    enum VolumeStruct {
        kVoxel = 0,
        kFlagVol,
        kNumStruct
    };

    enum FilterType {
        kNoFilter = 0,
        kLinearFilter,
        kSamplerLinear,
        kNumFilter
    };

    TSDFVolume();
    ~TSDFVolume();
    virtual void OnConfiguration();
    virtual HRESULT OnCreateResource() override;
    virtual HRESULT OnSizeChanged() override;
    virtual void OnRender(CommandContext& EngineContext);
    virtual void OnDestroy() override;
    virtual void OnUpdate() override;
    virtual bool OnEvent(MSG* msg);

    float m_camOrbitRadius = 2.f;
    float m_camMaxOribtRadius = 5.f;
    float m_camMinOribtRadius = 0.2f;

    OrbitCamera m_camera;

private:
    struct Ball {
        float fPower; // size of this metaball
        float fOribtRadius; // radius of orbit
        float fOribtSpeed; // speed of rotation
        float fOribtStartPhase; // initial phase
        DirectX::XMFLOAT4 f4Color; // color
    };

    void _OnIntegrate(CommandContext& cmdCtx);
    void _OnRender(CommandContext& cmdContext, const DirectX::XMMATRIX& wvp,
        const DirectX::XMMATRIX& mView, const DirectX::XMFLOAT4& eyePos);
    void _RenderGui();
    void _CreateBrickVolume(const uint3& reso, const uint ratio);
    // Data update
    void _UpdatePerFrameData(const DirectX::XMMATRIX& wvp,
        const DirectX::XMMATRIX& mView, const DirectX::XMFLOAT4& eyePos);
    void _UpdateVolumeSettings(const uint3 reso);
    void _UpdateBlockSettings(const uint blockVoxelRatio);
    void _CleanTSDFBuffer(ComputeContext& cptCtx,
        const ManagedBuf::BufInterface& buf);
    // Render subroutine
    void _CleanBrickVolume(ComputeContext& cptCtx);
    void _UpdateBlockVolume(CommandContext& cmdCtx);
    void _UpdateVolume(CommandContext& cmdCtx,
        const ManagedBuf::BufInterface& buf);
    void _RenderVolume(GraphicsContext& gfxCtx,
        const ManagedBuf::BufInterface& buf);
    void _RenderNearFar(GraphicsContext& gfxCtx);
    void _RenderBrickGrid(GraphicsContext& gfxCtx);
    void _ResetCameraView();
    void _AddBall();

    // Volume settings currently in use
    VolumeStruct _curVolStruct = kVoxel;
    FilterType _filterType = kSamplerLinear;
    uint3 _curReso;
    // new vol reso setting sent to ManagedBuf _volBuf
    uint3 _submittedReso;

    // per instance buffer resource
    ManagedBuf _volBuf;
    VolumeTexture _flagVol;
    ColorBuffer _stepInfoTex;
    StructuredBuffer _blockWorkBuf;
    IndirectArgsBuffer _indirectParams;
    PerFrameDataCB _cbPerFrame;
    PerCallDataCB _cbPerCall;
    // point to vol data section in _cbPerCall
    VolumeParam* _volParam;

    // pointers/handlers currently available
    ManagedBuf::BufInterface _curBufInterface;

    // available ratios for current volume resolution
    std::vector<uint16_t> _ratios;
    // current selected ratio idx
    uint _ratioIdx;

    // info. to control volume update, processed by cpu
    std::vector<Ball> _ballsData;

    double _animateTime = 0.0;
    bool _isAnimated = true;
    bool _needVolumeRebuild = true;
};