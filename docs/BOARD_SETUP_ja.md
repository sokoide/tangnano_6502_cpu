# 🔌 ボード設定と環境構築 (Tang Nano 9K / 20K)

---

🌐 対応言語:
[English](./BOARD_SETUP.md) | [日本語](./BOARD_SETUP_ja.md)

## 概要

本リポジトリのカリキュラムは、Sipeed 社の **Tang Nano 9K** および **Tang Nano 20K** FPGA ボードに対応しています。
両ボードは搭載されている FPGA デバイスやリセットボタンの極性、クロック設定に違いがあります。本書では、両ボードの差異と設定方法をまとめます。

---

## 1. ボード仕様比較

| 項目 | Tang Nano 9K | Tang Nano 20K |
| :--- | :--- | :--- |
| **FPGA デバイス** | Gowin GW1NR-9C (`GW1NR-LV9QN88PC6/I5`) | Gowin GW2AR-18C (`GW2AR-LV18QN88PC8/I7`) |
| **LUT (論理セル)** | 8,640 | 20,736 |
| **内蔵 BSRAM** | 468 Kbits (26 Block RAMs) | 828 Kbits (46 Block RAMs) |
| **オンボード水晶振動子** | 27 MHz | 27 MHz |
| **リセットボタン極性** | **Active-High** (押すと High) | **Active-Low** (押すと Low) |
| **RTL内リセット結線** | `rst_n = ResetButton;` | `rst_n = !ResetButton;` |
| **トップレベル制約** | `tang_nano_9k.cst` | `tang_nano_20k.cst` |
| **ビルド指定** | `make BOARD=9k` (デフォルト) | `make BOARD=20k` |

---

## 2. リセットボタンの極性

FPGA の内部ロジックでは通常 **Active-Low リセット (`rst_n`)**（0 でリセット、1 で通常動作）を使用します。

- **Tang Nano 9K**:
  - オンボードの `ResetButton`（S1）はプルダウンされており、ボタンを押すと `1` (High)、離すと `0` (Low) が入力されます。
  - そのため、Active-Low の `rst_n` として使うにはそのまま `rst_n = ResetButton;`（またはプルアップ直結時の極性に合わせる）と配線します。
- **Tang Nano 20K**:
  - オンボードの `ResetButton`（S1）はプルアップされており、ボタンを押すと `0` (Low)、離すと `1` (High) が入力されます。
  - そのため、`rst_n = !ResetButton;` のように論理を反転して内部リセット信号を生成します。

---

## 3. クロックツリーと周波数

### オンボード発振器

両ボードとも、ベースクロックとして **27MHz** の水晶発振器が供給されます。

### LCD ピクセルクロック (9MHz)

480×272 解像度（リフレッシュレート約 58Hz）の LCD パネルを駆動するため、rPLL（PLL9）で **9MHz** を生成します。

### CPU / メモリクロック

- **Day 04〜17**: 両ボードとも rPLL40 で **40.5MHz** を生成して動作します。
- **Day 18 & Day 99**:
  - **Tang Nano 9K**: 配置配線後のセットアップ時間マージンを安全に確保するため、**27MHz**（IDIV=6, FBDIV=6）で動作します。
  - **Tang Nano 20K**: 高速なファブリックを持つため、**40.5MHz**（IDIV=6, FBDIV=9）で動作します。

### LCD 表示パイプラインと CDC (クロックドメイン交差)

- VRAM (SDPB) の**書き込みポート (`clka`)** は CPU/メモリクロックで動作します。
- VRAM (SDPB) の**読み出しポート (`clkb`)** および Font ROM (pROM) の**読み出しクロック (`clk`)** は、**9MHz 画素クロック (`LCD_CLK`)** ドメインで同期読み出しを行います。
- これにより、メモリドメインからピクセルドメインへのゼロ遅延 CDC レースを防ぎ、安定した描画を実現しています。

---

## 4. ツールパスと環境変数

Gowin EDA が標準以外のパスにインストールされている場合、Makefile 実行時に環境変数で指定できます。

### macOS の場合

Gowin EDA を `/Applications/GowinIDE.app` にインストールした場合、自動検出されます。
手動で指定する場合は以下のように設定します：

```bash
export GWSH=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/IDE/bin/gw_sh
export PRG=/Applications/GowinIDE.app/Contents/Resources/Gowin_EDA/Programmer/bin/programmer_cli

# ビルドと書き込み
make BOARD=9k download
# 20K の場合:
make BOARD=20k download
```

### Linux / WSL の場合

通常は `~/Gowin/` 配下にインストールします：

```bash
export GWSH=$HOME/Gowin/IDE/bin/gw_sh
export PRG=$HOME/Gowin/Programmer/bin/programmer_cli
```
