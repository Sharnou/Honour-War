#include "sharnou/Engine.h"
#include <chrono>
#include <windows.h>

namespace Sharnou {

bool Engine::Initialize() {
    const auto instance=GetModuleHandleW(nullptr);
    window_=std::make_unique<Win32Window>();
    if(!window_->Create(instance,L"Honour War — Sharnou Engine",1600,900)) return false;

    renderer_=std::make_unique<D3D11Renderer>();
    if(!renderer_->Initialize(*window_)) return false;

    game_=std::make_unique<HonourWarGame>();
    if(!game_->Initialize()) return false;

    running_=true;
    return true;
}

int Engine::Run() {
    auto previous=std::chrono::steady_clock::now();
    while(running_ && !window_->ShouldClose()) {
        auto now=std::chrono::steady_clock::now();
        float dt=std::chrono::duration<float>(now-previous).count();
        previous=now;
        if(dt>0.1f) dt=0.1f;

        window_->PollEvents();
        POINT click{};
        if(window_->ConsumeLeftClick(click)) game_->OnLeftClick(click.x,click.y);
        float dx=0,dy=0;
        if(window_->ConsumeRightDrag(dx,dy)) game_->OnRightDrag(dx,dy);
        const float wheel=window_->ConsumeWheel();
        if(wheel!=0) game_->OnMouseWheel(wheel);
        unsigned int key=0;
        if(window_->ConsumeKey(key)) game_->OnKeyDown(key);

        game_->Update(dt);
        renderer_->BeginFrame();
        game_->Render(*renderer_);
        renderer_->EndFrame();
    }
    return 0;
}

}
