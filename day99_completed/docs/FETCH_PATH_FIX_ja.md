# simple5 実機誤動作の調査と修正 (2026-10-03)

Tang Nano 9K 実機でのみ `simple5.s` が誤動作する問題の調査記録と修正内容。
RTL シミュレーションでは常に正常だったため、実機とシミュレーションの差
(合成結果・実メモリマクロの振る舞い) に起因する2つの欠陥を修正した。

## 症状

- `simple5.s`: 右上の文字が `' '` と `'^'` (0x20/0x5E) の点滅を繰り返す。
  A レジスタが 0.3 秒ごとに 0x20↔0x5E を反復し、`0x20→0x7E` の掃引が始まらない。
- ループ抜け後の `LDA #$20` をコメントアウトしても症状が変わらない
  (RTL 上、ループ内に A を 0x20 へ戻す経路は存在しない = 実機はプログラムの
  意味論どおりに動いていない)。
- `diag_simple5.s` (25バイト、index 16 = `LDA $02`) は画面が真っ暗のまま。
- `diag_bootram.s` (7バイト) は正常に IFO ダンプを表示し、RAM `$0200` の
  バイト列も正しい。

## 調査の経緯

1. **RTL シミュレーションは常に正常** (`tb_simple5_trace.sv` で A の掃引を確認)。
2. **タイミング違反説 (不成立)**: 31.5MHz 構成の setup slack が +0.115ns しか
   なく実機破綻の疑いが強かったため 27MHz へ低下したが、症状は治らなかった。
   ただし今回の修正後も 27MHz は維持している (修正後の slack は +2.651ns)。
3. **メモリ読み出しタイミング差分説 (不成立)**: SDPB を pipeline モード相当の
   1サイクル遅延読み出しにしたシミュレーションでも挙動不変。
