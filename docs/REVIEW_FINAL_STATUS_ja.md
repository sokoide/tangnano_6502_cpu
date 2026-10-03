# 教材・Day99レビュー最終状況

更新日: 2026-10-03。全体方針は[改善計画](REVIEW_IMPROVEMENT_PLAN_ja.md)、担当と各作業証跡は[実施記録](REVIEW_IMPLEMENTATION_ja.md)を参照。

## 完了内容

- Day01–18のstarter/completedにCPU・LCD・同期RAMの目的別検証を追加し、CPU課題の誤った期待値・説明を修正した。
- 失敗を隠して成功扱いするMakefileとFPGA書込みhelperを修正し、fake programmerで失敗経路を確認した。
- Day99のopcode/CPU契約、HEX変換、ALU、RAM、font、LCD pipeline、clock/reset、board wrapper、build依存を改善した。
- Day05–18の20K TFTシミュレーションへ`BOARD_20K`を渡し、ボード固有reset極性でテストするよう修正した。
- 9K/20K別PLL・SDCを設定した。9KはCPU/メモリクロックを31.5MHz、20Kは40.5MHzとする。
- ルート`make`のデフォルトをヘルプ表示にし、Day99を書き込む`make download BOARD=9k|20k`を追加した。
- Solの設計レビューで戻されたCPU回帰、programmer marker、Makefile board設定などを修正・再確認した。詳しくは担当別記録を参照。

## Gowin P&R結果

実ソースをGowinで合成・配置配線し、両ボードのbitstream生成まで完了した。制約したクロックと配置配線後の最大周波数は次の通り。

| Board | CPU/Memory制約 | CPU/Memory Actual Fmax | 最悪setup slack | Setup TNS |
| --- | ---: | ---: | ---: | ---: |
| Tang Nano 9K | 31.500MHz | 31.907MHz | +0.406ns | 0 |
| Tang Nano 20K | 40.500MHz | 53.791MHz | +6.101ns | 0 |

9Kの40.5MHz構成はFmax 33.809MHzで不成立だった。33MHz制約もFmax 33.013MHzで余裕がほぼなかったため、27MHz入力からPLL比7/6の31.5MHzへ下げた。9Kでは最悪経路のslackが正で、setup TNSは0。これは今回のGowinツール・選択デバイス条件における内部STA結果であり、外部LCD入出力delayや基板上の計測を含まない。

**[2026-10-03追記]** 31.5MHz構成はslack +0.406nsでも配置ばらつきにより+0.115nsまで落ち、実機(Tang Nano 9K)でCPU状態が破壊された(simple5.sでAレジスタが0x20↔0x5Eにトグル)。27MHz(PLL比7/7、VCO同一)へ低下しslack +0.581ns。現在の9KのCPU/メモリクロックは27MHz。詳細はcommit `7a4ea96`。

各ボードのレポートとbitstreamは`day99_completed/build/fpga/9k/`、`day99_completed/build/fpga/20k/`に保存している。再生成時は`make -C day99_completed BOARD=9k`または`BOARD=20k`を使う。

## 全体テスト

最終ソースで両方のルートテストを完了し、両コマンドとも終了コード0。

- `make BOARD=9k test` — Day01–18、Day99のCPU/ALU/RAM/font/LCD/clock-reset/system/VRAM smokeを通過。
- `make BOARD=20k test` — 同じsuiteを通過。Day05–18のTFT smoke testは20Kのreset極性で通過。
- 9K/20Kのclock contract testはそれぞれ31.5MHz/40.5MHzを含むPLL period、lock待ち・loss/relock、local reset releaseを確認。
- Day99のALU regressionは393,216 vectors、LCD pipelineは3 phase × 261,120 pixels、font契約は4096 bytesを検査。
- `git diff --check`を通過。

詳細ログは実行時に`/private/tmp/tangnano-final-tests-9k.log`、`/private/tmp/tangnano-final-tests-20k-r2.log`へ保存した。

## 受入境界

レビューとコード・テスト・FPGA P&Rは完了。FPGAへの書込み、実パネルでの表示確認、cold boot、連続運転はまだ実施していないため、その受入は未確認のまま区別する。commit/pushは行っていない。
