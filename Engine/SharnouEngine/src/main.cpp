#include "sharnou/Engine.h"
int WINAPI wWinMain(HINSTANCE instance, HINSTANCE, PWSTR, int) {
    Sharnou::Engine engine;
    return engine.Initialize() ? engine.Run() : 1;
}
