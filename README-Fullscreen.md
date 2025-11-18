# BRILink Desktop Application

## Fullscreen Mode

The BRILink desktop application now automatically launches in **borderless fullscreen mode** when run as an executable (.exe).

### Features Added:

1. **Auto Fullscreen**: Application automatically opens in fullscreen without window borders
2. **Command Line Options**: Support for windowed mode during development
3. **Keyboard Shortcuts**: 
   - `ESC` key: Exit application
   - `F11` key: Exit application
   - `Alt + F4`: Exit application

### Launch Options:

#### Fullscreen Mode (Default)
```bash
desktop_flutter_brilnik.exe
```
Or use the batch file:
```bash
BRILink.bat
```

#### Windowed Mode (Development)
```bash
desktop_flutter_brilnik.exe --windowed
```
Or use the batch file:
```bash
BRILink-Windowed.bat
```

### File Locations:

After building with `flutter build windows --release`, files are located in:
```
build/windows/x64/runner/Release/
├── desktop_flutter_brilnik.exe    # Main executable
├── BRILink.bat                    # Fullscreen launcher
├── BRILink-Windowed.bat          # Windowed launcher
└── [other Flutter runtime files]
```

### Technical Implementation:

- **Modified Files**:
  - `windows/runner/main.cpp`: Added fullscreen initialization
  - `windows/runner/flutter_window.h`: Added `EnableFullscreen()` method
  - `windows/runner/flutter_window.cpp`: Implemented fullscreen functionality with keyboard shortcuts

- **Features**:
  - Borderless fullscreen window
  - Screen dimension detection
  - Window style modification to remove borders and title bar
  - Command line argument parsing for windowed mode
  - Keyboard shortcut handling

### Build Commands:

```bash
# Build release version with fullscreen support
flutter build windows --release

# Run in development mode (windowed)
flutter run -d windows

# Test built executable
cd build/windows/x64/runner/Release
./desktop_flutter_brilnik.exe
```

### Distribution:

For end users, distribute the entire `Release` folder contents, and users can simply double-click `BRILink.bat` to launch in fullscreen mode.
