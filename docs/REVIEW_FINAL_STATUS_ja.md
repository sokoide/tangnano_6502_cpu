# 教材・Day99レビュー最終状況

更新日: 2026-10-03。全体方針は[改善計画](REVIEW_IMPROVEMENT_PLAN_ja.md)、担当と各作業証跡は[実施記録](REVIEW_IMPLEMENTATION_ja.md)を参照。

## 完了内容

- Day01–18 の starter/completed に CPU・LCD・同期 RAM の目的別検証を追加し、CPU 課題の誤った期待値・説明を修正した。
- 失敗を隠して成功扱いする Makefile と FPGA 書込み helper を修正し、fake programmer で失敗経路を確認した。
- Day99 の opcode/CPU 契約、HEX 変換、ALU、RAM、font、LCD pipeline、clock/reset、board wrapper、build 依存を改善した。
- Day05–18 の 20K TFT シミュレーションへ`BOARD_20K`を渡し、ボード固有 reset 極性でテストするよう修正した。
- 9K/20K 別 PLL・SDC を設定した。9K は CPU/メモリクロックを 31.5MHz、20K は 40.5MHz とする。
- ルート`make`のデフォルトをヘルプ表示にし、Day99 を書き込む`make download BOARD=9k|20k`を追加した。
- Sol の設計レビューで戻された CPU 回帰、programmer marker、Makefile board 設定などを修正・再確認した。詳しくは担当別記録を参照。

## Gowin P&R結果

実ソースを Gowin で合成・配置配線し、両ボードの bitstream 生成まで完了した。制約したクロックと配置配線後の最大周波数は次の通り。

| Board | CPU/Memory制約 | CPU/Memory Actual Fmax | 最悪setup slack | Setup TNS |
| --- | ---: | ---: | ---: | ---: |
| Tang Nano 9K | 31.500MHz | 31.907MHz | +0.406ns | 0 |
| Tang Nano 20K | 40.500MHz | 53.791MHz | +6.101ns | 0 |

9K の 40.5MHz 構成は Fmax 33.809MHz で不成立だった。33MHz 制約も Fmax 33.013MHz で余裕がほぼなかったため、27MHz 入力から PLL 比 7/6 の 31.5MHz へ下げた。9K では最悪経路の slack が正で、setup TNS は 0。これは今回の Gowin ツール・選択デバイス条件における内部 STA 結果であり、外部 LCD 入出力 delay や基板上の計測を含まない。

**[2026-10-03追記]** 31.5MHz 構成は slack +0.406ns でも配置ばらつきにより+0.115ns まで落ち、実機(Tang Nano 9K)で CPU 状態が破壊された(simple5.s で A レジスタが 0x20↔0x5E にトグル)。27MHz(PLL 比 7/7、VCO 同一)へ低下し slack +0.581ns。現在の 9K の CPU/メモリクロックは 27MHz。詳細は commit `7a4ea96`。

各ボードのレポートと bitstream は`day99_completed/build/fpga/9k/`、`day99_completed/build/fpga/20k/`に保存している。再生成時は`make -C day99_completed BOARD=9k`または`BOARD=20k`を使う。

## 全体テスト

最終ソースで両方のルートテストを完了し、両コマンドとも終了コード 0。

- `make BOARD=9k test` — Day01–18、Day99 の CPU/ALU/RAM/font/LCD/clock-reset/system/VRAM smoke を通過。
- `make BOARD=20k test` — 同じ suite を通過。Day05–18 の TFT smoke test は 20K の reset 極性で通過。
- 9K/20K の clock contract test はそれぞれ 31.5MHz/40.5MHz を含む PLL period、lock 待ち・loss/relock、local reset release を確認。
- Day99 の ALU regression は 393,216 vectors、LCD pipeline は 3 phase × 261,120 pixels、font 契約は 4096 bytes を検査。
- `git diff --check`を通過。

詳細ログは実行時に`/private/tmp/tangnano-final-tests-9k.log`、`/private/tmp/tangnano-final-tests-20k-r2.log`へ保存した。

## 受入境界

レビューとコード・テスト・FPGA P&R は完了。FPGA への書込み、実パネルでの表示確認、cold boot、連続運転はまだ実施していないため、その受入は未確認のまま区別する。commit/push は行っていない。
