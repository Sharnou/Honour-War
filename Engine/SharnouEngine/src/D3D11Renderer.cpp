#include "sharnou/D3D11Renderer.h"
#include <d3dcompiler.h>
#include <cstring>

using namespace DirectX;
using Microsoft::WRL::ComPtr;

namespace Sharnou {

static const char* kVS = R"(
cbuffer Constants : register(b0) {
    matrix worldViewProjection;
    float4 color;
};
struct VSIn { float3 position : POSITION; };
struct VSOut { float4 position : SV_POSITION; };
VSOut main(VSIn input) {
    VSOut output;
    output.position = mul(float4(input.position,1), worldViewProjection);
    return output;
})";

static const char* kPS = R"(
cbuffer Constants : register(b0) {
    matrix worldViewProjection;
    float4 color;
};
float4 main() : SV_TARGET { return color; })";

bool D3D11Renderer::Initialize(const Win32Window& window) {
    DXGI_SWAP_CHAIN_DESC scd{};
    scd.BufferCount = 2;
    scd.BufferDesc.Width = window.Width();
    scd.BufferDesc.Height = window.Height();
    scd.BufferDesc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    scd.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    scd.OutputWindow = window.Handle();
    scd.SampleDesc.Count = 1;
    scd.Windowed = TRUE;
    scd.SwapEffect = DXGI_SWAP_EFFECT_DISCARD;

    UINT flags = D3D11_CREATE_DEVICE_BGRA_SUPPORT;
#ifdef _DEBUG
    flags |= D3D11_CREATE_DEVICE_DEBUG;
#endif
    D3D_FEATURE_LEVEL levels[] = {D3D_FEATURE_LEVEL_11_1, D3D_FEATURE_LEVEL_11_0};
    D3D_FEATURE_LEVEL actual{};
    if (FAILED(D3D11CreateDeviceAndSwapChain(nullptr, D3D_DRIVER_TYPE_HARDWARE, nullptr, flags,
        levels, 2, D3D11_SDK_VERSION, &scd, swapChain_.GetAddressOf(), device_.GetAddressOf(),
        &actual, context_.GetAddressOf()))) return false;

    ComPtr<ID3D11Texture2D> backBuffer;
    if (FAILED(swapChain_->GetBuffer(0, IID_PPV_ARGS(backBuffer.GetAddressOf())))) return false;
    if (FAILED(device_->CreateRenderTargetView(backBuffer.Get(), nullptr, renderTarget_.GetAddressOf()))) return false;

    D3D11_TEXTURE2D_DESC depthDesc{};
    depthDesc.Width = window.Width(); depthDesc.Height = window.Height();
    depthDesc.MipLevels = 1; depthDesc.ArraySize = 1; depthDesc.Format = DXGI_FORMAT_D24_UNORM_S8_UINT;
    depthDesc.SampleDesc.Count = 1; depthDesc.Usage = D3D11_USAGE_DEFAULT; depthDesc.BindFlags = D3D11_BIND_DEPTH_STENCIL;
    ComPtr<ID3D11Texture2D> depthTexture;
    if (FAILED(device_->CreateTexture2D(&depthDesc, nullptr, depthTexture.GetAddressOf()))) return false;
    if (FAILED(device_->CreateDepthStencilView(depthTexture.Get(), nullptr, depthView_.GetAddressOf()))) return false;

    ComPtr<ID3DBlob> vsBlob, psBlob, errors;
    if (FAILED(D3DCompile(kVS, strlen(kVS), "SharnouVS", nullptr, nullptr, "main", "vs_5_0", 0, 0, vsBlob.GetAddressOf(), errors.GetAddressOf()))) return false;
    if (FAILED(D3DCompile(kPS, strlen(kPS), "SharnouPS", nullptr, nullptr, "main", "ps_5_0", 0, 0, psBlob.GetAddressOf(), errors.GetAddressOf()))) return false;
    if (FAILED(device_->CreateVertexShader(vsBlob->GetBufferPointer(), vsBlob->GetBufferSize(), nullptr, vertexShader_.GetAddressOf()))) return false;
    if (FAILED(device_->CreatePixelShader(psBlob->GetBufferPointer(), psBlob->GetBufferSize(), nullptr, pixelShader_.GetAddressOf()))) return false;

    D3D11_INPUT_ELEMENT_DESC layout[] = {{"POSITION",0,DXGI_FORMAT_R32G32B32_FLOAT,0,0,D3D11_INPUT_PER_VERTEX_DATA,0}};
    if (FAILED(device_->CreateInputLayout(layout,1,vsBlob->GetBufferPointer(),vsBlob->GetBufferSize(),inputLayout_.GetAddressOf()))) return false;

    const Vertex cube[] = {{{-1,-1,-1}},{{-1,1,-1}},{{1,1,-1}},{{1,-1,-1}},{{-1,-1,1}},{{-1,1,1}},{{1,1,1}},{{1,-1,1}}};
    const unsigned short indices[] = {0,1,2,0,2,3,4,6,5,4,7,6,0,4,5,0,5,1,3,2,6,3,6,7,1,5,6,1,6,2,0,3,7,0,7,4};

    D3D11_BUFFER_DESC vbDesc{}; vbDesc.ByteWidth=sizeof(cube); vbDesc.Usage=D3D11_USAGE_IMMUTABLE; vbDesc.BindFlags=D3D11_BIND_VERTEX_BUFFER;
    D3D11_SUBRESOURCE_DATA vbData{cube,0,0};
    if (FAILED(device_->CreateBuffer(&vbDesc,&vbData,vertexBuffer_.GetAddressOf()))) return false;

    D3D11_BUFFER_DESC ibDesc{}; ibDesc.ByteWidth=sizeof(indices); ibDesc.Usage=D3D11_USAGE_IMMUTABLE; ibDesc.BindFlags=D3D11_BIND_INDEX_BUFFER;
    D3D11_SUBRESOURCE_DATA ibData{indices,0,0};
    if (FAILED(device_->CreateBuffer(&ibDesc,&ibData,indexBuffer_.GetAddressOf()))) return false;

    D3D11_BUFFER_DESC cbDesc{}; cbDesc.ByteWidth=sizeof(Constants); cbDesc.Usage=D3D11_USAGE_DEFAULT; cbDesc.BindFlags=D3D11_BIND_CONSTANT_BUFFER;
    if (FAILED(device_->CreateBuffer(&cbDesc,nullptr,constantBuffer_.GetAddressOf()))) return false;

    viewport_.Width=float(window.Width()); viewport_.Height=float(window.Height()); viewport_.MinDepth=0; viewport_.MaxDepth=1;
    projection_=XMMatrixPerspectiveFovLH(XMConvertToRadians(60.0f),float(window.Width())/float(window.Height()),0.1f,1000.0f);
    view_=XMMatrixLookAtLH(XMVectorSet(0,8,-18,1),XMVectorZero(),XMVectorSet(0,1,0,0));
    return true;
}

