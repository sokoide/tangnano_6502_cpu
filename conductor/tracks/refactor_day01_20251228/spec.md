# Spec: Refactor Day 01 material to improve beginner accessibility and clarity

## Goals
- 初心者がDay 01（LED点滅）の学習を開始する際の摩擦を最小限にする。
- 開発環境（Gowin EDA, programmer_cli, Make）の動作確認をより確実に、分かりやすくする。
- 既存の `day01` および `day01_completed` の構成を整理し、一貫性を高める。

## Requirements
- `README.md` の手順を簡潔にし、トラブルシューティング情報を充実させる。
- プロジェクトファイル（.gprj）や制約ファイル（.cst）の設定ミスが起きにくい構成にする。
- `top.sv` のコードコメントを充実させ、各行の意味が理解できるようにする。

## Success Criteria
- 全くの初心者がREADMEのみを読んで、15分以内にLEDを点滅させられる。
- Tang Nano 9K/20K 両方のボードで、迷うことなくプロジェクトを開ける。
- コードスタイルガイドに準拠したクリーンなコードになっている。
