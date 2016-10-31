#include "pch.h"
#include "TSDFVolume.h"

_Use_decl_annotations_
int WINAPI WinMain(_In_ HINSTANCE hInstance, _In_opt_ HINSTANCE hPrevInstance,
    _In_ LPSTR lpCmdLine, _In_ int nShowCmd)
{
    TSDFVolume application;
    return Core::Run(application, hInstance, nShowCmd);
}