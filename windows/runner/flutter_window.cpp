#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

void FlutterWindow::EnableFullscreen() {
  HWND hwnd = GetHandle();
  if (hwnd) {
    // Get current window style
    LONG style = GetWindowLong(hwnd, GWL_STYLE);
    
    // Remove border, title bar, and other decorations
    style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
    
    // Set the new style
    SetWindowLong(hwnd, GWL_STYLE, style);
    
    // Get screen dimensions
    int screenWidth = GetSystemMetrics(SM_CXSCREEN);
    int screenHeight = GetSystemMetrics(SM_CYSCREEN);
    
    // Position and size the window to cover the entire screen
    SetWindowPos(hwnd, HWND_TOP, 0, 0, screenWidth, screenHeight, 
                 SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    
    // Show maximized
    ShowWindow(hwnd, SW_MAXIMIZE);
  }
}

void FlutterWindow::DisableFullscreen() {
  HWND hwnd = GetHandle();
  if (hwnd) {
    // Get current window style
    LONG style = GetWindowLong(hwnd, GWL_STYLE);
    
    // Restore border, title bar, and other decorations
    style |= (WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
    
    // Set the new style
    SetWindowLong(hwnd, GWL_STYLE, style);
    
    // Set window to normal size (1280x720)
    int windowWidth = 1280;
    int windowHeight = 720;
    int posX = 100;
    int posY = 100;
    
    // Position and size the window
    SetWindowPos(hwnd, HWND_TOP, posX, posY, windowWidth, windowHeight, 
                 SWP_NOZORDER | SWP_NOACTIVATE | SWP_FRAMECHANGED);
    
    // Show as normal window
    ShowWindow(hwnd, SW_NORMAL);
  }
}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // Setup method channel for fullscreen control
  flutter::MethodChannel<> channel(
      flutter_controller_->engine()->messenger(), 
      "desktop_flutter_brilnik/fullscreen",
      &flutter::StandardMethodCodec::GetInstance());
  
  channel.SetMethodCallHandler(
      [this](const flutter::MethodCall<>& call,
             std::unique_ptr<flutter::MethodResult<>> result) {
        if (call.method_name() == "enableFullscreen") {
          this->EnableFullscreen();
          result->Success();
        } else if (call.method_name() == "disableFullscreen") {
          this->DisableFullscreen();
          result->Success();
        } else {
          result->NotImplemented();
        }
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_KEYDOWN:
      // Handle F11 key to toggle fullscreen (for testing/debugging)
      if (wparam == VK_F11) {
        // For now, just close the app when F11 is pressed (can be modified later)
        PostQuitMessage(0);
        return 0;
      }
      // Handle Alt+F4 or Escape to close
      if (wparam == VK_ESCAPE || (wparam == VK_F4 && (GetKeyState(VK_MENU) & 0x8000))) {
        PostQuitMessage(0);
        return 0;
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
