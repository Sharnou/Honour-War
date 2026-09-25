#include "sharnou/Win32Window.h"

namespace Sharnou {

Win32Window::~Win32Window() {
    if (hwnd_) DestroyWindow(hwnd_);
}

bool Win32Window::Create(HINSTANCE instance, const wchar_t* title, int width, int height) {
    instance_ = instance;
    width_ = width;
    height_ = height;
    active_ = this;

    WNDCLASSEXW wc{};
    wc.cbSize = sizeof(wc);
    wc.hInstance = instance_;
    wc.lpfnWndProc = &Win32Window::WindowProc;
    wc.lpszClassName = L"SharnouEngineWindow";
    wc.hCursor = LoadCursorW(nullptr, IDC_ARROW);
    wc.hbrBackground = static_cast<HBRUSH>(GetStockObject(BLACK_BRUSH));
    if (!RegisterClassExW(&wc) && GetLastError() != ERROR_CLASS_ALREADY_EXISTS)
        return false;

    RECT rect{0,0,width_,height_};
    AdjustWindowRect(&rect, WS_OVERLAPPEDWINDOW, FALSE);
    hwnd_ = CreateWindowExW(0, wc.lpszClassName, title, WS_OVERLAPPEDWINDOW | WS_VISIBLE,
        CW_USEDEFAULT, CW_USEDEFAULT, rect.right-rect.left, rect.bottom-rect.top,
        nullptr, nullptr, instance_, nullptr);
    return hwnd_ != nullptr;
}

void Win32Window::PollEvents() {
    MSG msg{};
    while (PeekMessageW(&msg, nullptr, 0, 0, PM_REMOVE)) {
        if (msg.message == WM_QUIT) shouldClose_ = true;
        TranslateMessage(&msg);
        DispatchMessageW(&msg);
    }
}

bool Win32Window::ConsumeLeftClick(POINT& outPoint) {
    if (!leftClick_) return false;
    leftClick_ = false;
    outPoint = clickPoint_;
    return true;
}

bool Win32Window::ConsumeRightDrag(float& dx, float& dy) {
    if (!rightDragging_) return false;
    dx = dragDx_; dy = dragDy_;
    dragDx_ = dragDy_ = 0;
    return true;
}

float Win32Window::ConsumeWheel() {
    const float value = wheel_;
    wheel_ = 0;
    return value;
}

bool Win32Window::ConsumeKey(unsigned int& key) {
    if (!keyPending_) return false;
    keyPending_ = false;
    key = pendingKey_;
    return true;
}

LRESULT CALLBACK Win32Window::WindowProc(HWND hwnd, UINT msg, WPARAM wParam, LPARAM lParam) {
    if (!active_) return DefWindowProcW(hwnd, msg, wParam, lParam);
    switch (msg) {
        case WM_CLOSE: active_->shouldClose_ = true; return 0;
        case WM_DESTROY: PostQuitMessage(0); return 0;
        case WM_LBUTTONDOWN:
            active_->leftClick_=true;
            active_->clickPoint_.x=GET_X_LPARAM(lParam);
            active_->clickPoint_.y=GET_Y_LPARAM(lParam);
            return 0;
        case WM_RBUTTONDOWN:
            active_->rightDragging_=true;
            active_->lastMouse_.x=GET_X_LPARAM(lParam);
            active_->lastMouse_.y=GET_Y_LPARAM(lParam);
            SetCapture(hwnd);
            return 0;
        case WM_MOUSEMOVE:
            if (active_->rightDragging_) {
                POINT p{GET_X_LPARAM(lParam),GET_Y_LPARAM(lParam)};
                active_->dragDx_ += float(p.x-active_->lastMouse_.x);
                active_->dragDy_ += float(p.y-active_->lastMouse_.y);
                active_->lastMouse_=p;
            }
            return 0;
        case WM_RBUTTONUP:
            active_->rightDragging_=false;
            ReleaseCapture();
            return 0;
        case WM_MOUSEWHEEL:
            active_->wheel_ += float(GET_WHEEL_DELTA_WPARAM(wParam));
            return 0;
        case WM_KEYDOWN:
            active_->keyPending_=true;
            active_->pendingKey_=static_cast<unsigned int>(wParam);
            if (wParam==VK_ESCAPE) active_->shouldClose_=true;
            return 0;
        default:
            return DefWindowProcW(hwnd, msg, wParam, lParam);
    }
}

}
