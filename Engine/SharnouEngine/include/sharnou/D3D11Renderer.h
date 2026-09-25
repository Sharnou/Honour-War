#pragma once
#include <d3d11.h>
#include <wrl/client.h>
#include <DirectXMath.h>
#include "sharnou/Win32Window.h"

namespace Sharnou {

class D3D11Renderer {
public:
    bool Initialize(const Win32Window& window);
    void BeginFrame();
    void SetCamera(const DirectX::XMMATRIX& view, const DirectX::XMMATRIX& projection);
    void RenderCube(const DirectX::XMMATRIX& world, const DirectX::XMFLOAT4& color);
    void EndFrame();

private:
    struct Vertex { DirectX::XMFLOAT3 position; };
    struct Constants {
        DirectX::XMMATRIX worldViewProjection;
        DirectX::XMFLOAT4 color;
    };

    Microsoft::WRL::ComPtr<ID3D11Device> device_;
    Microsoft::WRL::ComPtr<ID3D11DeviceContext> context_;
    Microsoft::WRL::ComPtr<IDXGISwapChain> swapChain_;
    Microsoft::WRL::ComPtr<ID3D11RenderTargetView> renderTarget_;
    Microsoft::WRL::ComPtr<ID3D11DepthStencilView> depthView_;
    Microsoft::WRL::ComPtr<ID3D11Buffer> vertexBuffer_;
    Microsoft::WRL::ComPtr<ID3D11Buffer> indexBuffer_;
    Microsoft::WRL::ComPtr<ID3D11Buffer> constantBuffer_;
    Microsoft::WRL::ComPtr<ID3D11VertexShader> vertexShader_;
    Microsoft::WRL::ComPtr<ID3D11PixelShader> pixelShader_;
    Microsoft::WRL::ComPtr<ID3D11InputLayout> inputLayout_;
    DirectX::XMMATRIX view_{};
    DirectX::XMMATRIX projection_{};
    D3D11_VIEWPORT viewport_{};
};

}
