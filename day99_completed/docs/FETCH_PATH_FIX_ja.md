# simple5 実機誤動作の調査と修正 (2026-10-03)

Tang Nano 9K 実機でのみ `simple5.s` が誤動作する問題の調査記録と修正内容。
RTL シミュレーションでは常に正常だったため、実機とシミュレーションの差
(合成結果の欠陥、および実メモリマクロの同期読み出しに対するフェッチ
データパス構造) に起因する 2 つの問題を修正した。

## 症状

- `simple5.s`: 右上の文字が `' '` と `'^'` (0x20/0x5E) の点滅を繰り返す。
  A レジスタが 0.3 秒ごとに 0x20↔0x5E を反復し、`0x20→0x7E` の掃引が始まらない。
- ループ抜け後の `LDA #$20` をコメントアウトしても症状が変わらない
  (RTL 上、ループ内に A を 0x20 へ戻す経路は存在しない = 実機はプログラムの
  意味論どおりに動いていない)。
- `diag_simple5.s` (25 バイト、index 16 = `LDA $02`) は画面が真っ暗のまま。
- `diag_bootram.s` (7 バイト) は正常に IFO ダンプを表示し、RAM `$0200` の
  バイト列も正しい。

## 調査の経緯

1. **RTL シミュレーションは常に正常** (`tb_simple5_trace.sv` で A の掃引を確認)。
2. **タイミング違反説 (不成立)**: 31.5MHz 構成の setup slack が +0.115ns しか
   なく実機破綻の疑いが強かったため 27MHz へ低下したが、症状は治らなかった。
   ただし今回の修正後も 27MHz は維持している (修正後の slack は +2.651ns)。
3. **メモリ読み出しタイミング差分説 (不成立)**: SDPB を pipeline モード相当の
   1 サイクル遅延読み出しにしたシミュレーションでも挙動不変。
