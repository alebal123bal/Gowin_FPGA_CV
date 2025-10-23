# Gowin_FPGA_CV

## Project Overview
This project implements a high-performance camera streaming system using the Gowin Tang Primer 20k FPGA. The system captures video from an OV5640 camera module and provides dual output streams:

- **HDMI Output**: Real-time video display on external monitors/TVs
- **USB 2.0 High-Speed Streaming**: Up to 40 MB/s data transfer to PC

### Current Capabilities
- **Camera**: OV5640 sensor capturing 640×480 resolution at 51.45 FPS
- **Video Format**: RGB565 color encoding
- **HDMI Display**: Real-time video output with TMDS encoding
- **USB Streaming**: High-speed bulk transfer mode achieving up to 40 MB/s throughput
- **Frame Synchronization**: Precise timing control with vsync-based frame boundary detection
- **DDR3 Buffer**: Triple frame buffering for smooth video processing

## Demo Video

<video width="640" height="480" controls>
  <source src="images/StreamerDemo_lite.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

*Demo showing the FPGA streaming video simultaneously to both PC (via USB) and Television (via HDMI)*

**Note**: If the video doesn't play above, you can [download it here](images/StreamerDemo_lite.mp4) to view locally.

## System Screenshots

### USB Device Recognition
![Device Manager](images/DeviceManager_working.png)

*Windows Device Manager showing the FPGA recognized as a USB 2.0 high-speed device*

### Signal Analysis
![PulseView Signals](images/PulseView_signals.png)

*Logic analyzer capture showing camera timing signals and USB communication*

## Technical Specifications

### Hardware Platform
- **FPGA**: Gowin Tang Primer 20k (GW2A-LV18PG256C8/I7)
- **Camera**: OV5640 sensor module
- **Memory**: DDR3 interface for frame buffering
- **USB**: USB 3317 ULPI PHY for USB 2.0 high-speed communication
- **Display**: HDMI output via TMDS encoding

### Performance Metrics
- **Video Resolution**: 640×480 pixels
- **Frame Rate**: 51.45 FPS
- **Color Depth**: 16-bit RGB565
- **USB Throughput**: Up to 40 MB/s (320 Mbps)
- **USB Mode**: High-speed bulk transfer (480 Mbps theoretical)
- **Latency**: Real-time processing with triple frame buffering

### Key Features
- Dual simultaneous video output (HDMI + USB)
- Frame-synchronized data streaming
- Automatic USB enumeration and configuration
- Real-time video processing pipeline
- FIFO-based data buffering with flow control
- Configurable frame boundary markers

## Development Setup

# VSC Extensions Needed
- eirikpre.systemverilog
  - Install: In VS Code, go to Extensions, search “SystemVerilog (eirikpre)”, install.
  - Enable format-on-save:
    - File → Preferences → Settings → search “format on save” → check “Editor: Format On Save”.
  - Set as default formatter for Verilog/SystemVerilog:
    - Open settings.json and add:
      {
        "[verilog]": {
          "editor.defaultFormatter": "eirikpre.systemverilog",
          "editor.formatOnSave": true
        },
        "[systemverilog]": {
          "editor.defaultFormatter": "eirikpre.systemverilog",
          "editor.formatOnSave": true
        }
      }

# Programs Needed
- verible-verilog-format and verible-verilog-lint (optional but recommended)
  - Download a Verible release for Windows (zip) and extract, e.g. to C:\verible.
  - Point the formatter to the absolute path (avoids PATH dependency):
    - In settings.json:
      "systemverilog.formatCommand": "C:/verible/verible-verilog-format.exe --line_terminator=LF --column_limit=500 --indentation_spaces=2 --assignment_statement_alignment=flush-left --case_items_alignment=flush-left --class_member_variable_alignment=flush-left --distribution_items_alignment=flush-left --enum_assignment_statement_alignment=flush-left --formal_parameters_alignment=flush-left --module_net_variable_alignment=flush-left --named_parameter_alignment=flush-left --named_port_alignment=flush-left --port_declarations_alignment=flush-left --struct_union_members_alignment=flush-left --try_wrap_long_lines=false --wrap_end_else_clauses=false"
  - Linting (optional): If you want lint diagnostics in VS Code, either:
    - Add C:\verible to PATH (see below), or
    - Configure the extension’s Verible Lint command explicitly (key name may vary by version), e.g.:
      "systemverilog.launchConfigurationVeribleLint": "C:/verible/verible-verilog-lint.exe --check_syntax --lint_fatal --parse_fatal --show_diagnostic_context --ruleset=default"

- Add C:\verible (or your Verible bin folder) to PATH environment variable
  - Windows: Win + R → sysdm.cpl → Advanced → Environment Variables…
  - Under “System variables” → Path → Edit → New → C:\verible → OK.
  - Close and reopen VS Code and terminals so they see the new PATH.
  - Verify in a new terminal:
    - verible-verilog-format --version
    - verible-verilog-lint --version

- Microsoft Visual C++ Redistributable (both x64 and x86)
  - Install the latest “Microsoft Visual C++ Redistributable” packages for x64 and x86 from Microsoft’s website.
  - These are required to run the prebuilt Verible executables.

# Recommendations
- Line endings: set LF
  - In VS Code, bottom-right selector → choose LF.
  - Optionally enforce in settings:
    - "files.eol": "\n",
    - "files.insertFinalNewline": true
  - Note: verible-verilog-format can force LF with --line_terminator=LF, but aligning the editor/repo prevents mixed line endings and avoids churn.