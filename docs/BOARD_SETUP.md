# Tang Nano 9K/20K Board Setup (Hardware-first)

This repo supports both **Tang Nano 9K** and **Tang Nano 20K**. The main source of confusion for beginners is that *the same HDL* often needs **different device/constraints/reset polarity** depending on the board.

## Choose your board

- Tang Nano **9K**
  - Device: `GW1NR-9C`
  - Clock pin and LED pins differ from 20K (see each day's `.cst`)
- Tang Nano **20K**
  - Device: `GW2AR-18C`

Most completed projects accept:

```bash
make BOARD=9k   # default
make BOARD=20k
```

## Required tools

- Gowin EDA
  - `gw_sh` (batch build)
  - `programmer_cli` (download/program)
- Optional but useful
  - `gtkwave` (waveform viewer)
  - `verilator` (lint, where supported)

### Tool paths on macOS

Some Makefiles default to tools on `PATH` (e.g., `gw_sh`). If you installed Gowin EDA as an app bundle, you may need to provide explicit paths:

```bash
make GWSH=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh \
     PRG=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli \
     download
```

## What “success” looks like (Day 01)

Day 01 (LED blink) is your hardware sanity check:

- Build succeeds (no synth/pnr errors)
- Download succeeds (programmer sees device and writes SRAM)
- LED blinks at a visible rate

If Day 01 is unstable, fix this before moving on; later days build on the same toolchain + board setup.
