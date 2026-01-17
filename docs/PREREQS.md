# 💻 Required Software

- **GoWin EDA** (FPGA synthesis and place & route tool)
- **Verilator** (SystemVerilog simulator)
- **GTKWave** (Waveform viewer)
- **cc65** (6502 assembler, used on Day 10)
- **srecord** (binary conversion tool)
- **Make** (build system)

## Installation Instructions

**macOS:**

```bash
brew update
brew install srecord cc65 golang gtkwave verilator openssl@3
```

- If you already have Homebrew, make sure it's the aarch64 version for Apple Silicon, or the Intel version for Intel CPUs.
- If there is a mismatch, reinstall Homebrew.

```bash
❯ brew --prefix
/opt/homebrew # this is Apple Silicon version (aarch64)
/usr/local # this is Intel version (x86_64)
```

**Linux (Ubuntu/Debian):**

```bash
sudo apt update
sudo apt install -y srecord cc65 golang gtkwave verilator libnss3 libnspr4 libasound2-dev
sudo apt install -y --reinstall \
  libfreetype6 \
  libfontconfig1
```

**GoWin EDA:**

- Download _Gowin V1.9.11.03 Education_ for macOS, Windows & Linux from <https://www.gowinsemi.com/ja/support/download_eda/>
  - Mac users only need macOS version of IDE which includes both compiler & programmer
  - Install macOS IDE into /Applications/GowinIDE.app
  - Windows users should install Windows version of IDE on Windows (compiler & programmer), Linux version of IDE (compiler) on WSL. WSL cannot use the programmer -> needs Windows version of it
  - Install Linux IDE into $(HOME)/Gowin/IDE
  - Install Windows IDE into c:\Gowin
- macOS only
  - First time -> fails to open
  - macOS settings -> privacy -> scroll to the bottom -> allow anytime
  - Patch command line tool

```bash
GW=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE

for f in "$GW/bin/"*; do
  if file "$f" | grep -q executable; then
    install_name_tool \
      -add_rpath @executable_path/../lib \
      -add_rpath @executable_path/../Frameworks \
      "$f" 2>/dev/null
  fi
done

for f in "$GW/bin/"*; do
  if file "$f" | grep -q executable; then
    if otool -L "$f" | grep -q '/Library/Frameworks/Tcl.framework'; then
      install_name_tool \
        -change \
        /Library/Frameworks/Tcl.framework/Versions/8.6/Tcl \
        @rpath/Tcl.framework/Versions/8.6/Tcl \
        "$f"
    fi
  fi
done
```

- WSL only

```bash
# install IDE and programmer in $HOME/Gowin
cd $HOME/Gowin/IDE/lib
mv libfreetype.so.6 libfreetype.so.6.gowin.bak

# set env var
export QT_QPA_PLATFORM=minimal
export QT_OPENGL=software
export QT_XCB_GL_INTEGRATION=none
```

## macOS Tool Paths

If you installed Gowin EDA as an app bundle and the tools (`gw_sh`, `programmer_cli`) are not in your `PATH`, you can pass them explicitly to `make`:

```bash
make GWSH=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh \
     PRG=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli \
     download
```
