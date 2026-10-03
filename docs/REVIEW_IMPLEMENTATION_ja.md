# 教材・完成版の修正実施記録

開始日: 2026-10-02。基準: `b261ad5`。実装と Sol レビュー完了。両ボード全体検証を実行中。

## 実行経路

ユーザー指定に従い、GLM 担当は `ccz` で起動する Claude Code から変更し、
GPT 6.1 Sol で独立レビューする。Sol 担当の設計修正はレビュー後に進める。
初回の広い調査セッションは終了し、編集対象を限定したセッションへ分割した。
モデル名は Claude Code の要求値だけでなく、応答の `message.model` でも確認する。

| 担当 | 範囲 | 記録 |
| --- | --- | --- |
| GLM 5.3 Flash | 失敗の伝播、assert有効化、教材・構成文書の定型訂正 | [実装記録](REVIEW_FLASH_RESULT_ja.md) |
| GLM 5.3 | HEX変換・独立ALU | [実装記録](REVIEW_GLM_TOOLS_RESULT_ja.md)、[Solレビュー](REVIEW_SOL_TOOLS_ja.md) |
| GLM 5.3 | 現行CPUのRTS・BCS・比較命令、回帰テスト | [実装記録](REVIEW_GLM_CPU99_RESULT_ja.md)、[Sol最終レビュー](REVIEW_SOL_CPU99_FINAL_REVIEW_ja.md) |
| GLM 5.3 | 各Dayの課題とCPU検証経路の一致 | [実装記録](REVIEW_GLM_LESSONS_RESULT_ja.md) |
| GPT 6.1 Sol | boot・メモリmap・write・LCD・reset | [設計調査](REVIEW_SOL_MEMORY_DESIGN_ja.md)、[実装記録](REVIEW_SOL_LCD_RESULT_ja.md) |
| GPT 6.1 Sol | 同期RAM・Day 18表示時の所有権 | [設計調査](REVIEW_SOL_CURRICULUM_DESIGN_ja.md)、[実装記録](REVIEW_SOL_CURRICULUM_RESULT_ja.md) |

## レビューで戻した修正

- HEX type 04 の非 0 レコードアドレスを拒否する検査。
- チェックサム不正の fixture が奇数桁エラーになっていた問題。
- 容量超過 fixture を正確に 7681 bytes へ変更。
- GLM の一時 ALU 検証の期待値に式幅の誤りがあった。Sol の独立 oracle で
  CMP/ADC/SBC の 393216 vectors を検査し、DUT の二進演算は合格した。

## 検証の境界

変更後のテスト結果と終了コードは各記録へ保存する。教材の未実装 starter、
LCD の smoke test、CPU 命令テスト、vendor model、FPGA ビルド、実機を区別する。
実機書込み・連続運転は実施していない。commit/push は実施しない。

## 最終検証

両ボードの`make BOARD=9k test`と`make BOARD=20k test`が終了コード 0 で完了した。
Gowin P&R と bitstream 生成も両ボードで完了。9K は 31.5MHz で Actual Fmax 31.907MHz、
worst setup slack +0.406ns / TNS 0。20K は 40.5MHz で Actual Fmax 53.791MHz、
worst setup slack +6.101ns / TNS 0。全体の再現コマンド・制約・未実施の実機受入は
[最終状況](REVIEW_FINAL_STATUS_ja.md)を参照。
