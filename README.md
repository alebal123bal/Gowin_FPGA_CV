# Gowin_FPGA_CV
Computer vision hardware acceleration using Gowin Tang Primer 20k FPGA

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