4. **症状をバイト値で捉えた仮説**: プログラム 16 バイト目以降 (RAM `$0210` 以降)
   の各バイトの bit7 が失われると仮定すると、全観測が説明できる:
   - simple5: index 16 の `0xC9` (CMP #imm) が `0x49` (EOR #imm) になれば、
     `ADC #1; EOR #$7F` のループで `0x21^0x7F=0x5E`、`0x5F^0x7F=0x20` と
     **0x20↔0x5E の正確な反復**になる (BVC/BNE は常に分岐)。
     末尾の `LDA #$20` は実行されないのでコメントアウト無効とも一致。
   - diag_simple5: index 16 の `0xA5` (LDA zp) が `0x25` (AND zp、実装済み)
     になっても算術結果は A に影響せず実行は継続するが、後続の index 18 の
     `0xDF` (IFO) が `0x5F` (未定義、FSM のオペコードリストに不在) になれば
     FAULT で停止 → CVR 直後の真っ暗画面と一致。
   - diag_bootram: 7 バイト (index 16 未満) なので無事なことも一致。

## 原因と修正

修正は 2 点。いずれも「RTL シミュレーションでは差が出ない構造」を、
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

前提として、Gowin SDPB の READ_MODE=0 (bypass) は**組み合わせ読み出しでは
ない**。`deps/gw1n/prim_sim.v` の SDPB モデルでは、bypass モードの出力
`bp_reg` も posedge CLKB で登録されており、読み出しは同期 1 サイクルである
(組み合わせ読み出しモードはモデル上存在しない。当初 bypass を
組み合わせ出力と誤解していた期間があり、その訂正は
「教材 (day01-18) への適用範囲」節に記載のとおり)。

旧 FSM は opcode/オペランドフェッチ (`FETCH_RECV`) で RAM の生の出力バス
`in.dout` を直接デコードに使っていた。同期読み出しでは SDPB 出力レジスタの
更新エッジと FETCH_RECV のデコードエッジが一致し、実機の出力遷移タイミング
に依存する構造になる。STA 上は成立していても、アドレス遷移に追従する出力の
更新と同一エッジでサンプルする構造は脆弱である。

新 FSM では**全フェッチを `FETCH_WAIT` を経由させ**、1 エッジ前に
サンプルした登録値 `cur.dout_r` のみをデコードに使う
(`src/cpu/cpu_fsm_next_pkg.sv`)。FETCH_WAIT を 1 つ挟むため、デコードに
使う `dout_r` は SDPB 出力レジスタの**更新後**の値を拾い、同期 1 サイクルの
SDPB と正しく整合する。この性質は
`make test-simple5` の `+poison_live_read` で構造的に検査される
(`FETCH_RECV` 中に生バスの値を反転させてデコードを破壊しても正常動作する
ことを確認。旧設計ではこのテストは失敗する)。

なお、simple5 実機誤動作の**主因は上記 1. の boot ROM 合成バグ
(index 16 以降の bit7 欠落) と推定される**。本項の FETCH_WAIT+dout_r への
統一は主因の修正ではないが、同期 SDPB を前提としたフェッチデータパスの
構造改善として有効であり維持する。

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

| ファイル                             | 目的                                                                                                                                   |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| `examples/diag_bootram.s`            | RAM `$0200` のロードバイトダンプ (7バイト)                                                                                             |
| `examples/diag_simple5.s`            | simple5 の最初の算術演算を IFO/WVS と分離 (25バイト)                                                                                   |
| `examples/diag_adc.s` / `diag_wvs.s` | 算術経路と VSync 待ちの分離                                                                                                            |
| `examples/diag_rom16.s`              | index 16-23 の bit7 マーカー (`C9 A5 D0 EE A9 4C 8D FF`) ダンプ。正常なら `$0210:` 行が `C9A5D0EE A94C8DFF`、旧バグなら `4925 506E...` |
| `src/tb_simple5_trace.sv`            | RTL: フレーム毎の A/PC トレース                                                                                                        |
| `src/tb_diag_screen.sv`              | RTL: 60x17 テキスト画面ダンプ                                                                                                          |
| `src/tb_pnr_trace.sv`                | Post-PnR ネットリストから SDPB モデルの RAM/VRAM を直接観測                                                                            |
| `docs/DIAG_SIMPLE5_ja.md`            | 診断プログラムの使い方と期待値                                                                                                         |

## 教材 (day01-18) への適用範囲

Day99 の調査結果を day01-18 教材に展開した際の方針 (2026-10-03)。なお展開時、
SDPB の bypass モードを「組み合わせ読み出し」と誤解しており、その誤った
前提に基づく変更は実機確認 (ユーザー実験) で発覚した後に revert した。
正しい理解は以下のとおり:

- **Gowin SDPB の READ_MODE=0 (bypass) は同期 1 サイクル読み出しである**。
  `day99_completed/deps/gw1n/prim_sim.v` の SDPB モデルでは bypass モードの
  出力 `bp_reg` が posedge CLKB で登録されており (上記「原因と修正 2.」)、
  組み合わせ読み出しモードは存在しない。

revert 後の適用状況は次のとおり:

- **パターンB (アレイROM動的インデックス) は全dayに存在しない**。教材の
  ROM はすべて case 文またはベンダ IP であり、boot program を RAM へ
  展開する構造も Day99 と異なり rom.sv の case 組み合わせ出力のみ。
  この点は展開当初の調査どおりであり、教材側の修正は不要。
- **day10-18 の ram.sv (starter/completed 計18ファイル) は元の同期読み出し
  (`dout <= mem[addr]`) のまま**。展開時に VERILATOR モデルのみ組み合わせ
  読み出し (`assign dout = mem[addr]`) へ変更したが、上記のとおり実機 IP
  (READ_MODE=0) も同期 1 サイクルであるためこの変更は誤りであり、revert
  した。元の実装が正しかった。
- **day18 (starter/completed) の cpu.sv `data_r` 登録サンプル化は取りやめ**。
  bypass を組み合わせ出力と誤解した前提で、settle エッジで SDPB 出力の
  **更新前** (旧アドレス) の値をラッチする構造となり、実機で全フェッチが
  1 バイトずれる障害を起こした (ユーザーの実機確認で発覚)。元の
  `data_in` 直接デコードへ revert した。実機では `data_in` は SDPB の
  登録出力であり直接デコードで安全である。`+poison_live_read` 強制テスト
  (`sim/tb_curriculum_sync.sv` への追加ブロックと
  `day18_completed/Makefile` の実行行) も同時に revert 済み。
- **day10-17 は当初から変更なし (data_in 直接デコード)**。これらの
  CPU は `pc_enable` が 2^24 クロックに 1 回しか立たず、デコードエッジの
  前に実質無限のセットアップ時間がある (連続実行しない) ため、遷移追従
  レースの条件が存在しない。
- **維持した有効な変更**: day18 への SDC 追加 (day18_9k.sdc /
  day18_20k.sdc、gprj 経由で PnR が認識) と README クロック記述修正
  は維持した。PnR スラックの計測値 (revert 後の現行構成):
  9K 40.5MHz で +0.026ns (最悪パスは memory_clk ドメインの CPU →
  SDPB 入力。TNS は 0)、20K 40.5MHz で +6.013ns (Fmax 53.537MHz、
  TNS 0。revert 後の再計測値)。9K は余裕がほぼゼロのため、実機で
  問題が出る場合は memory_clk の低下を検討すること。
  → 2026-10-03、day18 (starter/completed) の 9K について memory_clk を
  27MHz に低下した (Gowin_rPLL40 の IDIV_SEL=6 / FBDIV_SEL=6、
  day18_9k.sdc は multiply_by 7 / divide_by 7)。data_r 登録サンプル化の
  revert により 9K PnR の setup slack が +0.026ns とほぼゼロになったため、
  Day99 9K と同一の 27MHz 構成でタイミング余裕を確保するものである。
  27MHz 化後の 9K 計測値: setup slack +4.417ns (最悪パス
  `u_boot/boot_index_7 → u_cpu/pc_3/CE`、起動時のみ動作)、hold
  +0.708ns、TNS 0 (9K のタイミングレポートはその後の 20K ビルドで
  上書き済みのため、本記録が唯一の証跡)。20K は 40.5MHz のまま
  (+6.013ns)。README のクロック記述も「9K 27MHz / 20K 40.5MHz」へ
  更新済み (上記の「9K/20K ともに 40.5MHz」の記述は本変更で置き換え)。
- **Day99 自身の FETCH_WAIT + dout_r 登録は有効**。フェッチに 1 エッジの
  待ちを挟むため `dout_r` は SDPB 出力レジスタ更新後の値を拾い、同期
  1 サイクルの SDPB と正しく整合する。ただし Day99 の実機障害の主因は
  boot ROM 合成バグ (bit7 欠落) と推定される (「原因と修正 1./2.」参照)。

## 運用上の注意

- `examples/*.s` を編集しただけでは `make download` は組み込みプログラムを
  更新しない。`make prog PROG=<name>` (または `make prog-download`) で
  `include/boot_program.sv` を再生成する。
- `make test-simple5-netlist` は「現在埋め込まれているプログラム」を検証する。
  実行前に `make prog PROG=simple5` で embedded プログラムを simple5 にする
  こと (Makefile が検査する)。
- cpu の array port は `ifdef VERILATOR` のシミュレーション専用である。
  Verilator 以外のシミュレータで cpu 単体を動かす場合はポート構成に注意。
