#pragma once
#include <windows.h>

namespace Sharnou {

class Win32Window {
public:
    Win32Window() = default;
    ~Win32Window();

    bool Create(HINSTANCE instance, const wchar_t* title, int width, int height);
    void PollEvents();
    bool ShouldClose() const { return shouldClose_; }
    HWND Handle() const { return hwnd_; }
    int Width() const { return width_; }
    int Height() const { return height_; }

    bool ConsumeLeftClick(POINT& outPoint);
    bool ConsumeRightDrag(float& dx, float& dy);
    float ConsumeWheel();
    bool ConsumeKey(unsigned int& key);

    static LRESULT CALLBACK WindowProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam);

private:
    HWND hwnd_{nullptr};
    HINSTANCE instance_{nullptr};
    int width_{1600};
    int height_{900};
    bool shouldClose_{false};
    bool leftClick_{false};
    POINT clickPoint_{};
    bool rightDragging_{false};
    POINT lastMouse_{};
    float dragDx_{0};
    float dragDy_{0};
    float wheel_{0};
    bool keyPending_{false};
    unsigned int pendingKey_{0};

    static inline Win32Window* active_{nullptr};
};

}
