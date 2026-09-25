#pragma once
#include <memory>
#include "sharnou/Win32Window.h"
#include "sharnou/D3D11Renderer.h"
#include "sharnou/HonourWarGame.h"

namespace Sharnou {
class Engine {
public:
    bool Initialize();
    int Run();
private:
    void Tick(float dt);
    std::unique_ptr<Win32Window> window_;
    std::unique_ptr<D3D11Renderer> renderer_;
    std::unique_ptr<HonourWarGame> game_;
    bool running_{false};
};
}
