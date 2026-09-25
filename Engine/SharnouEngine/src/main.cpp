#include "sharnou/Engine.h"
#include <string>

int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR commandLine, int) {
    const std::wstring args = commandLine ? commandLine : L"";
    if (args.find(L"--self-test") != std::wstring::npos) {
        Sharnou::HonourWarGame game;
        return game.Initialize() && game.RunSelfTest() ? 0 : 2;
    }

    Sharnou::Engine engine;
    return engine.Initialize() ? engine.Run() : 1;
}
