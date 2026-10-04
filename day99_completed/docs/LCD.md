## 043026-N6(ML) LCD spec

### Interface PIN connections

| Pin No. | Symbol | Function                                                     |
| ------- | ------ | ------------------------------------------------------------ |
| 1       | LEDK   | Back light power supply negative                             |
| 2       | LEDA   | Back light power supply positive                             |
| 3       | GND    | Ground                                                       |
| 4       | VCC    | Power supply                                                 |
| 5-12    | R0-R7  | Red Data                                                     |
| 13-20   | G0-G7  | Green Data                                                   |
| 21-28   | B0-B7  | Blue Data                                                    |
| 29      | GND    | Ground                                                       |
| 30      | CLK    | Clock signal                                                 |
| 31      | DISP   | Display on/off                                               |
| 32      | HSYNC  | Horizontal sync input in RGB mode (short to GND if not used) |
| 33      | VSYNC  | Vertical sync input in RGB mode (short to GND if not used)   |
| 34      | DE     | Data enable                                                  |
| 35      | NC     | No Connection                                                |
| 36      | GND    | Ground                                                       |
| 37      | XR     | Touch panel X-right                                          |
| 38      | YD     | Touch panel Y-bottom                                         |
| 39      | XL     | Touch panel X-left                                           |
| 40      | YU     | Touch panel Y-up                                             |

### Parallel RGP Input Timing

| Item           | Symbol | Values (Min.) | Values (Typ.) | Values (Max.) | Unit | Remark |
| -------------- | ------ | ------------- | ------------- | ------------- | ---- | ------ |
| DCLK Frequency | Fclk   | 8             | 9             | 12            | MHz  |        |
| **Hsync**      |        |               |               |               |      |        |
| Period time    | Th     | 485           | 531           | 589           | DCLK |        |
| Display Period | Thdisp | -             | 480-          | -             | DCLK |        |
| Back Porch     | Thbp   | 3             | 43            | 43            | DCLK |        |
| Front Porch    | Thfp   | 2             | 4             | 75            | DCLK |        |
| **Vsync**      |        |               |               |               |      |        |
| Period time    | Tv     | 276           | 292           | 321           | H    |        |
| Display Period | Tvdisp | -             | 272           | -             | H    |        |
| Back Porch     | Tvbp   | 2             | 12            | 12            | H    |        |
| Front Porch    | Tvfp   | 2             | 4             | 37            | H    |        |

### Sync Mode

![sync](./lcd_sync.png)

### Sync DE Mode

![sync DE](./lcd_sync_de.png)

## Example

![lcd](./lcd.jpg)

## Day 99 pixel pipeline（2026-10-03）

VRAM の write port は 9K では 27MHz、20K では 40.5MHz の MEMORY_CLK へ接続する。read port は両ボードとも 9MHz PixelClk へ接続する。
font ROM と LCD は PixelClk に揃える。複数ビットのアドレスを 2FF で転送する旧 CDC 経路は使用しない。

VRAM address を beam 座標から組合せ生成し、同期 VRAM 1clock → 同期 font ROM 1clock → RGB/DE 登録の順で描画する。
font row・bit index・active valid を同じ pipeline で運び、DE は beam に対し 2edge 遅延する。
画素は font byte の MSB から左順。active 幅 480、active 行 272、周期 531×292 pixel である。
reset 時に pipeline valid をクリアする。font memory の READ_MODE=0 では OCE によらず CE で読み出す。

実 font MI は metadata 上 4096byte 容量だが、収録データは 128 文字×16 行=2048byte。
simulation はこの 2048byte を読み、残る 2048byte を vendor INIT と同じゼロで埋める。
全 4096byte の vendor INIT との一致を `tb_font_contract` で確認する。

`platform_clocks` は既存 PLL と同じ rPLL 値を持つ project 所有 wrapper で、LOCK を公開する。
9K/20K の pixel ODIV は 48/64、memory ODIV は 16 で、board wrapper から parameter を渡す。
外部 reset またはいずれかの PLL lock 喪失時に両 domain へ非同期 reset を assert し、各 domain の 2edge 後に解除する。
CPU/RAM/VRAM の write は memory reset 中 gate され、LCD DE は pixel reset 中 0 となる。

同一 VRAM address への非同期 read/write 衝突の old/new 値は保証しない。
CPU から表示中に書く場合、画面の一時的な変化は許容し、frame atomicity は提供しない。
simulation による非同期位相検査は、実機 metastability 耐性・timing・連続安定動作の証明ではない。
旧 `sim/gowin_rpll*_stub.sv` と `tb_top.sv` は legacy 参考で、現行受入経路には使わない。

実行: `make test-ram`, `make test-font`, `make test-lcd`, `make test-clock`, `make test-reset`。
詳細な実行結果・未検証範囲は[Sol LCD実装結果](../../docs/REVIEW_SOL_LCD_RESULT_ja.md)を参照する。