void D3D11Renderer::BeginFrame() {
    const float clear[]={0.01f,0.015f,0.025f,1.0f};
    context_->ClearRenderTargetView(renderTarget_.Get(),clear);
    context_->ClearDepthStencilView(depthView_.Get(),D3D11_CLEAR_DEPTH|D3D11_CLEAR_STENCIL,1,0);
    ID3D11RenderTargetView* rt[]={renderTarget_.Get()};
    context_->OMSetRenderTargets(1,rt,depthView_.Get());
    context_->RSSetViewports(1,&viewport_);
    UINT stride=sizeof(Vertex),offset=0;
    context_->IASetVertexBuffers(0,1,vertexBuffer_.GetAddressOf(),&stride,&offset);
    context_->IASetIndexBuffer(indexBuffer_.Get(),DXGI_FORMAT_R16_UINT,0);
    context_->IASetInputLayout(inputLayout_.Get());
    context_->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);
    context_->VSSetShader(vertexShader_.Get(),nullptr,0);
    context_->PSSetShader(pixelShader_.Get(),nullptr,0);
}

void D3D11Renderer::SetCamera(const XMMATRIX& view, const XMMATRIX& projection) { view_=view; projection_=projection; }

void D3D11Renderer::RenderCube(const XMMATRIX& world, const XMFLOAT4& color) {
    Constants c{XMMatrixTranspose(world*view_*projection_),color};
    context_->UpdateSubresource(constantBuffer_.Get(),0,nullptr,&c,0,0);
    context_->VSSetConstantBuffers(0,1,constantBuffer_.GetAddressOf());
    context_->PSSetConstantBuffers(0,1,constantBuffer_.GetAddressOf());
    context_->DrawIndexed(36,0,0);
}

void D3D11Renderer::EndFrame() { swapChain_->Present(1,0); }

}
