#include "sharnou/Engine.h"
#include <string>
#include <windows.h>

static bool SharnouIdeSessionActive() {
    wchar_t value[8]{};
    const DWORD length = GetEnvironmentVariableW(L"SHARNOU_IDE_SESSION", value, static_cast<DWORD>(sizeof(value) / sizeof(value[0])));
    return length == 1 && value[0] == L'1';
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR commandLine, int) {
    const std::wstring args = commandLine ? commandLine : L"";

    if (args.find(L"--self-test") != std::wstring::npos) {
        Sharnou::HonourWarGame game;
        return game.Initialize() && game.RunSelfTest() ? 0 : 2;
    }

    if (args.find(L"--runtime-test") != std::wstring::npos) {
        Sharnou::HonourWarGame game;
        return game.Initialize() && game.RunRuntimeSoak(300) ? 0 : 3;
    }

    // Honour War's normal game runtime is IDE-authoritative.
    // The Sharnou IDE launcher sets SHARNOU_IDE_SESSION=1.
    // Direct executable launches are rejected so the project cannot silently
    // fall back to another IDE or editor workflow.
    if (!SharnouIdeSessionActive()) {
        MessageBoxW(nullptr,
                    L"Honour War runtime is controlled by Sharnou IDE. Launch the game through Tools\\SharnouIDE\\SharnouIDE.ps1 -Command run.",
                    L"Sharnou IDE enforcement",
                    MB_ICONERROR | MB_OK);
        return 4;
    }

    Sharnou::Engine engine;
    return engine.Initialize() ? engine.Run() : 1;
}