4. **症状の符号化から の仮説**: プログラム 16 バイト目以降 (RAM `$0210` 以降)
   の各バイトの bit7 が失われると仮定すると、全観測が説明できる:
   - simple5: index 16 の `0xC9` (CMP #imm) が `0x49` (EOR #imm) になれば、
     `ADC #1; EOR #$7F` のループで `0x21^0x7F=0x5E`、`0x5F^0x7F=0x20` と
     **0x20↔0x5E の正確な反復**になる (BVC/BNE は常に分岐)。
     末尾の `LDA #$20` は実行されないのでコメントアウト無効とも一致。
   - diag_simple5: index 16 の `0xA5` (LDA zp) が `0x25` (未定義) になれば
     FAULT で停止 → CVR 直後の真っ暗画面と一致。
   - diag_bootram: 7バイト (index 16 未満) なので無事なことも一致。

## 原因と修正

修正は2点。いずれも「RTL シミュレーションでは差が出ない構造」を、
実機の合成結果が正しく扱える構造へ置き換える。

### 1. boot ROM: unpacked array localparam + 動的インデックスの廃止

旧構造では `include/boot_program.sv` が 7680 要素の unpacked array localparam
を生成し、`top_core` がそれを cpu の array port へ渡し、cpu が
`boot_program[cur.boot_idx]` の動的インデックスで読んでいた。
この構造の Gowin 合成結果が実機で上記の bit7 欠落 (index 15 超) を
起こしたものと推定される (症状との一致は上記のとおり。修正版のゲート
ネットリストは `make test-simple5-netlist` で全ビット正しいことを確認済み)。

新構造ではジェネレータ (`utils/hex_fpga/main.go`) が case 文ベースの
定数関数 ROM を生成する:

```systemverilog
localparam logic [15:0] boot_program_length = 25;

function automatic logic [7:0] boot_program_byte(input logic [14:0] addr);
    case (addr)
    15'd0: boot_program_byte = 8'hA9;
    ...
    default: boot_program_byte = 8'hEA;
    endcase
endfunction
```

各 ROM ビットは addr (15bit) の小さな論理関数として合成され、
7680:1 の動的 mux は消滅する。`src/cpu.sv` は合成時にこの include を直接
読み、array port は `ifdef VERILATOR` のシミュレーション専用ポートとして
分離した (テストベンチが独自プログラムを注入する機能を維持するため。
`src/top_core.sv` はシミュレーション時、関数 ROM を配列へミラーする)。

### 2. 命令フェッチのデータパス登録 (dout_r) への統一

旧 FSM は opcode/オペランドフェッチ (`FETCH_RECV`) で RAM の生の出力バス
`in.dout` (Gowin SDPB bypass モード = 組み合わせ出力) を直接デコードに
使っていた。STA 上は成立していても、実メモリマクロの出力が
アドレス遷移に追従して変化するタイミングに依存する構造は脆弱である。

新 FSM では**全フェッチを `FETCH_WAIT` を経由させ**、1エッジ前に
サンプルした登録値 `cur.dout_r` のみをデコードに使う
(`src/cpu/cpu_fsm_next_pkg.sv`)。この性質は
`make test-simple5` の `+poison_live_read` で構造的に検査される
(`FETCH_RECV` 中に生バスの値を反転させてデコードを破壊しても正常動作する
ことを確認。旧設計ではこのテストは失敗する)。

### 27MHz クロック低下の扱い

31.5MHz→27MHz への低下 (commit `7a4ea96`) 自体は本症状を治さなかったが、
セットアップ余裕の観点で妥当なため維持する。修正後の最悪 setup slack は
+2.651ns (memory_clk 27MHz)。31.5MHz での再検証は実施していない。

## 検証

- `make test`: 全テスト PASS (exit 0)。新規に `test-simple5`
  (ベンダ SDPB モデル + `+poison_live_read`)、`test-diag-simple5` を含む。
- `make test-simple5-netlist`: P&R 後の実ゲートネットリスト
  (`impl/pnr/day99_9k.vo` + `deps/gw1n/prim_sim.v`) で simple5 の全 RAM
  ライト系列 (0xC9 比較含む) を検証。PLL/リセット同期/LCD タイミングは
  強制ドライブで除外した機能検証である点に注意。
- **実機確認 (2026-10-03)**: `make prog-download PROG=simple5` で
  A が正しく increment し、掃引が動作することを確認済み。

## 診断資産

| ファイル | 目的 |
| --- | --- |
| `examples/diag_bootram.s` | RAM `$0200` のロードバイトダンプ (7バイト) |
| `examples/diag_simple5.s` | simple5 の初回算術を IFO/WVS と分離 (25バイト) |
| `examples/diag_adc.s` / `diag_wvs.s` | 算術経路と VSync 待ちの分離 |
| `examples/diag_rom16.s` | index 16-23 の bit7 マーカー (`C9 A5 D0 EE A9 4C 8D FF`) ダンプ。正常なら `$0210:` 行が `C9A5D0EE A94C8DFF`、旧バグなら `4925 506E...` |
| `src/tb_simple5_trace.sv` | RTL: フレーム毎の A/PC トレース |
| `src/tb_diag_screen.sv` | RTL: 60x17 テキスト画面ダンプ |
| `src/tb_pnr_trace.sv` | Post-PnR ネットリストから SDPB モデルの RAM/VRAM を直接観測 |
| `docs/DIAG_SIMPLE5_ja.md` | 診断プログラムの使い方と期待値 |

## 運用上の注意

- `examples/*.s` を編集しただけでは `make download` は組み込みプログラムを
  更新しない。`make prog PROG=<name>` (または `make prog-download`) で
  `include/boot_program.sv` を再生成する。
- `make test-simple5-netlist` は「現在埋め込まれているプログラム」を検証する。
  実行前に `make prog PROG=simple5` で embedded プログラムを simple5 にする
  こと (Makefile が検査する)。
- cpu の array port は `ifdef VERILATOR` のシミュレーション専用である。
  Verilator 以外のシミュレータで cpu 単体を動かす場合はポート構成に注意。
