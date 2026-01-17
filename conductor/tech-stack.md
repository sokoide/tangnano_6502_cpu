# Tech Stack - 6502 CPU on FPGA Learning Journey

## Hardware Description Language (HDL)

- **SystemVerilog:** RTL 設計、テストベンチの記述に使用。

## Target Hardware

- **FPGA:** Gowin GW1N-9C (Tang Nano 9K), GW2A-LV18PG256C8/I7 (Tang Nano 20K)
- **Display:** 1.14 inch LCD (135x240, ST7789) および HDMI 出力

## Development Tools (Gowin Ecosystem)

- **Gowin EDA (IDE):** 論理合成、配置配線、ビットストリーム生成。
- **Gowin Programmer:** FPGA への書き込み (SRAM/Flash)。

## Simulation & Verification

- **Verilator:** 高速なサイクルベースのシミュレーションと静的解析（lint）。
- **GTKWave:** シミュレーション結果（.vcd 波形）の視覚的デバッグ。

## Infrastructure & Build Tools

- **GNU Make:** ビルドプロセスの自動化、シミュレーション実行、書き込み、フォーマットの管理。
- **Go (Golang):**
  - `hex_fpga`: Intel Hex ファイルから SystemVerilog の ROM 定義への変換。
  - `font_converter`: フォントデータからメモリ定義への変換。
  - `cpu_ifo_generate`: CPU 情報定義の自動生成。
- **Verible (verible-verilog-format):** SystemVerilog コードの自動フォーマット。
- **cc65:** 6502 アセンブリのコンパイル（学習用のサンプルプログラム作成に使用）。
- **srecord (srec_cat):** バイナリファイルから Intel Hex 形式への変換。

## Documentation & Quality

- **Markdown:** ドキュメント記述。
- **Node.js / Markdownlint:** ドキュメントの構文チェック。
