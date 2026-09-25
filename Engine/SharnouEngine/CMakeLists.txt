cmake_minimum_required(VERSION 3.24)
project(SharnouEngine VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
  add_compile_options(/W4 /permissive- /EHsc)
endif()

find_package(nlohmann_json CONFIG REQUIRED)

add_executable(SharnouEngine WIN32
  src/main.cpp
  src/Engine.cpp
  src/Win32Window.cpp
  src/D3D11Renderer.cpp
  src/HonourWarGame.cpp
)

target_include_directories(SharnouEngine PRIVATE include)
target_link_libraries(SharnouEngine PRIVATE
  nlohmann_json::nlohmann_json
  d3d11
  dxgi
  d3dcompiler
  user32
  gdi32
)

target_compile_definitions(SharnouEngine PRIVATE UNICODE _UNICODE NOMINMAX WIN32_LEAN_AND_MEAN)

add_custom_command(TARGET SharnouEngine POST_BUILD
  COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:SharnouEngine>/data"
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${CMAKE_SOURCE_DIR}/../../data"
          "$<TARGET_FILE_DIR:SharnouEngine>/data"
  COMMENT "Copying canonical Honour War data for Sharnou Engine runtime"
)

set_property(DIRECTORY PROPERTY VS_STARTUP_PROJECT SharnouEngine)
