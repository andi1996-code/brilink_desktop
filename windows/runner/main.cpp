#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  
  // Check if windowed mode is requested via command line
  bool windowedMode = false;
  for (const auto& arg : command_line_arguments) {
    if (arg == "--windowed" || arg == "-w") {
      windowedMode = true;
      break;
    }
  }
  
  // Get screen dimensions
  int screenWidth = GetSystemMetrics(SM_CXSCREEN);
  int screenHeight = GetSystemMetrics(SM_CYSCREEN);
  
  Win32Window::Point origin(windowedMode ? Win32Window::Point(100, 100) : Win32Window::Point(0, 0));
  Win32Window::Size size(windowedMode ? Win32Window::Size(1280, 720) : Win32Window::Size(screenWidth, screenHeight));
  
  if (!window.Create(L"BRILink Desktop", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);
  
  // Enable fullscreen only if not in windowed mode
  if (!windowedMode) {
    window.EnableFullscreen();
  } else {
    // Just show normally in windowed mode
    window.Show();
  }

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
